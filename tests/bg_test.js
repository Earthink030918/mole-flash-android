/*
 * bg_test.js —— 验证 1.1.1 的「后台固定步长推进」
 * ==============================================
 * 直接从 shell.html 里切出第 6 段跑，player / instance / AudioContext /
 * AudioWorkletNode 全部用桩替代。测的是我们自己写的那层节拍逻辑。
 *
 * 这一版针对用户实测的两个现象：
 *   a) 后台挂机音乐爆破音
 *   b) 仍然因数据包对不上被踢
 *
 * 两者同源：Ruffle 的 startBackgroundTick 用 setTimeout 递归驱动，
 * 页面 hidden 时被节流到 1 秒起步，喂进 core 的 dt 一跳一秒 →
 * 音频一次生成 44100 样本（撕裂=爆破音）、frame_accumulator 只跑 5 帧
 * 就归零（逻辑时间落后 79%）、update_timers 一次补 10 个回调（包乱序=被踢）。
 *
 * 所以要守住的断言只有一条主心骨：
 *   相邻两次喂给 core.tick_for_background 的时间戳差 **恒等于** 41.666ms，
 *   不论节拍器被节流成多慢、单轮补多少帧。
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

const FRAME_MS = 1000 / 24;

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra ? '  → ' + extra : '')); }
}
function flush() { return new Promise(r => setImmediate(r)); }

function makeEnv(opt = {}) {
  const st = {
    bgMode: 0, restarts: 0, plays: 0, aligns: 0, alignTs: null,
    resumes: 0, workerStarts: 0, ticks: [], blobs: 0, workletModules: 0
  };
  let now = 1000;
  const listeners = [];
  const intervals = [];
  const workletNodes = [];
  let stateListener = null;

  const perf = { now() { return now; } };

  const audioCtx = {
    state: opt.audioState || 'running',
    destination: { id: 'dest' },
    audioWorklet: {
      addModule() { st.workletModules++; return Promise.resolve(); }
    },
    resume() { st.resumes++; this.state = 'running'; return Promise.resolve(); },
    addEventListener(t, fn) { if (t === 'statechange') stateListener = fn; }
  };

  class AudioWorkletNodeMock {
    constructor(ctx, name) {
      this.ctx = ctx;
      this.name = name;
      this.port = { onmessage: null };
      this.connected = 0;
      workletNodes.push(this);
    }
    connect() { this.connected++; }
    disconnect() { this.connected = 0; }
  }

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
      audio_context() { return opt.noAudio ? null : audioCtx; },
      tick_for_background(ts) { st.ticks.push(ts); }
    },
    /* 模拟 Ruffle 原型上的原始实现：一调就 new 一个 Worker */
    startBackgroundTick() {
      st.workerStarts++;
      this.backgroundWorker = { id: st.workerStarts };
    },
    stopBackgroundTick() {
      this.backgroundWorker = null;
    }
  };

  const doc = {
    hidden: !!opt.hidden,
    querySelector: () => (opt.noPlayer ? null : player),
    addEventListener(t, fn) { if (t === 'visibilitychange') listeners.push(fn); }
  };

  const win = {
    performance: perf,
    __moleAlignClock(ts) { st.aligns++; st.alignTs = ts; return true; }
  };

  const ctx = {
    window: win, document: doc, performance: perf,
    console: { log() {}, warn() {}, error() {} },
    JSON, Math, Number, String, Object, Array, Boolean,
    isFinite, isNaN, Date,
    setInterval(fn, ms) { const o = { fn, ms }; intervals.push(o); return intervals.length; },
    clearInterval(id) { const o = intervals[id - 1]; if (o) o.fn = null; },
    setTimeout(fn) { fn(); return 0; },
    clearTimeout() {},
    Blob: class { constructor(parts) { this.parts = parts; } },
    URL: {
      createObjectURL() { st.blobs++; return 'blob:mock'; },
      revokeObjectURL() {}
    },
    AudioWorkletNode: AudioWorkletNodeMock
  };
  vm.createContext(ctx);
  vm.runInContext(code, ctx);

  return {
    win, player, doc, st, listeners, audioCtx, workletNodes,
    audioStateListener() { return stateListener; },
    advance(ms) { now += ms; },
    now() { return now; },
    /* 只触发 50ms 的兜底轮询（第 6 段还有一个 2000ms 的 disarm 轮询） */
    fireTimer() {
      intervals.filter(o => o.fn && o.ms === 50).forEach(o => o.fn());
    },
    fireWorklet() {
      workletNodes.forEach(n => { if (n.port.onmessage) n.port.onmessage({ data: 1 }); });
    },
    fireVisibility() { listeners.forEach(f => f()); }
  };
}

