/*
 * logpage_test.js —— 运行日志页 + 右上角浮钮（1.2.7-beta）
 * ==================================================================
 * 这一版新增的是一条「游戏还活着的时候」的路径，出错的代价比崩溃页更大：
 *   · 日志页要是把 #pad 收掉 / 把 player 重载，用户点一下按钮就等于被打断；
 *   · 每 1 秒重建一次报告，要是每次都探 GPU，那就是每秒一个 WebGL 上下文；
 *   · 点分享之后日志还在跳，发出去的正文和用户看到的对不上；
 *   · 系统返回键不能退回游戏 → 用户只能杀进程。
 * 所以这里用假 DOM + 手动定时器把这条路径真正跑一遍，逐条钉死。
 *
 * 跑：node tests/logpage_test.js [shell.html]
 */
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const shellPath = process.argv[2] || 'src/web/shell.html';
const src = fs.readFileSync(path.resolve(shellPath), 'utf8');

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra !== undefined ? '  → ' + extra : '')); }
}

/* ---- 切段：日志页（含 10) 与 10-B) 两个 IIFE） ---- */
const cpStart = src.indexOf('window.__moleCrashPage = (function () {');
const lbStart = src.indexOf('window.__moleLogBtn = (function () {');
const lbEnd = src.indexOf('window.__moleAbout = (function () {');
if (cpStart < 0 || lbStart < 0 || lbEnd < 0) throw new Error('未取到日志页 / 浮钮段');
const cpCode = src.slice(cpStart, lbStart);
const lbCode = src.slice(lbStart, lbEnd);

/* ---- 极简假 DOM ---- */
function makeEl(tag) {
  const el = {
    tagName: String(tag || 'div').toUpperCase(),
    className: '', id: '', textContent: '', value: '', role: '', label: '',
    style: { cssText: '', display: '' },
    children: [], parentNode: null,
    _listeners: {},
    scrollTop: 0, scrollHeight: 0, clientHeight: 0,
    appendChild(c) { this.children.push(c); c.parentNode = this; return c; },
    removeChild(c) {
      const i = this.children.indexOf(c);
      if (i >= 0) this.children.splice(i, 1);
      c.parentNode = null;
      return c;
    },
    setAttribute(k, v) { if (k === 'role') this.role = v; if (k === 'aria-label') this.label = v; },
    getAttribute() { return null; },
    addEventListener(t, fn) { (this._listeners[t] = this._listeners[t] || []).push(fn); },
    removeEventListener() {},
    select() {}, setSelectionRange() {}, focus() {},
    click() { (this._listeners.click || []).forEach(fn => fn({ preventDefault() {}, stopPropagation() {} })); },
  };
  return el;
}

