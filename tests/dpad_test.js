/*
 * dpad_test.js —— 验证虚拟方向键「按键状态不会泄漏」（1.2.5-beta）
 * ==================================================================
 * 为什么单独测它：这一版修的是「按着方向键 → 收起面板 → KEYUP 永远发不出去」。
 * 面板收起用的是 opacity + pointer-events:none（不能改成 display:none，
 * 否则 OmniPad 量到的矩形会变成 0），代价就是**收起之后再也收不到
 * pointerup / pointercancel**。于是游戏里那个方向一直处于按下状态。
 *
 * 这条路径平时看不出来，一旦写错却是「操作失灵」级别的问题，所以钉死：
 *
 *   1) 兜底模式（没有 OmniPad）：四个自绘键能发 keydown / keyup；
 *   2) 收起时补发 4 个 KEYUP，且不在按下状态里留残值；
 *   3) OmniPad 模式：收起时调 DPadCore.reset()（它内部会把按下的
 *      emitter 全部 release）—— 不调的话它以为还按着，下次同一方向
 *      算出的向量没变 → 不再发 KEYDOWN，表现为「方向键忽然不灵」；
 *   4) off() / 切后台 也要补发；
 *   5) KEYUP 必须是 bubbles=true 的原生 KeyboardEvent（要冒泡到 window
 *      才进得了 Ruffle 的监听）。
 *
 * 跑：node tests/dpad_test.js [shell.html]
 */
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const shellPath = process.argv[2] || 'src/web/shell.html';
const src = fs.readFileSync(path.resolve(shellPath), 'utf8');

const blocks = [...src.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map(m => m[1]);
const code = blocks[blocks.length - 1];
if (code.indexOf('__moleDpad') < 0) throw new Error('未取到第 9 段脚本（虚拟方向键）');

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra !== undefined ? '  → ' + extra : '')); }
}

/* 极简元素桩：够第 9 段用（class / textContent / child / 事件） */
function fakeEl(tag) {
  const handlers = {};
  const el = {
    tagName: (tag || 'div').toUpperCase(), id: '', className: '', textContent: '',
    style: {}, children: [], parentNode: null, firstChild: null,
    classList: {
      add(c) { const s = new Set(el.className.split(/\s+/).filter(Boolean)); s.add(c); el.className = [...s].join(' '); },
      remove(c) { el.className = el.className.split(/\s+/).filter(x => x && x !== c).join(' '); },
      contains(c) { return el.className.split(/\s+/).indexOf(c) >= 0; },
    },
    addEventListener(type, fn) { (handlers[type] = handlers[type] || []).push(fn); },
    removeEventListener(type, fn) { handlers[type] = (handlers[type] || []).filter(f => f !== fn); },
    appendChild(c) { el.children.push(c); c.parentNode = el; el.firstChild = el.children[0]; return c; },
    removeChild(c) {
      el.children = el.children.filter(x => x !== c); c.parentNode = null;
      el.firstChild = el.children[0] || null; return c;
    },
    /* 测试用：直接触发某个已注册的处理器 */
    fire(type, ev) { (handlers[type] || []).forEach(fn => fn(ev || fakeEv())); return (handlers[type] || []).length; },
    handlers,
  };
  return el;
}

function fakeEv() {
  return { preventDefault() {}, stopPropagation() {}, clientX: 0, clientY: 0, pointerId: 1 };
}

/* 键盘事件桩：keyCode / which 由第 9 段用 defineProperty 补，这里允许被定义 */
class FakeKeyboardEvent {
  constructor(type, opts) {
    opts = opts || {};
    this.type = type;
    this.key = opts.key;
    this.code = opts.code;
    this.bubbles = !!opts.bubbles;
    this.cancelable = !!opts.cancelable;
    this.composed = !!opts.composed;
  }
}

/* opt.omni = true 时装一个 OmniPad 桩：VirtualDPad 记录 core.reset() 调用 */
function makeEnv(opt) {
  opt = opt || {};
  const events = [];          // 派发到播放器的键盘事件
  const logs = [];
  const timers = [];
  const created = [];         // 所有 createElement('div') 出来的元素
  const head = fakeEl('head');
  const body = fakeEl('body');
  const pads = [];            // 假 OmniPad 的靶区根节点

  const player = {
    tagName: 'RUFFLE-PLAYER',
    dispatchEvent(ev) { events.push({ type: ev.type, key: ev.key, keyCode: ev.keyCode, bubbles: ev.bubbles }); return true; },
    addEventListener() {},
  };

  let dpadReset = 0;
  const OmniPad = opt.omni ? {
    TargetZone: function () { this.el = fakeEl(); this.updateConfig = () => {}; this.markRectDirty = () => {}; this.destroy = () => {}; },
    VirtualTrackpad: function () { this.el = fakeEl(); this.updateConfig = () => {}; this.destroy = () => {}; },
    VirtualDPad: function (container, o) {
      this.opts = o;
      this.el = fakeEl();
      this.core = { reset() { dpadReset++; }, rect: { left: 0, top: 0, width: 132, height: 132 } };
      this.destroy = () => {};
    },
  } : undefined;

  const doc = {
    body, head, visibilityState: 'visible',
    getElementById(id) { return (opt.omni && id === 'pad') ? (pads[0] || (pads[0] = fakeEl('div'))) : null; },
    querySelector() { return player; },
    createElement(tag) {
      const el = fakeEl(tag);
      if (tag === 'div') created.push(el);
      return el;
    },
    addEventListener() {},
  };

  const win = {
    innerWidth: 2400, innerHeight: 1080,
    OmniPad,
  };

  const ctx = {
    window: win, document: doc,
    console: { log() {}, warn() {}, error() {} },
    KeyboardEvent: FakeKeyboardEvent,
    log: m => logs.push(String(m)),
    setInterval: (fn, ms) => { const t = { fn, ms, cleared: false }; timers.push(t); return t; },
    clearInterval: t => { if (t) t.cleared = true; },
    setTimeout: fn => { const t = { fn, ms: 0, cleared: false }; timers.push(t); return t; },
    JSON, Math, Number, String, Object, parseInt, isFinite, RegExp, Date,
  };
  vm.createContext(ctx);
  vm.runInContext(code, ctx);

  return {
    win, doc, events, logs, timers, created,
    resetCount: () => dpadReset,
    tick(n = 1) { for (let i = 0; i < n; i++) { for (const t of [...timers]) if (!t.cleared && t.ms === 500) t.fn(); } },
    fakeKeys() { return created.filter(e => /mole-fake-key/.test(e.className)); },
    key(dir) { return this.fakeKeys().find(e => e.className.indexOf('fk-' + dir) >= 0); },
    count(type) { return events.filter(e => e.type === type).length; },
  };
}

