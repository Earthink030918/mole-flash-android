/*
 * panic_test.js —— 验证「panic 面板侦测 + 渲染后端降级」（1.1.5-beta）
 * ==================================================================
 * 为什么单独测它：这一版改的是「Ruffle 崩了以后怎么办」，而这条路径
 * 平时根本不会跑 —— 一旦写错，表现就是"红屏永远挂在那儿"或者"无限重载死循环"，
 * 比原来的 bug 更糟。所以把语义逐条钉死：
 *
 *   1) 不再依赖 Ruffle 的 'panic' 事件（它压根不派发，是被写错的死代码）；
 *   2) 面板要从 shadowRoot 里查（#panic 挂在 shadow 的 #container 下）；
 *   3) 文本取自 #panic-title / #panic-body / 详情 textarea；
 *   4) 判定为 GPU/驱动类 → 后端降一级；判定为内容类 → 档位不动，只重载；
 *   5) 每个播放器只处理一次（反复 append 不会重复上报）；
 *   6) 重载通知走 MoleBridge.onPanic()；
 *   7) 会话内重载次数有上限，到顶后不再通知（防无限闪烁）；
 *   8) shell 侧档位：读 localStorage、越界钳制、到底后 bump 返回 null。
 *
 * 跑：node tests/panic_test.js [mole_boot.js] [shell.html]
 */
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const bootPath = process.argv[2] || 'src/web/mole_boot.js';
const shellPath = process.argv[3] || 'src/web/shell.html';

const bootSrc = fs.readFileSync(path.resolve(bootPath), 'utf8');
const shellSrc = fs.readFileSync(path.resolve(shellPath), 'utf8');

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra !== undefined ? '  → ' + extra : '')); }
}

/* ---------------------------------------------------------------
 * 0) 静态检查：不再有 'panic' 事件监听
 * --------------------------------------------------------------- */
console.log('=== 0) 死代码已清除 ===');
ok('事件类型表里已经没有 panic',
  !/var types = \[[^\]]*'panic'/.test(bootSrc));
ok('注释里写明 Ruffle 只派发 loadedmetadata/loadeddata',
  bootSrc.indexOf('loadedmetadata / loadeddata') >= 0);

/* ---------------------------------------------------------------
 * 1) 切出 panic 侦测段，在假环境里跑
 * --------------------------------------------------------------- */
const aMark = bootSrc.indexOf('function panicRoot');
const bMark = bootSrc.indexOf('/** 路径 A');
if (aMark < 0 || bMark < 0) throw new Error('未取到 panic 侦测段');
const code = bootSrc.slice(aMark, bMark);

function makeEnv(opts) {
  opts = opts || {};
  const logs = [];
  const bridge = { panic: 0 };
  const store = Object.assign({}, opts.session || {});
  const sessionStorage = {
    getItem: k => (k in store ? store[k] : null),
    setItem: (k, v) => { store[k] = String(v); },
  };
  const win = {
    __moleRenderer: opts.renderer || 'wgpu-webgl',
    __moleRendererTier: opts.tier || 0,
    __moleBootAt: Date.now() - 5000,
    __moleRendererBump: undefined,
  };
  const sandbox = {
    window: win,
    sessionStorage,
    localStorage: sessionStorage,
    MoleBridge: { onPanic() { bridge.panic++; } },
    Date, Math, JSON, String, RegExp, isFinite, parseInt,
    setTimeout: (fn) => { /* 不真的排程，避免测试里重载 */ return 0; },
    MutationObserver: class { constructor(fn) { this.fn = fn; } observe() {} disconnect() {} },
    log: (m) => logs.push(String(m)),
  };
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);
  vm.runInContext(code, sandbox);
  return { sandbox, logs, bridge, store };
}

/* 假播放器：shadowRoot 里有 #container，panic 面板 append 进去 */
function makePlayer(panel) {
  const nodes = {};
  const sh = {
    getElementById: id => (id === 'panic' ? (nodes.panic || null) : (nodes[id] || null)),
    querySelector: sel => {
      if (sel.indexOf('textarea') >= 0) return nodes.ta || null;
      return null;
    },
  };
  const p = { shadowRoot: sh, __tag: 'ruffle-player' };
  if (panel) {
    nodes.panic = { id: 'panic' };
    nodes['panic-title'] = { textContent: panel.title || '' };
    nodes['panic-body'] = { textContent: panel.body || '' };
    if (panel.detail) nodes.ta = { value: panel.detail };
  }
  return p;
}