function makeEnv(opts) {
  opts = opts || {};
  const head = makeEl('head');
  const body = makeEl('body');
  const pad = makeEl('div'); pad.id = 'pad';
  const ses = Object.assign({ mole_panic_n: '0' }, opts.session || {});
  const doc = {
    head, body,
    visibilityState: opts.hidden ? 'hidden' : 'visible',
    getElementById: (id) => (id === 'pad' ? pad : null),
    createElement: makeEl,
    execCommand: () => true,
  };

  const shares = [];
  const builds = [];
  const timeouts = [], intervals = [];
  /* 可控时钟：popstate 的「300ms 余波保护」需要把时间推过去 */
  const clock = { t: Date.now() };
  class FakeDate extends Date {
    constructor(...a) { if (a.length) super(...a); else super(clock.t); }
    static now() { return clock.t; }
  }
  const winListeners = {};
  let pushCount = 0, backCount = 0;
  const logLines = opts.logLines || ['WARN| 一条测试日志'];
  let tailCalls = [];

  const win = {
    innerWidth: 800, innerHeight: 360, devicePixelRatio: 2,
    __moleBootAt: Date.now() - 65000,
    __moleRenderer: 'wgpu-webgl',
    __moleRendererTier: 1,
    addEventListener(t, fn) { (winListeners[t] = winListeners[t] || []).push(fn); },
    history: {
      pushState() { pushCount++; },
      back() { backCount++; },
    },
  };
  win.window = win;

  const sandbox = {
    window: win,
    document: doc,
    navigator: { userAgent: 'Mozilla/5.0 (Linux; Android 16; PHK110) Chrome/138 Mobile' },
    screen: { width: 800, height: 360 },
    sessionStorage: {
      getItem: k => (k in ses ? String(ses[k]) : null),
      setItem: (k, v) => { ses[k] = String(v); },
    },
    localStorage: { getItem: () => null, setItem() {} },
    setInterval: (fn, ms) => { const t = { fn, ms, cleared: false }; intervals.push(t); return t; },
    clearInterval: (t) => { if (t) t.cleared = true; },
    setTimeout: (fn, ms) => { const t = { fn, ms, cleared: false }; timeouts.push(t); return t; },
    clearTimeout: (t) => { if (t) t.cleared = true; },
    console: { warn: (m) => (opts.logs || []).push(String(m)), log() {}, error() {} },
    Date: FakeDate, Math, JSON, String, Number, RegExp, parseInt, isFinite, Object, Array,
  };

  if (opts.androidBridge !== false) {
    sandbox.MoleBridge = {
      reportCrash: (n, t) => shares.push({ n, t }),
      saveCrash: (n, t) => shares.push({ n, t, save: true }),
      showAbout: () => {},
    };
    win.MoleBridge = sandbox.MoleBridge;
  }

  /* 第 8 段的报告生成器：这里只要认得参数、能返回声明的正文 */
  sandbox.__logLines = logLines;
  sandbox.__tailCalls = tailCalls;
  win.__moleCrash = {
    build: (k, e, opt) => {
      builds.push({ k, e, opt });
      return '===== 运行日志 =====\n报告类型: ' + k + '\n日志行数: ' + logLines.length;
    },
    tail: (n) => { tailCalls.push(n); return logLines.slice(Math.max(0, logLines.length - n)); },
    info: () => ({ ring: logLines.length, ringMax: 140, errs: 0, autoShared: 0 }),
    share: () => '',
  };

  sandbox.globalThis = sandbox;
  doc.defaultView = win;
  vm.createContext(sandbox);

  return {
    sandbox, win, doc, body, head, pad, shares, builds, timeouts, intervals, winListeners, ses,
    get pushCount() { return pushCount; },
    get backCount() { return backCount; },
    get tailCalls() { return tailCalls; },
    addLine(s) { logLines.push(s); },
    logLines,
    /* 只跑日志页的定时器（按钮的挂载也挂在 setTimeout 上） */
    tickOnce() { intervals.filter(t => !t.cleared).forEach(t => t.fn()); },
    flushTimeouts() {
      const pend = timeouts.filter(t => !t.cleared);
      timeouts.length = 0;
      pend.forEach(t => t.fn());
    },
    firePopstate() { (winListeners.popstate || []).forEach(fn => fn({})); },
    advance(ms) { clock.t += ms; },
    liveTimers() { return intervals.filter(t => !t.cleared); },
  };
}

/* ================================================================
 * 1) 日志页：打开 → 实时刷新
 * ================================================================ */
console.log('=== 1) showLive()：盖上浮层，游戏没被动 ===');
const e1 = makeEnv();
vm.runInContext(cpCode, e1.sandbox);
const page = e1.win.__moleCrashPage;
{
  ok('__moleCrashPage.showLive 已导出', typeof page.showLive === 'function');
  const shown = page.showLive();
  ok('showLive() 返回 true', shown === true, shown);
  ok('状态：shown 且 mode=live', page.state().shown === true && page.state().mode === 'live',
    JSON.stringify(page.state()));

  const host = e1.body.children.find(c => c.id === 'moleCrashPage');
  ok('浮层挂到 body 上，class=on live（横屏两栏靠 live 类）',
    !!host && /(^|\s)on(\s|$)/.test(host.className) && /\blive\b/.test(host.className),
    host && host.className);

  const flat = JSON.stringify(host, (k, v) => (k === 'parentNode' ? undefined : v));
  ok('抬头写的是「运行日志」而不是崩溃', flat.indexOf('运行日志') >= 0 && flat.indexOf('崩溃现场') < 0);
  ok('主按钮是「返回游戏」', flat.indexOf('← 返回游戏') >= 0);
  ok('「关于本作」「复制报告」等原有功能都在',
    flat.indexOf('关于本作') >= 0 && flat.indexOf('复制报告') >= 0 && flat.indexOf('分享日志') >= 0);
  ok('给了日志正文区', flat.indexOf('mcp-log') >= 0);

  ok('起了一个 1 秒的刷新定时器', e1.liveTimers().length === 1 && e1.liveTimers()[0].ms === 1000,
    JSON.stringify(e1.liveTimers().map(t => t.ms)));
  ok('取日志尾巴用的是 40 行', e1.tailCalls.indexOf(40) >= 0, JSON.stringify(e1.tailCalls));
  ok('首帧就出过正文', e1.builds.length >= 1);
}

