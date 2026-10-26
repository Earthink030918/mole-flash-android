/*
 * bg_test.js —— 验证 1.1.2 的「逻辑 + 音频原子冻结」
 * ==================================================
 * 直接从 shell.html 里切出第 6 段跑，player / instance / AudioContext
 * 全部用桩替代。测的是我们写的那层冻结状态机。
 *
 * 针对用户 1.1.1 实测的两条：「切回来有严重爆破音」「切回来画面卡顿」，
 * 以及新报的「挂久了应用自己崩溃」。
 *
 * 结论性事实（都能在源码里对上）：
 *   core/src/backend/audio.rs  audio_skew_time()
 *     stream_pos   = get_sound_position()          // 音频后端已混音到第几秒
 *     timeline_pos = current_frame / frame_rate    // 时间轴走到第几秒
 *     if skew.abs() >= 1.0 { stop_sound(); }       // 硬切流音 = 爆破音
 *   web/src/audio.rs  Buffer::play() 才调 mix()，play() 只由 onended 触发
 *   → onended 是主线程事件，页面 hidden 被压到 1Hz，stream_pos 必然掉队
 *   → 只要后台还在 tick，就一定会周期性 stop_sound。这是 pull 模型的硬约束。
 *
 * 所以 1.1.2 的做法是「一起停」：
 *   A. inst.pause() 是一对原子操作（core → Suspended，AudioContext → suspend），
 *      两条时间轴同时冻结，skew 不再增长；
 *   B. 冻结前必须先把音量淡到 0（suspend 会在波形中途切断 = 那声「啪」）；
 *   C. 回前台必须先静音再 play()，再淡回原音量；
 *   D. 全程不调 enable_background_tick_mode / restart_animation_loop，
 *      也不让 Ruffle 自己的 visibilitychange 跑到（否则它会无条件 play()）。
 */
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const shell = process.argv[2] || 'src/web/shell.html';
const src = fs.readFileSync(path.resolve(shell), 'utf8');

const blocks = [...src.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map(m => m[1]);
const block = blocks[blocks.length - 1];
const at = block.indexOf('6) 后台：逻辑与音频');
if (at < 0) throw new Error('未找到第 6 段');
const code = block.slice(block.lastIndexOf('/*', at));

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra ? '  → ' + extra : '')); }
}
const near = (a, b, eps = 0.001) => Math.abs(a - b) <= eps;

function makeEnv(opt = {}) {
  let now = 1000;
  const timers = [];
  const intervals = [];
  const winListeners = [];
  const docListeners = [];

  const log = {
    events: [],
    vol: [],
    pause: 0, play: 0, bgTick: 0, restart: 0,
    ctxResume: 0, ctxSuspend: 0, worker: 0
  };

  const perf = { now() { return now; } };

  const ctx = {
    state: opt.ctxState || 'running',
    resume() { log.ctxResume++; this.state = 'running'; return Promise.resolve(); },
    suspend() { log.ctxSuspend++; this.state = 'suspended'; return Promise.resolve(); }
  };

  const instance = {
    __playing: opt.playing !== false,
    __vol: (opt.vol == null ? 1 : opt.vol),
    is_playing() { return this.__playing; },
    play() { log.play++; log.events.push('play'); this.__playing = true; ctx.resume(); },
    pause() { log.pause++; log.events.push('pause'); this.__playing = false; ctx.suspend(); },
    volume() { return this.__vol; },
    set_volume(v) { log.vol.push(v); log.events.push('vol:' + v.toFixed(3)); this.__vol = v; },
    audio_context() { return ctx; },
    enable_background_tick_mode() { log.bgTick++; log.events.push('bgTick'); },
    restart_animation_loop() { log.restart++; log.events.push('restart'); }
  };

  const player = { instance, lastActivePlayingState: true };

  const win = {
    performance: perf,
    addEventListener(t, fn, cap) { winListeners.push({ t, fn, cap }); },
    setTimeout(fn, ms) { timers.push({ fn, ms }); return timers.length; },
    setInterval(fn, ms) { intervals.push(fn); return intervals.length; }
  };

  const doc = {
    hidden: false,
    querySelector() { return player; },
    addEventListener(t, fn) { docListeners.push({ t, fn }); }
  };

  const sandbox = {
    window: win, document: doc, performance: perf,
    console: { log() {}, warn() {}, error() {} },
    setTimeout: win.setTimeout, setInterval: win.setInterval,
    Math, Number, Date, Promise, Object, String, isFinite
  };
  vm.createContext(sandbox);
  vm.runInContext(code, sandbox);

  return {
    win, doc, instance, player, log, ctx,
    frozen() { return win.__moleBgFrozen(); },
    enter() { return win.__moleEnterBackground(); },
    leave() { return win.__moleLeaveBackground(); },
    bg() { return win.__moleBg(); },
    advance(ms) { now += ms; },
    /* 把当前排队的 setTimeout 全部跑完（淡出/淡入） */
    flush(max = 400) {
      let n = 0;
      while (timers.length && n++ < max) timers.shift().fn();
      return n;
    },
    /* 模拟一次 visibilitychange：先走 window 捕获，再决定放不放给 document */
    fireVis() {
      const e = { stopped: false, stopImmediatePropagation() { this.stopped = true; } };
      winListeners.filter(l => l.t === 'visibilitychange' && l.cap).forEach(l => l.fn(e));
      let docRan = 0;
      if (!e.stopped) {
        docListeners.filter(l => l.t === 'visibilitychange').forEach(l => { docRan++; l.fn({}); });
      }
      return { stopped: e.stopped, docRan };
    },
    /* 模拟 Ruffle 自己的监听器（用来证明它被拦掉了） */
    installRuffleListener() {
      doc.addEventListener('visibilitychange', () => {
        log.events.push('ruffle-vis');
        if (!doc.hidden) { instance.play(); ctx.resume(); }
        else { instance.enable_background_tick_mode(); instance.pause(); }
      });
    }
  };
}

