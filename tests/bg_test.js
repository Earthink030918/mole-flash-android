/*
 * bg_test.js —— 验证 1.0.6 的「后台继续运行」
 * ==============================================
 * 直接从 shell.html 里切出第 6 段（后台保活）来跑，Ruffle 的 player / instance
 * 用桩替代。测的是我们自己写的那层「谁负责启停、什么时候才允许对齐时间轴」。
 *
 * 关注点：
 *   1) startBackgroundTick 必须幂等 —— 重复调用会 new 出第二个 Worker，
 *      两个 Worker 各推 24fps，游戏就是两倍速
 *   2) document.hidden 时不要抢 Ruffle 的活（它自己的 visibilitychange 分支会做）
 *   3) visibility 没变时（少数 WebView）要能代劳一次
 *   4) 游戏本来就是暂停态时，后台不为它维持时间轴
 *   5) 只有「后台真跑过」才允许对齐时间轴 —— 否则等于把挂起时长喂给 core，
 *      那正是补帧风暴的来源
 */
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const shell = process.argv[2] || 'src/web/shell.html';
const src = fs.readFileSync(path.resolve(shell), 'utf8');

const blocks = [...src.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map(m => m[1]);
const block = blocks[blocks.length - 1];
const at = block.indexOf(' * 6) 后台保活');
if (at < 0) throw new Error('未找到第 6 段');
const code = block.slice(block.lastIndexOf('/*', at));

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra ? '  → ' + extra : '')); }
}

function makeEnv(opt = {}) {
  const st = { workers: 0, starts: 0, stops: 0, restarts: 0, bgMode: 0, plays: 0, aligns: 0 };
  const listeners = [];

  const player = {
    backgroundWorker: null,
    lastActivePlayingState: false,
    instance: {
      _playing: opt.playing !== false,
      is_playing() { return this._playing; },
      play() { this._playing = true; st.plays++; },
      pause() { this._playing = false; },
      enable_background_tick_mode() { st.bgMode++; },
      restart_animation_loop() { st.restarts++; },
    },
    startBackgroundTick() {                     // 模拟 Ruffle：不判重
      st.starts++;
      this.backgroundWorker = { id: ++st.workers };
    },
    stopBackgroundTick() {
      if (this.backgroundWorker) st.stops++;
      this.backgroundWorker = null;
    },
  };

  const doc = {
    hidden: opt.hidden !== false,
    querySelector: () => (opt.noPlayer ? null : player),
    addEventListener(t, fn) { if (t === 'visibilitychange') listeners.push(fn); },
  };

  const win = {
    __moleAlignClock() { st.aligns++; return true; },
  };

  const ctx = {
    window: win, document: doc,
    console: { log() {}, warn() {}, error() {} },
    JSON, Math, Number, String, Object,
  };
  vm.createContext(ctx);
  vm.runInContext(code, ctx);

  return { win, player, doc, st, listeners,
    fireVisibility() { listeners.forEach(f => f()); } };
}

console.log('=== 1) document.hidden 时把活留给 Ruffle，不抢 ===');
{
  const env = makeEnv({ hidden: true });
  const r = env.win.__moleEnterBackground();
  ok('enter 返回 false（不接管）', r === false);
  ok('没有启动 Worker', env.st.workers === 0);
  ok('没有调用 enable_background_tick_mode', env.st.bgMode === 0);
}

console.log('=== 2) startBackgroundTick 幂等（防双 Worker 双倍速） ===');
{
  const env = makeEnv({ hidden: true });
  env.win.__moleEnterBackground();          // 先让第 6 段打上补丁
  env.player.startBackgroundTick();          // 模拟 Ruffle 自己的 hidden 分支
  ok('第一次创建 1 个 Worker', env.st.workers === 1);
  env.player.startBackgroundTick();
  env.player.startBackgroundTick();
  ok('再次调用不会新建 Worker', env.st.workers === 1, 'workers=' + env.st.workers);
  ok('实例上仍只有那一个 Worker', !!env.player.backgroundWorker);
}