console.log('=== 2) 每 1 秒重抓，且复用已探测的 GPU（不新建 WebGL 上下文）===');
{
  const last = e1.builds[e1.builds.length - 1];
  ok('build 收到 cachedGpu=true', last.opt && last.opt.cachedGpu === true, JSON.stringify(last.opt));
  ok('build 抬头是「运行日志」', last.opt && last.opt.title === '运行日志', JSON.stringify(last.opt));
  ok('报告类型写明是实时抓取', String(last.k).indexOf('实时') >= 0, last.k);

  const host = e1.body.children.find(c => c.id === 'moleCrashPage');
  const before = JSON.stringify(host, (k, v) => (k === 'parentNode' ? undefined : v));
  e1.addLine('WARN| 转屏后帧率掉了 2 帧');
  e1.tickOnce();
  const after = JSON.stringify(host, (k, v) => (k === 'parentNode' ? undefined : v));
  ok('新日志立刻出现在页面上', after.indexOf('转屏后帧率掉了 2 帧') >= 0);
  ok('页面确实被重绘过（不是空跑）', after !== before);
  ok('每次刷新都带 cachedGpu', e1.builds.every(b => b.opt && b.opt.cachedGpu === true),
    JSON.stringify(e1.builds.map(b => b.opt && b.opt.cachedGpu)));
}

console.log('=== 3) 返回：不重载、不碰 #pad ===');
{
  ok('日志页没有把 #pad 收起来', e1.pad.style.display === '', JSON.stringify(e1.pad.style.display));
  ok('往 history 里塞了一条（吃返回键）', e1.pushCount === 1, e1.pushCount);

  page.close(false);
  ok('close() 之后浮层收起', page.state().shown === false);
  ok('定时器已停', e1.liveTimers().length === 0);
  ok('主动返回会回退那条 history', e1.backCount === 1, e1.backCount);
  ok('没有 reload（= 游戏没被打断）', page.state().shown === false && page.state().mode === 'live');
}

console.log('=== 4) 系统返回键（popstate）也能收页 ===');
{
  const e = makeEnv();
  vm.runInContext(cpCode, e.sandbox);
  const p = e.win.__moleCrashPage;
  p.showLive();
  ok('已打开', p.state().shown === true);
  /* 刚打开 0ms 就来的 popstate 是上一次退回的余波，不许把新页面收掉 */
  e.firePopstate();
  ok('刚打开的 300ms 内忽略余波', p.state().shown === true);
  e.advance(400);
  e.firePopstate();
  ok('popstate 后收起', p.state().shown === false);
  ok('popstate 不再自己 back 一次（不然会连退两级）', e.backCount === 0, e.backCount);
  ok('定时器也停了', e.liveTimers().length === 0);
}

/* ================================================================
 * 5) 分享：先冻结，再拉起分享面板
 * ================================================================ */
console.log('=== 5) 点分享 → 日志停止更新 → 拉系统分享 ===');
{
  const e = makeEnv();
  vm.runInContext(cpCode, e.sandbox);
  const p = e.win.__moleCrashPage;
  p.showLive();
  e.addLine('WARN| 分享前最后一行');

  const before = p.state();
  const okShare = p.share();
  ok('share() 返回 true（桥在）', okShare === true);
  ok('状态标记 frozen', p.state().frozen === true);
  ok('定时器已停', e.liveTimers().length === 0 && p.state().ticking === false);
  ok('正文长度没变（这就是冻结的那一刻）', p.state().size === before.size,
    before.size + ' → ' + p.state().size);

  const sent = e.shares[e.shares.length - 1];
  ok('调了一次 reportCrash', !!sent);
  ok('文件名是 mole-log-*.txt（不是崩溃报告）',
    /^mole-log-\d{8}-\d{6}\.txt$/.test(sent.n), sent.n);
  ok('正文是运行日志', String(sent.t).indexOf('运行日志') >= 0, String(sent.t).slice(0, 40));

  /* 冻结之后再来新日志、再手动 tick，正文都不许变 */
  e.addLine('WARN| 冻结之后才到的日志');
  e.tickOnce();
  const sent2 = e.shares[e.shares.length - 1];
  ok('冻结后不会被后续 tick 改写', sent2.t === sent.t);
  ok('冻结后没有新报告被生成', e.shares.length === 1, e.shares.length);
}