console.log('=== 1) 进后台：先淡出到 0，再原子冻结 ===');
{
  const env = makeEnv();
  ok('进后台前 frozen=false', env.frozen() === false);
  ok('进后台返回 true', env.enter() === true);
  ok('立刻进入冻结态（时钟据此停）', env.frozen() === true);

  env.flush();
  ok('淡出走完，最后一步音量是 0',
     near(env.log.vol[env.log.vol.length - 1], 0, 1e-9),
     'last=' + env.log.vol[env.log.vol.length - 1]);
  ok('音量是逐步降下去的（不是硬切）', env.log.vol.length >= 5, 'steps=' + env.log.vol.length);
  ok('单调下降',
     env.log.vol.every((v, i) => i === 0 || v <= env.log.vol[i - 1] + 1e-9),
     JSON.stringify(env.log.vol));

  /* 顺序：pause 必须在最后一次 set_volume(0) 之后 */
  const iLastVol = env.log.events.map(e => e.indexOf('vol:')).lastIndexOf(0);
  const iPause = env.log.events.indexOf('pause');
  ok('pause() 发生在淡出之后', iPause > 0 && env.log.events[iPause - 1].indexOf('vol:') === 0,
     JSON.stringify(env.log.events));
  ok('pause() 只调一次', env.log.pause === 1);
  ok('AudioContext 被挂起（suspend 由 pause 带出）', env.ctx.state === 'suspended');
  ok('没有用 enable_background_tick_mode 抢 rAF', env.log.bgTick === 0);
}

console.log('=== 2) 幂等：Java onPause 与 visibilitychange 各叫一次 ===');
{
  const env = makeEnv();
  env.enter(); env.flush();
  env.enter(); env.flush();
  ok('pause() 仍然只有 1 次', env.log.pause === 1, 'pause=' + env.log.pause);
  ok('冻结态保持', env.frozen() === true);
  ok('enters 计数 1', env.bg().enters === 1, 'enters=' + env.bg().enters);
}

console.log('=== 3) 回前台：静音 → play() → 淡回原音量 ===');
{
  const env = makeEnv({ vol: 0.5 });
  env.enter(); env.flush();
  ok('冻结时记住了原音量 0.5', near(env.bg().vol, 0.5, 1e-9), 'vol=' + env.bg().vol);

  env.log.events.length = 0;
  const r = env.leave();
  ok('返回 ran=true', r.ran === true);
  ok('返回 resumed=true', r.resumed === true);
  ok('第一件事是把音量压到 0', env.log.events[0] === 'vol:0.000',
     'first=' + env.log.events[0]);
  ok('紧接着才 play()', env.log.events[1] === 'play', JSON.stringify(env.log.events.slice(0, 3)));
  ok('play() 只有 1 次', env.log.play === 1);
  ok('没有调 restart_animation_loop（防双倍速）', env.log.restart === 0);

  env.flush();
  ok('淡入结束回到原音量 0.5', near(env.instance.__vol, 0.5, 1e-9),
     'vol=' + env.instance.__vol);
  ok('淡入是逐步升上去的', env.log.vol.filter(v => v > 0).length >= 4, JSON.stringify(env.log.vol));
  ok('解冻后 frozen=false', env.frozen() === false);
}

console.log('=== 4) 冻结前就是暂停态：回前台不许擅自 play() ===');
{
  const env = makeEnv({ playing: false });
  env.enter(); env.flush();
  ok('冻结时记下 wasPlaying=false', env.bg().wasPlaying === false);
  env.leave(); env.flush();
  ok('没有调用 play()', env.log.play === 0, 'play=' + env.log.play);
  ok('音量照样还回去', near(env.instance.__vol, 1, 1e-9), 'vol=' + env.instance.__vol);
}