console.log('=== 1) 面板定位在 shadowRoot ===');
{
  const { sandbox } = makeEnv();
  const p0 = makePlayer(null);
  ok('没有面板时 hasPanic=false', sandbox.hasPanic(p0) === false);
  const p1 = makePlayer({ title: 'Something went wrong :(', body: 'x' });
  ok('面板在 shadowRoot 里能被找到', sandbox.hasPanic(p1) === true);
  ok('light DOM（p.querySelector）找不到 —— 这就是以前漏判的原因',
    typeof p1.querySelector === 'undefined');
  p1.querySelector = () => null;
  ok('即便 light DOM 查不到，hasPanic 仍为 true', sandbox.hasPanic(p1) === true);
}

console.log('=== 2) 文本抽取 ===');
{
  const { sandbox } = makeEnv();
  const p = makePlayer({
    title: 'Something went wrong :(',
    body: 'Error creating player: Unable to create renderer',
    detail: 'panicked at wgpu-core/src/backend/wgpu_core.rs:1414',
  });
  const t = sandbox.panicText(p);
  ok('title 取到', t.title === 'Something went wrong :(', t.title);
  ok('body 取到', t.body.indexOf('Unable to create renderer') >= 0, t.body);
  ok('详情 textarea 取到', t.detail.indexOf('wgpu_core.rs') >= 0, t.detail);
  ok('没有 shadowRoot 时不抛异常',
    sandbox.panicText({}).title === '');
}

console.log('=== 3) GPU 类 panic → 后端降级 ===');
{
  const { sandbox, logs, bridge } = makeEnv();
  let bumped = 0;
  sandbox.window.__moleRendererBump = () => { bumped++; return 'webgl'; };
  const p = makePlayer({
    title: 'Something went wrong :(',
    body: 'wgpu error: Validation Error: shader compilation failed',
  });
  sandbox.onPanicDom(p);
  ok('调用了一次档位降级', bumped === 1, bumped);
  ok('日志里写明"改用 webgl"',
    logs.some(l => l.indexOf('改用 webgl') >= 0), logs.join(' / '));
  ok('通知 Java 重载', bridge.panic === 1, bridge.panic);
  ok('日志带上后端与运行时长',
    logs.some(l => l.indexOf('后端=wgpu-webgl') >= 0 && l.indexOf('已运行=') >= 0));
}

console.log('=== 4) 内容类 panic → 不降级，只重载 ===');
{
  const { sandbox, logs, bridge } = makeEnv();
  let bumped = 0;
  sandbox.window.__moleRendererBump = () => { bumped++; return 'webgl'; };
  const p = makePlayer({
    title: 'Something went wrong :(',
    body: 'Error: AVM2 instruction not supported (0xEF)',
  });
  sandbox.onPanicDom(p);
  ok('没有降级', bumped === 0, bumped);
  ok('日志说明"档位不变"',
    logs.some(l => l.indexOf('后端档位不变') >= 0), logs.join(' / '));
  ok('仍然通知重载', bridge.panic === 1, bridge.panic);
}

console.log('=== 5) 同一个播放器只处理一次 ===');
{
  const { sandbox, bridge } = makeEnv();
  sandbox.window.__moleRendererBump = () => 'webgl';
  const p = makePlayer({ title: 't', body: 'gpu lost' });
  sandbox.onPanicDom(p);
  sandbox.onPanicDom(p);
  sandbox.onPanicDom(p);
  ok('只降级一次', p.__molePanicAt > 0);
  ok('只通知一次', bridge.panic === 1, bridge.panic);
}