console.log('=== 6) 没有桥 → 退化成复制，不白点 ===');
{
  const e = makeEnv({ androidBridge: false });
  vm.runInContext(cpCode, e.sandbox);
  const p = e.win.__moleCrashPage;
  p.showLive();
  ok('share() 返回 false（无桥）', p.share() === false);
  ok('仍然冻结了日志', p.state().frozen === true);
}

/* ================================================================
 * 7) 日志页开着的时候崩了 → 切回崩溃终局
 * ================================================================ */
console.log('=== 7) 日志页开着时 panic：停表、切成崩溃页 ===');
{
  const e = makeEnv();
  vm.runInContext(cpCode, e.sandbox);
  const p = e.win.__moleCrashPage;
  p.showLive();
  const shown = p.show('Ruffle panic', { '判定': '核心重入类' });
  ok('show() 仍然返回 true', shown === true);
  ok('mode 切回 crash', p.state().mode === 'crash', p.state().mode);
  ok('刷新定时器停了', e.liveTimers().length === 0);
  ok('崩溃页照旧把 #pad 压住', e.pad.style.display === 'none', e.pad.style.display);

  const flat = JSON.stringify(e.body.children.find(c => c.id === 'moleCrashPage'),
    (k, v) => (k === 'parentNode' ? undefined : v));
  ok('主按钮回到「重新进入」', flat.indexOf('重新进入') >= 0 && flat.indexOf('← 返回游戏') < 0);
  ok('抬头回到崩溃现场', flat.indexOf('崩溃现场') >= 0);
  ok('崩溃报告没有传 cachedGpu（现场要现探）',
    !e.builds[e.builds.length - 1].opt || e.builds[e.builds.length - 1].opt.cachedGpu !== true,
    JSON.stringify(e.builds[e.builds.length - 1].opt));
}

/* ================================================================
 * 8) 右上角浮钮
 * ================================================================ */
console.log('=== 8) 浮钮：挂得上、点得动、能被日志页收起来 ===');
{
  const e = makeEnv();
  vm.runInContext(lbCode, e.sandbox);
  const btn = e.win.__moleLogBtn;
  ok('__moleLogBtn 已导出', !!btn);
  ok('挂载是延后的（不挤首帧）', e.body.children.length === 0);
  e.flushTimeouts();

  const el = e.body.children.find(c => c.id === 'moleLogBtn');
  ok('按钮已挂到 body', !!el);
  ok('按钮文字是「日志」', el && el.textContent === '日志', el && el.textContent);
  ok('带有无障碍标签', el && el.label === '查看并分享运行日志', el && el.label);
  ok('样式注入了右上角定位', !!e.head.children.find(c => c.id === 'moleLogBtnCss'));
  const cssText = (e.head.children.find(c => c.id === 'moleLogBtnCss') || {}).textContent || '';
  ok('CSS 里是 right/top 定位且 z-index 13',
    /right:calc\(10px \+ env\(safe-area-inset-right\)\)/.test(cssText)
    && /top:calc\(10px \+ env\(safe-area-inset-top\)\)/.test(cssText)
    && /z-index:13/.test(cssText), cssText.slice(0, 80));
  ok('只注入一次样式', e.head.children.filter(c => c.id === 'moleLogBtnCss').length === 1);

  /* 点一下 → 交给日志页 */
  let liveCalls = 0;
  e.win.__moleCrashPage = { showLive: () => { liveCalls++; return true; } };
  el.click();
  ok('点击调用 __moleCrashPage.showLive()', liveCalls === 1, liveCalls);
  ok('state().opens 计数', btn.state().opens === 1, JSON.stringify(btn.state()));

  btn.hide();
  ok('hide() 把按钮藏起来', el.style.display === 'none');
  btn.show();
  ok('show() 恢复', el.style.display === '');
}

console.log('=== 9) 日志页建不起来时，浮钮退化成直接分享 ===');
{
  const e = makeEnv();
  vm.runInContext(lbCode, e.sandbox);
  const btn = e.win.__moleLogBtn;
  e.flushTimeouts();
  const el = e.body.children.find(c => c.id === 'moleLogBtn');
  let shared = 0;
  e.win.__moleCrashPage = { showLive: () => false };
  e.win.__moleCrash = { share: () => { shared++; return 'x'; } };
  el.click();
  ok('仍然调了一次分享（按钮永远不「点了没反应」）', shared === 1, shared);
}

console.log('');
if (fail) { console.log('FAILED  pass=' + pass + ' fail=' + fail); process.exit(1); }
console.log('ALL PASS  pass=' + pass + ' fail=' + fail);