function maxStep(xs) {
  let m = 0;
  for (let i = 1; i < xs.length; i++) m = Math.max(m, Math.abs((xs[i] - xs[i - 1]) - FRAME_MS));
  return m;
}

(async function main() {

  console.log('=== 1) Ruffle 自己的 setTimeout Worker 必须被摘掉 ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    const r = env.player.startBackgroundTick();
    ok('startBackgroundTick 返回 false', r === false);
    ok('没有创建 backgroundWorker', env.player.backgroundWorker === null);
    ok('workerStarts === 0', env.st.workerStarts === 0, 'starts=' + env.st.workerStarts);
    ok('诊断口子报告 disarmed', env.win.__moleBg().disarmed === true);
  }

  console.log('=== 2) 进后台：只取消 rAF、只拉音频，不建 Worker ===');
  {
    const env = makeEnv({ playing: true, audioState: 'suspended' });
    const r = env.win.__moleEnterBackground();
    ok('enter 返回 true', r === true);
    ok('enable_background_tick_mode 调了 1 次', env.st.bgMode === 1);
    ok('AudioContext 被 resume', env.st.resumes >= 1, 'resumes=' + env.st.resumes);
    ok('没有 Worker', env.player.backgroundWorker === null);
  }

  console.log('=== 3) 核心：一拍只推一帧，dt 恒为 41.666ms ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    env.advance(1000);                 // 模拟被节流到 1 秒一次
    env.fireTimer();

    const ts = env.st.ticks;
    ok('一秒补了 24 帧', ts.length === 24, 'got=' + ts.length);
    ok('相邻间隔误差 < 0.01ms', maxStep(ts) < 0.01, 'maxErr=' + maxStep(ts).toFixed(4));
    ok('首帧没有吃掉那 1 秒', ts[0] - 1000 < FRAME_MS + 0.01,
       'first=' + (ts[0] - 1000).toFixed(2));
  }

  console.log('=== 4) 连续 10 轮慢节拍，全程不出现跳变 ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    for (let i = 0; i < 10; i++) { env.advance(1000); env.fireTimer(); }

    const ts = env.st.ticks;
    ok('总帧数量级正确（≈240）', ts.length >= 235 && ts.length <= 245, 'got=' + ts.length);
    ok('240 帧全程 dt 误差 < 0.01ms', maxStep(ts) < 0.01, 'maxErr=' + maxStep(ts).toFixed(4));
    ok('时间轴单调递增', ts.every((v, i) => i === 0 || v > ts[i - 1]));
  }

  console.log('=== 5) 极端节流（10 秒才叫一次）也只能推 CATCHUP_MAX 帧 ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    env.advance(10000);
    env.fireTimer();
    ok('单轮不超过 120 帧', env.st.ticks.length <= 120, 'got=' + env.st.ticks.length);
    ok('仍然没有跳变', maxStep(env.st.ticks) < 0.01);
  }

  console.log('=== 6) AudioWorklet 就绪后接管节拍 ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    await flush();

    ok('addModule 被调用', env.st.workletModules === 1);
    ok('worklet 节点已创建', env.workletNodes.length === 1);
    ok('节点已接到 destination', env.workletNodes[0].connected === 1);
    ok('诊断口子 mode=worklet', env.win.__moleBg().mode === 'worklet');

    env.advance(FRAME_MS);
    env.fireWorklet();
    ok('worklet 触发也能推进', env.st.ticks.length >= 1);
    ok('worklet 推进的 dt 仍是 41.67', maxStep(env.st.ticks) < 0.01);
  }

  console.log('=== 7) worklet + 定时器双源同时叫，不会重复推进 ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    await flush();
    env.advance(FRAME_MS);
    env.fireWorklet();
    const n1 = env.st.ticks.length;
    env.fireTimer();                   // 同一时刻兜底也来一次
    ok('第二次叫不再补帧（幂等）', env.st.ticks.length === n1,
       'before=' + n1 + ' after=' + env.st.ticks.length);
  }

  console.log('=== 8) 音频上下文被挂起后自动拉回 ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    const before = env.st.resumes;
    env.audioCtx.state = 'suspended';
    const l = env.audioStateListener();
    ok('已注册 statechange 监听', typeof l === 'function');
    if (l) l();
    ok('被挂起后再次 resume', env.st.resumes > before,
       'before=' + before + ' after=' + env.st.resumes);
  }

  console.log('=== 9) 回前台：恢复 rAF、把合成轴交回第 0 段 ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    env.advance(1500);
    env.fireTimer();
    const lastTs = env.st.ticks[env.st.ticks.length - 1];

    const r = env.win.__moleLeaveBackground();
    ok('ran=true', r.ran === true);
    ok('报告帧数', r.ticks === env.st.ticks.length);
    ok('restart_animation_loop 调了 1 次', env.st.restarts === 1);
    ok('要求接续时间轴', env.st.aligns === 1 && r.aligned === true);
    ok('交给第 0 段的是合成轴最后一帧', Math.abs(env.st.alignTs - lastTs) < 0.01,
       'alignTs=' + env.st.alignTs + ' lastTs=' + lastTs);
    ok('后台状态已清空', env.win.__moleBg().on === false);
  }
  {
    /* 后台期间被系统挂起过 → 回前台必须立刻拉回来，否则第一帧音频要等好几秒 */
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    env.advance(800);
    env.fireTimer();
    env.audioCtx.state = 'suspended';      // 模拟被系统挂起
    const before = env.st.resumes;
    env.win.__moleLeaveBackground();
    ok('回前台把挂起的 AudioContext 拉回来', env.st.resumes > before,
       'before=' + before + ' after=' + env.st.resumes);
  }

  console.log('=== 10) 游戏本身是暂停态：不为它维持时间轴 ===');
  {
    const env = makeEnv({ playing: false });
    const r = env.win.__moleEnterBackground();
    ok('enter 返回 false', r === false);
    ok('没有 enable_background_tick_mode', env.st.bgMode === 0);
    ok('没有 tick', env.st.ticks.length === 0);
    env.advance(3000);
    env.fireTimer();
    ok('之后也不会偷偷推进', env.st.ticks.length === 0);
  }

  console.log('=== 11) 没有播放器 / 没有音频上下文时不抛 ===');
  {
    const env = makeEnv({ noPlayer: true });
    let threw = false, r1, r2;
    try { r1 = env.win.__moleEnterBackground(); r2 = env.win.__moleLeaveBackground(); }
    catch (e) { threw = true; }
    ok('enter/leave 都不抛', threw === false);
    ok('enter 返回 false', r1 === false);
    ok('leave 返回结构完整', r2 && r2.ran === false && r2.aligned === false);
  }
  {
    const env = makeEnv({ playing: true, noAudio: true });
    let threw = false;
    try { env.win.__moleEnterBackground(); env.advance(100); env.fireTimer(); }
    catch (e) { threw = true; }
    ok('audio_context() 返回 null 时降级到定时器', threw === false && env.st.ticks.length > 0);
  }

  console.log('=== 12) 重复 enter 幂等 ===');
  {
    const env = makeEnv({ playing: true });
    env.win.__moleEnterBackground();
    env.advance(100);
    env.fireTimer();
    const n1 = env.st.ticks.length;
    const r = env.win.__moleEnterBackground();
    ok('第二次 enter 返回 true', r === true);
    ok('没有再调 enable_background_tick_mode', env.st.bgMode === 1);
    env.advance(0);
    env.fireTimer();
    ok('时间轴没有被打乱', maxStep(env.st.ticks) < 0.01 && env.st.ticks.length >= n1);
  }

  console.log('\n' + (fail === 0 ? 'ALL PASS' : 'FAILED') + '  pass=' + pass + ' fail=' + fail);
  process.exit(fail === 0 ? 0 : 1);

})();