console.log('=== 3) visibility 没变时手动接管 ===');
{
  const env = makeEnv({ hidden: false, playing: true });
  const r = env.win.__moleEnterBackground();
  ok('enter 成功', r === true);
  ok('调了 enable_background_tick_mode', env.st.bgMode === 1);
  ok('创建了 1 个 Worker', env.st.workers === 1);
  ok('记下了挂起前的播放状态', env.player.lastActivePlayingState === true);

  const r2 = env.win.__moleEnterBackground();
  ok('重复 enter 不再建 Worker', env.st.workers === 1 && r2 === true, 'workers=' + env.st.workers);
}

console.log('=== 4) 游戏本身是暂停态：后台不为它维持时间轴 ===');
{
  const env = makeEnv({ hidden: false, playing: false });
  const r = env.win.__moleEnterBackground();
  ok('enter 返回 false', r === false);
  ok('没有 enable_background_tick_mode（不取消 rAF）', env.st.bgMode === 0);
  ok('没有 Worker', env.st.workers === 0);
}

console.log('=== 5) 回前台：Worker 还在 → 我们接管恢复 ===');
{
  const env = makeEnv({ hidden: false, playing: true });
  env.win.__moleEnterBackground();
  const r = env.win.__moleLeaveBackground();
  ok('报告 worker=true', r.worker === true);
  ok('报告后台跑过', r.ranInBackground === true);
  ok('停掉了 Worker', env.st.workers === 1 && env.player.backgroundWorker === null);
  ok('恢复了动画循环（只一次）', env.st.restarts === 1, 'restarts=' + env.st.restarts);
  ok('要求对齐时间轴', env.st.aligns === 1 && r.aligned === true);
  ok('游戏仍是播放态', env.player.instance._playing === true);
}

console.log('=== 6) 回前台：Ruffle 先跑了 visible 分支 → 不重复 restart ===');
{
  const env = makeEnv({ hidden: true });
  env.win.__moleEnterBackground();          // 打补丁
  env.player.startBackgroundTick();          // Ruffle 的 hidden 分支
  env.player.stopBackgroundTick();           // Ruffle 的 visible 分支（先跑）
  env.player.instance.restart_animation_loop();   // 它同时 restart 了

  const before = env.st.restarts;
  const r = env.win.__moleLeaveBackground();
  ok('worker=false（已被 Ruffle 停掉）', r.worker === false);
  ok('没有第二次 restart_animation_loop（否则双倍帧率）',
     env.st.restarts === before, 'restarts=' + env.st.restarts);
  ok('仍然要求对齐时间轴', env.st.aligns === 1 && r.aligned === true);
  ok('判定为「后台跑过」', r.ranInBackground === true);
}

console.log('=== 7) 后台压根没跑：绝不对齐（否则补帧风暴） ===');
{
  const env = makeEnv({ hidden: true });
  const r = env.win.__moleLeaveBackground();
  ok('worker=false', r.worker === false);
  ok('ranInBackground=false', r.ranInBackground === false);
  ok('没有要求对齐时间轴', env.st.aligns === 0, 'aligns=' + env.st.aligns);
  ok('没有 restart', env.st.restarts === 0);
}

console.log('=== 8) 状态口子 ===');
{
  const env = makeEnv({ hidden: false, playing: true });
  const s0 = env.win.__moleBg();
  ok('初始 ran=false / worker=false', s0.ran === false && s0.worker === false);
  env.win.__moleEnterBackground();
  const s1 = env.win.__moleBg();
  ok('进后台后 worker=true', s1.worker === true);
  ok('playing=true 被正确读出', s1.playing === true);
}

console.log('=== 9) 没有播放器时不抛异常 ===');
{
  const env = makeEnv({ noPlayer: true });
  let threw = false, r1, r2;
  try { r1 = env.win.__moleEnterBackground(); r2 = env.win.__moleLeaveBackground(); }
  catch (e) { threw = true; }
  ok('enter/leave 都不抛', threw === false);
  ok('enter 返回 false', r1 === false);
  ok('leave 返回结构完整', r2 && r2.worker === false && r2.aligned === false);
}

console.log('\n' + (fail === 0 ? 'ALL PASS' : 'FAILED') + '  pass=' + pass + ' fail=' + fail);
process.exit(fail === 0 ? 0 : 1);