console.log('=== 6) 会话内次数上限 ===');
{
  const { sandbox, bridge, store } = makeEnv({ session: { mole_panic_n: '4' } });
  sandbox.window.__moleRendererBump = () => 'canvas';
  const p = makePlayer({ title: 't', body: 'wgpu panic' });
  sandbox.onPanicDom(p);
  ok('第 5 次不再通知重载', bridge.panic === 0, bridge.panic);
  ok('计数已推进到 5', store.mole_panic_n === '5', store.mole_panic_n);
}

console.log('=== 7) 计数存 sessionStorage（随本次启动重置） ===');
{
  const { sandbox, store } = makeEnv();
  sandbox.window.__moleRendererBump = () => 'webgl';
  sandbox.onPanicDom(makePlayer({ title: 't', body: 'webgl lost' }));
  ok('写进了 sessionStorage', store.mole_panic_n === '1', JSON.stringify(store));
  ok('上限常量是 4', code.indexOf('PANIC_MAX = 4') >= 0);
}

console.log('=== 8) 桥不可用时的自救 ===');
{
  const { sandbox, logs } = makeEnv();
  sandbox.MoleBridge = { onPanic() { throw new Error('no bridge'); } };
  sandbox.window.__moleRendererBump = () => 'webgl';
  let threw = 0;
  try { sandbox.onPanicDom(makePlayer({ title: 't', body: 'wgpu' })); } catch (e) { threw++; }
  ok('不把异常抛给调用方', threw === 0);
  ok('日志记录了自救', logs.some(l => l.indexOf('桥不可用') >= 0), logs.join(' / '));
}

/* ---------------------------------------------------------------
 * 9) shell 侧档位表
 * --------------------------------------------------------------- */
console.log('=== 9) 渲染后端档位表 ===');
const mMark = shellSrc.indexOf('var RENDERER_LADDER');
const mEnd = shellSrc.indexOf('};', shellSrc.indexOf('window.__moleRendererBump'));
if (mMark < 0 || mEnd < 0) throw new Error('未取到 shell 档位段');
const tierCode = shellSrc.slice(mMark, mEnd + 2);

function runTier(saved) {
  const store = {};
  if (saved !== null && saved !== undefined) store.mole_renderer_tier = String(saved);
  /* 真实页面在第 0.3 段之前就先写了 window.__moleRenderer = RENDERER（Java 注入值） */
  const win = { __moleRenderer: 'wgpu-webgl' };
  const sandbox = {
    window: win,
    localStorage: {
      getItem: k => (k in store ? store[k] : null),
      setItem: (k, v) => { store[k] = String(v); },
    },
    Math, JSON, parseInt, isFinite, Date,
  };
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);
  vm.runInContext('var RENDERER = "wgpu-webgl";' + tierCode, sandbox);
  return { win, store, sandbox };
}

{
  const { win } = runTier(null);
  ok('默认档位 0', win.__moleRendererTier === 0, win.__moleRendererTier);
  ok('默认后端 wgpu-webgl', win.__moleRenderer === 'wgpu-webgl', win.__moleRenderer);
}
{
  const { win } = runTier(1);
  ok('档位 1 → webgl', win.__moleRenderer === 'webgl', win.__moleRenderer);
}
{
  const { win } = runTier(2);
  ok('档位 2 → canvas', win.__moleRenderer === 'canvas', win.__moleRenderer);
}
{
  const { win } = runTier(99);
  ok('越界钳制到 canvas', win.__moleRenderer === 'canvas' && win.__moleRendererTier === 2,
    win.__moleRendererTier);
}
{
  const { win } = runTier('abc');
  ok('脏值回落 0', win.__moleRendererTier === 0, win.__moleRendererTier);
}
{
  const { win, store } = runTier(0);
  ok('bump 从 0 → 返回 webgl', win.__moleRendererBump() === 'webgl');
  ok('落盘为 1', store.mole_renderer_tier === '1', store.mole_renderer_tier);
}
{
  const { win } = runTier(2);
  ok('到底后 bump 返回 null（不会再"降级"）', win.__moleRendererBump() === null);
}

console.log('');
if (fail) { console.log('FAILED  pass=' + pass + ' fail=' + fail); process.exit(1); }
console.log('ALL PASS  pass=' + pass + ' fail=' + fail);
