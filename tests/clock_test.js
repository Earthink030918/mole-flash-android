/*
 * clock_test.js —— 验证 1.0.5 的「时间轴钳制」
 * =================================================
 * 直接从 shell.html 里切出第 0 段的帧率节流 IIFE 来跑，不复制代码，
 * 保证测的就是打进包里那一份。
 *
 * 关注点：
 *   1) 平时 1:1 —— 虚拟时钟与真实时间完全同步，不改变游戏节奏
 *   2) 后台恢复（gap > 800ms）只推进 1 帧，绝不补帧
 *   3) 普通掉帧（250ms < gap <= 800ms）截断到 250ms
 *   4) 喂给 Ruffle 的时间戳永远不会跳变
 *   5) 累计切断时间可用于诊断
 */
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const shell = process.argv[2] || 'src/web/shell.html';
const src = fs.readFileSync(path.resolve(shell), 'utf8');

const a = src.indexOf('var TARGET_FPS = 24;');
const b = src.indexOf('window.__moleFps = TARGET_FPS;');
if (a < 0 || b < 0) throw new Error('未找到第 0 段源码');
const code = '(function(){' + src.slice(a, b) + 'window.__moleFps = TARGET_FPS;\n})();';

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra ? '  → ' + extra : '')); }
}
function near(a, b, eps) { return Math.abs(a - b) <= (eps == null ? 0.5 : eps); }

function makeEnv() {
  const warns = [];
  let pumpCb = null;
  const win = {
    requestAnimationFrame(fn) { pumpCb = fn; return 1; },
    cancelAnimationFrame() {},
  };
  const ctx = {
    window: win,
    console: { log() {}, warn(...x) { warns.push(x.join(' ')); }, error() {} },
    Map, Math, Number, isFinite, Date, setTimeout,
  };
  vm.createContext(ctx);
  vm.runInContext(code, ctx);
  return {
    window: win,
    warn: () => warns,
    // 驱动一帧真实 rAF（ts 为真实时间戳）
    frame(ts) { const f = pumpCb; pumpCb = null; if (f) f(ts); },
  };
}

// 探针：登记一个回调，记录它被调用的虚拟时间戳
// 和 Ruffle 的动画闭包一样，回调内部会重新登记下一帧
function attachProbe(win) {
  const seen = [];
  function probe(vts) {
    seen.push(vts);
    win.requestAnimationFrame(probe);
  }
  win.requestAnimationFrame(probe);
  return seen;
}

console.log('=== 1) 平时 1:1（60Hz 真实帧 → 24fps 逻辑帧） ===');
{
  const env = makeEnv();
  const seen = attachProbe(env.window);
  const t0 = 1000;
  env.frame(t0);
  for (let i = 1; i <= 120; i++) env.frame(t0 + i * (1000 / 60));   // 2 秒
  ok('产出约 48 帧（2s × 24fps）', seen.length >= 46 && seen.length <= 50, 'got ' + seen.length);
  const span = seen[seen.length - 1] - seen[0];
  ok('虚拟时间跨度 ≈ 真实跨度（2s）', near(span, 2000, 60), 'span=' + span.toFixed(1));
  /* 60Hz 真实帧重采样到 24fps，帧间隔必然在 33.3 / 50 之间抖动
     （3 帧里出 1.2 帧），这是节流器本身的性质，不是钳制引入的 */
  let maxStep = 0, minStep = Infinity;
  for (let i = 1; i < seen.length; i++) {
    const d = seen[i] - seen[i - 1];
    maxStep = Math.max(maxStep, d); minStep = Math.min(minStep, d);
  }
  ok('帧间隔落在 33.3~50.1ms（≈24fps）',
     maxStep <= 50.1 && minStep >= 33.3, 'min=' + minStep.toFixed(2) + ' max=' + maxStep.toFixed(2));
}

console.log('=== 2) 后台恢复：挂起 300 秒 ===');
{
  const env = makeEnv();
  const seen = attachProbe(env.window);
  let ts = 5000;
  env.frame(ts);
  for (let i = 0; i < 30; i++) { ts += 16.67; env.frame(ts); }   // 正常跑一会儿
  const before = seen.length;
  ts += 300000;                                                   // 切后台 5 分钟
  env.frame(ts);
  const afterResume = seen.length;
  ok('恢复瞬间只产出 1 帧', afterResume - before === 1, 'got ' + (afterResume - before));
  ok('恢复那帧的时间戳没有跳变（≈1 帧）',
     near(seen[seen.length - 1] - seen[seen.length - 2], 41.67, 1.5),
     'delta=' + (seen[seen.length - 1] - seen[seen.length - 2]).toFixed(2));
  const c = env.window.__moleClock();
  ok('__moleClock 记录了 1 次恢复', c.resumes === 1, JSON.stringify(c));
  ok('切断时间 ≈ 300000 - 41.7', near(c.stallMs, 300000 - 41.67, 60), 'stall=' + c.stallMs);
  ok('写了一条恢复日志', env.warn().some(s => s.indexOf('长间隔') >= 0));

  // 恢复后继续跑 1 秒，不应有任何补帧
  const n0 = seen.length;
  const v0 = seen[seen.length - 1];
  for (let i = 0; i < 60; i++) { ts += 16.67; env.frame(ts); }
  ok('恢复后恢复正常节奏（1s ≈ 24 帧）', seen.length - n0 >= 22 && seen.length - n0 <= 26,
     'got ' + (seen.length - n0));
  ok('恢复后虚拟时钟与真实时间重新对齐',
     near(seen[seen.length - 1] - v0, 1000, 60), 'span=' + (seen[seen.length - 1] - v0).toFixed(1));
}