console.log('=== 5) 没冻结过时 leave 是纯 no-op ===');
{
  const env = makeEnv({ vol: 0.7 });
  const r = env.leave();
  ok('返回 ran=false', r.ran === false, JSON.stringify(r));
  ok('没有碰音量', env.log.vol.length === 0, JSON.stringify(env.log.vol));
  ok('没有 play()', env.log.play === 0);
}

console.log('=== 6) 快切（淡出还没走完就回来）不许把游戏冻住 ===');
{
  const env = makeEnv();
  env.enter();                 // 只走了第一步淡出，定时器还没跑
  const r = env.leave();       // 立刻回前台
  env.flush();
  ok('最终没有 pause()', env.log.pause === 0, 'pause=' + env.log.pause);
  ok('状态已解冻', env.frozen() === false);
  ok('音量回到 1', near(env.instance.__vol, 1, 1e-9), 'vol=' + env.instance.__vol);
  ok('leave 认为自己在跑', r.ran === true);
}

console.log('=== 7) 拦掉 Ruffle 的 visibilitychange（它会无条件 play） ===');
{
  const env = makeEnv();
  env.installRuffleListener();

  env.doc.hidden = true;
  const e1 = env.fireVis();
  ok('捕获阶段就 stopImmediatePropagation', e1.stopped === true);
  ok('document 上的监听器一次都没跑', e1.docRan === 0, 'docRan=' + e1.docRan);
  ok('Ruffle 的 hidden 分支没执行', env.log.events.indexOf('ruffle-vis') < 0);
  ok('我们自己没调 enable_background_tick_mode', env.log.bgTick === 0);

  env.flush();
  ok('hidden 之后确实进冻结态', env.frozen() === true);
  ok('pause 恰好一次', env.log.pause === 1);

  env.doc.hidden = false;
  const e2 = env.fireVis();
  ok('visible 同样被拦下', e2.stopped === true && e2.docRan === 0);
  ok('解冻', env.frozen() === false);
  ok('play() 只有我们自己那一次', env.log.play === 1, 'play=' + env.log.play);
}

console.log('=== 8) 摘掉 Ruffle 的后台 Worker ===');
{
  const env = makeEnv();
  env.enter(); env.flush();
  ok('startBackgroundTick 被摘成空函数（返回 false）',
     env.player.startBackgroundTick() === false);
  ok('stopBackgroundTick 可直接调用不抛错', (() => {
    try { env.player.stopBackgroundTick(); return true; } catch (e) { return false; }
  })());
  ok('disarmed 标记已置', env.player.__moleDisarmed === 1);
}

console.log('=== 9) 分辨率无关：音量 0 / 1 的边界 ===');
{
  const e0 = makeEnv({ vol: 0 });
  e0.enter(); e0.flush();
  ok('原音量 0 时不出现负数', e0.log.vol.every(v => v >= 0), JSON.stringify(e0.log.vol));
  e0.leave(); e0.flush();
  ok('回前台仍是 0', near(e0.instance.__vol, 0, 1e-9), 'vol=' + e0.instance.__vol);

  const e1 = makeEnv({ vol: 1 });
  e1.enter(); e1.flush();
  ok('原音量 1 时不超过 1', e1.log.vol.every(v => v <= 1), JSON.stringify(e1.log.vol));
  e1.leave(); e1.flush();
  ok('回前台仍是 1', near(e1.instance.__vol, 1, 1e-9));
}

console.log('=== 10) 连续 10 轮切后台/回前台，状态不漂 ===');
{
  const env = makeEnv({ vol: 0.8 });
  for (let i = 0; i < 10; i++) {
    env.advance(60000);
    env.enter(); env.flush();
    if (!env.frozen()) { ok('第 ' + (i + 1) + ' 轮冻结失败', false); break; }
    env.leave(); env.flush();
    if (env.frozen()) { ok('第 ' + (i + 1) + ' 轮解冻失败', false); break; }
  }
  ok('10 轮后 pause/play 各 10 次', env.log.pause === 10 && env.log.play === 10,
     'pause=' + env.log.pause + ' play=' + env.log.play);
  ok('10 轮后音量仍是 0.8', near(env.instance.__vol, 0.8, 1e-9), 'vol=' + env.instance.__vol);
  ok('音频上下文最终是 running', env.ctx.state === 'running', env.ctx.state);
  ok('诊断计数 10 进 10 出', env.bg().enters === 10 && env.bg().leaves === 10,
     JSON.stringify({ e: env.bg().enters, l: env.bg().leaves }));
  ok('没有偷偷调 enable_background_tick_mode / restart_animation_loop',
     env.log.bgTick === 0 && env.log.restart === 0);
}

console.log('\n' + (fail === 0 ? 'ALL PASS' : 'FAILED') + '  pass=' + pass + ' fail=' + fail);
process.exit(fail === 0 ? 0 : 1);