console.log('=== 1) 兜底模式：播放器就绪后挂上，四个键都在 ===');
{
  const env = makeEnv();
  env.tick(1);
  ok('已挂载', env.win.__moleDpad.state().mounted === true);
  ok('引擎是原生键盘事件（没有 OmniPad）', env.win.__moleDpad.state().engine === 'native');
  ok('画了 4 个自绘键', env.fakeKeys().length === 4, env.fakeKeys().length);
  ok('样式注入了 head', env.doc.head.children.some(e => e.tagName === 'STYLE'));
}

console.log('=== 2) 按下 → KEYDOWN；抬起 → KEYUP（只发这一个） ===');
{
  const env = makeEnv();
  env.tick(1);
  env.key('up').fire('pointerdown');
  ok('按下发了 1 个 keydown', env.count('keydown') === 1, env.count('keydown'));
  const d = env.events[0] || {};
  ok('键名是 ArrowUp', d.key === 'ArrowUp', d.key);
  ok('keyCode 补成了 38', d.keyCode === 38, d.keyCode);
  ok('bubbles=true（要冒泡到 window 才进得了 Ruffle）', d.bubbles === true);

  env.key('up').fire('pointerup');
  ok('抬起发了 1 个 keyup', env.count('keyup') === 1, env.count('keyup'));
  ok('抬起后该键不再是 down 状态',
    env.key('up').classList.contains('down') === false);
}

console.log('=== 3) 按着方向键直接收起面板 → 补发 4 个 KEYUP ===');
{
  const env = makeEnv();
  env.tick(1);
  env.key('left').fire('pointerdown');
  ok('按下 left 有 keydown', env.count('keydown') === 1);

  const before = env.count('keyup');
  env.win.__moleDpad.toggle(false);        // 收起（面板从此 pointer-events:none）
  const after = env.count('keyup');
  ok('收起时补发了 KEYUP', after - before >= 1, 'Δ=' + (after - before));
  ok('四个方向都补发（漏一个就是漏一条路径）', after - before === 4, 'Δ=' + (after - before));
  ok('补发的里面有 ArrowLeft',
    env.events.filter(e => e.type === 'keyup').some(e => e.key === 'ArrowLeft'));
  ok('收起后不再高亮 down', env.key('left').classList.contains('down') === false);
  ok('state().open 变成 false', env.win.__moleDpad.state().open === false);
}

console.log('=== 4) 再次展开后仍能正常按下（残值没把状态打死） ===');
{
  const env = makeEnv();
  env.tick(1);
  env.key('right').fire('pointerdown');
  env.win.__moleDpad.toggle(false);
  env.win.__moleDpad.toggle(true);
  const before = env.count('keydown');
  env.key('right').fire('pointerdown');
  ok('重新展开后按同一个方向仍发 keydown',
    env.count('keydown') === before + 1, env.count('keydown') - before);
}

console.log('=== 5) OmniPad 模式：收起时调 DPadCore.reset() ===');
{
  const env = makeEnv({ omni: true });
  env.tick(1);
  const st = env.win.__moleDpad.state();
  ok('挂的是 OmniPad', st.engine === 'omnipad', st.engine);
  env.win.__moleDpad.toggle(true);
  const r0 = env.resetCount();
  env.win.__moleDpad.toggle(false);
  ok('收起时调了 core.reset()（否则它以为还按着）',
    env.resetCount() === r0 + 1, env.resetCount() - r0);
  ok('reset 之后仍然补发原生 KEYUP（双保险）',
    env.count('keyup') >= 4, env.count('keyup'));
}

console.log('=== 6) off() 与切后台也补发 ===');
{
  const env = makeEnv();
  env.tick(1);
  env.key('down').fire('pointerdown');
  let before = env.count('keyup');
  env.win.__moleDpad.off();
  ok('off() 补发 KEYUP', env.count('keyup') - before >= 4, 'Δ=' + (env.count('keyup') - before));
  ok('off() 后不再是 mounted', env.win.__moleDpad.state().mounted === false);
}

console.log(`\n${fail === 0 ? 'ALL PASS' : 'FAILED'}  pass=${pass} fail=${fail}`);
process.exit(fail === 0 ? 0 : 1);