console.log('=== 3) 阈值边界（用 __moleClock().vTs 精确量推进量） ===');
{
  // 恰好 800ms：不算后台恢复，但会被 250ms 截断
  const e1 = makeEnv(); attachProbe(e1.window);
  let t = 0; e1.frame(t);
  for (let i = 1; i <= 10; i++) { t = i * 16.67; e1.frame(t); }
  const v0 = e1.window.__moleClock().vTs;
  e1.frame(t + 800);
  const d1 = e1.window.__moleClock().vTs - v0;
  ok('gap=800ms 截断到 250ms', near(d1, 250, 0.01), 'advance=' + d1);

  // 刚好超过 800ms → 后台恢复
  const e2 = makeEnv(); attachProbe(e2.window);
  let t2 = 0; e2.frame(t2);
  for (let i = 1; i <= 10; i++) { t2 = i * 16.67; e2.frame(t2); }
  const v2 = e2.window.__moleClock().vTs;
  e2.frame(t2 + 801);
  const d2 = e2.window.__moleClock().vTs - v2;
  ok('gap=801ms 判定后台恢复，只进 1 帧', near(d2, 41.67, 0.02), 'advance=' + d2);

  // 普通卡顿 200ms：原样通过（不牺牲真实时间）
  const e3 = makeEnv(); attachProbe(e3.window);
  let t3 = 0; e3.frame(t3);
  for (let i = 1; i <= 10; i++) { t3 = i * 16.67; e3.frame(t3); }
  const v3 = e3.window.__moleClock().vTs;
  e3.frame(t3 + 200);
  const d3 = e3.window.__moleClock().vTs - v3;
  ok('gap=200ms 原样通过（不牺牲真实时间）', near(d3, 200, 0.02), 'advance=' + d3);
}

console.log('=== 4) 时间戳异常 ===');
{
  const env = makeEnv();
  attachProbe(env.window);
  env.frame(1000);
  env.frame(1016.67); env.frame(1033.34);
  const v = env.window.__moleClock().vTs;
  env.frame(1000);                       // 时间戳回退
  const c = env.window.__moleClock();
  ok('时间戳回退不产生负推进', c.vTs >= v - 0.001, 'v=' + v + ' → ' + c.vTs);
  ok('虚拟时钟保持单调', c.vTs >= v - 0.001, JSON.stringify(c));
  ok('回退不会触发后台恢复分支', c.resumes === 0, JSON.stringify(c));
}

console.log('=== 5) fps 仍然可调（节流器未被破坏） ===');
{
  const env = makeEnv();
  ok('__moleSetFps(30) 成功', env.window.__moleSetFps(30) === true);
  ok('__moleSetFps(0) 被拒绝', env.window.__moleSetFps(0) === false);
  ok('__moleSetFps(999) 被拒绝', env.window.__moleSetFps(999) === false);
}

console.log('=== 6) 后台真跑过 → 回前台对齐真实时间（不钳制） ===');
{
  const env = makeEnv();
  const seen = attachProbe(env.window);
  let t = 0; env.frame(t);
  for (let i = 1; i <= 10; i++) { t = i * 16.67; env.frame(t); }
  ok('默认 pending=false', env.window.__moleClock().pending === false);

  const bg = 300000;                          // 后台 5 分钟
  env.window.__moleAlignClock();              // 第 6 段确认「后台真跑过」后调用
  ok('调用后 pending=true', env.window.__moleClock().pending === true);

  env.frame(t + bg);
  const c = env.window.__moleClock();
  ok('vTs 直接对齐到真实时间戳', near(c.vTs, t + bg, 0.01),
     'vTs=' + c.vTs + ' ts=' + (t + bg));
  ok('没有把后台时长记成「被切断」', c.stallMs === 0, 'stallMs=' + c.stallMs);
  ok('探针收到的就是这个时间戳', near(seen[seen.length - 1], t + bg, 0.01),
     'got=' + seen[seen.length - 1]);
  ok('align 计数 +1', c.align === 1, 'align=' + c.align);
  ok('pending 已复位', c.pending === false);

  const v0 = seen[seen.length - 1];
  for (let k = 1; k <= 3; k++) env.frame(t + bg + k * 16.67);
  ok('随后 3 个真实帧推进约 50ms（恢复正常 24fps 节奏，无跳变）',
     near(seen[seen.length - 1] - v0, 50.01, 0.05),
     'advance=' + (seen[seen.length - 1] - v0).toFixed(2));
}

console.log('\n' + (fail === 0 ? 'ALL PASS' : 'FAILED') + '  pass=' + pass + ' fail=' + fail);
process.exit(fail === 0 ? 0 : 1);
