/*
 * crashui_test.js —— 崩溃页 + 关于弹窗（1.2.6-beta）
 * ==================================================================
 * 这两块是「用户唯一会亲眼看到的东西」，写错了比 bug 本身更难看：
 *   · 崩溃页建不起来 → 用户还是只能看到红屏（等于没做）；
 *   · 分享按钮没接到 Java 桥 → 点下去毫无反应；
 *   · 关于弹窗在鸿蒙上被当成安卓调用 → 什么都不弹；
 *   · 红字段落丢了 → 最该强调的那句「非官方」变成灰字。
 * 所以这里用一个极简的假 DOM 把两段真正跑一遍，逐条钉死。
 *
 * 跑：node tests/crashui_test.js [shell.html]
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

/* ---- 切出两段 IIFE ---- */
const cpStart = src.indexOf('window.__moleCrashPage = (function () {');
const abStart = src.indexOf('window.__moleAbout = (function () {');
const abEnd = src.indexOf('</script>', abStart);
if (cpStart < 0 || abStart < 0 || abEnd < 0) throw new Error('未取到崩溃页 / 关于弹窗段');
const cpCode = src.slice(cpStart, abStart);
const abCode = src.slice(abStart, abEnd);

/* ---- 极简假 DOM：够用即可，不做渲染 ---- */
function makeEl(tag) {
  const el = {
    tagName: String(tag || 'div').toUpperCase(),
    className: '',
    id: '',
    textContent: '',
    value: '',
    style: { cssText: '', display: '' },
    children: [],
    parentNode: null,
    _listeners: {},
    appendChild(c) { this.children.push(c); c.parentNode = this; return c; },
    removeChild(c) {
      const i = this.children.indexOf(c);
      if (i >= 0) this.children.splice(i, 1);
      c.parentNode = null;
      return c;
    },
    setAttribute() {},
    addEventListener(t, fn) { (this._listeners[t] = this._listeners[t] || []).push(fn); },
    removeEventListener() {},
    select() {},
    setSelectionRange() {},
    click() { (this._listeners.click || []).forEach(fn => fn({ preventDefault() {}, stopPropagation() {} })); },
  };
  Object.defineProperty(el, 'firstChild', { get() { return this.children[0] || null; } });
  return el;
}

function makeEnv(opts) {
  opts = opts || {};
  const head = makeEl('head');
  const body = makeEl('body');
  const store = {};
  const doc = {
    head,
    body,
    visibilityState: 'visible',
    getElementById: () => null,
    createElement: makeEl,
    execCommand: () => (opts.execCopy === false ? false : true),
    documentElement: { style: { setProperty() {} } },
  };
  const ses = opts.session || {};
  const shares = [];
  const aboutCalls = [];
  const harmonyCalls = [];
  const win = {};
  const sandbox = {
    window: win,
    document: doc,
    navigator: { userAgent: opts.ua || 'Mozilla/5.0 (Linux; Android 16; PHK110) Chrome/138 Mobile' },
    localStorage: {
      getItem: k => (k in store ? store[k] : null),
      setItem: (k, v) => { store[k] = String(v); },
    },
    sessionStorage: { getItem: k => (k in ses ? String(ses[k]) : null), setItem(k, v) { ses[k] = String(v); } },
    setTimeout: (fn, ms) => { if (opts.runTimers) fn(); return 0; },
    clearTimeout: () => {},
    console: { warn: (m) => (opts.logs || []).push(String(m)), log: () => {} },
    Date, Math, JSON, String, Number, RegExp, parseInt, isFinite, Object, Array,
  };
  if (opts.androidBridge !== false) {
    sandbox.MoleBridge = {
      reportCrash: (n, t) => shares.push({ n, t }),
      saveCrash: (n, t) => shares.push({ n, t, save: true }),
      showAbout: (f) => aboutCalls.push(f),
    };
  }
  if (opts.harmonyBridge) {
    sandbox.NativeBridge = { showAbout: (j) => harmonyCalls.push(j) };
  }
  sandbox.globalThis = sandbox;
  sandbox.window.document = doc;
  sandbox.window.navigator = sandbox.navigator;
  /* 真页面里 window 就是全局对象，MoleBridge 两边都看得见；
     这里 window 是单独的对象，得手动挂一份。 */
  if (sandbox.MoleBridge) sandbox.window.MoleBridge = sandbox.MoleBridge;
  if (sandbox.NativeBridge) sandbox.window.NativeBridge = sandbox.NativeBridge;
  /* 第 8 段的报告生成器：崩溃页只负责「摆页面」，正文由它出 */
  if (opts.crashBuilder !== false) {
    sandbox.window.__moleCrash = {
      build: (k, e) => '===== 摩尔庄园 Flash 客户端 · 崩溃报告 =====\n报告类型: ' + k,
      save: () => 'mole-crash.txt',
      auto: () => null,
      share: () => '',
    };
  }
  vm.createContext(sandbox);
  return { sandbox, doc, store, shares, aboutCalls, harmonyCalls, win, head, body };
}

/* ================================================================
 * 1) 崩溃页
 * ================================================================ */
console.log('=== 1) 崩溃页能建起来，并显示现场 ===');
{
  const env = makeEnv({ session: { mole_panic_n: '2' } });
  vm.runInContext(cpCode, env.sandbox);
  const page = env.sandbox.window.__moleCrashPage;
  ok('__moleCrashPage 已导出', !!page, typeof page);

  const t0 = Date.now() - 30000;
  env.sandbox.window.__moleBootAt = t0;
  env.sandbox.window.__moleRenderer = 'wgpu-webgl';
  env.sandbox.window.__moleRendererTier = 1;

  const shown = page.show('Ruffle panic', { '判定': '核心重入类' });
  ok('show() 返回 true', shown === true, shown);
  ok('状态标记为已显示', page.state().shown === true, JSON.stringify(page.state()));

  const host = env.body.children.find(c => c.id === 'moleCrashPage');
  ok('浮层已挂到 body 上', !!host);
  ok('浮层 class 为 on', host && host.className === 'on', host && host.className);
  ok('样式只注入一次', env.head.children.filter(c => c.id === 'moleCrashCss').length === 1);

  const text = JSON.stringify(host, (k, v) => (k === 'parentNode' ? undefined : v));
  ok('页面上出现「引擎」与降级档位', text.indexOf('engine') >= 0 || text.indexOf('mcp-rows') >= 0);
  ok('报告正文已生成', typeof page.state().size === 'number' && page.state().size > 0);
}

console.log('=== 2) 分享按钮 → Java 桥（可转发到 QQ）===');
{
  const env = makeEnv();
  vm.runInContext(cpCode, env.sandbox);
  const page = env.sandbox.window.__moleCrashPage;
  page.show('Ruffle panic', {});
  const n0 = env.shares.length;
  ok('share() 返回 true（桥在）', page.share() === true);
  ok('调了一次 reportCrash', env.shares.length === n0 + 1, env.shares.length);
  const last = env.shares[env.shares.length - 1];
  ok('文件名是 mole-crash-*.txt', /^mole-crash-\d{8}-\d{6}\.txt$/.test(last.n), last.n);
  ok('正文是崩溃报告', last.t.indexOf('崩溃报告') >= 0, last.t.slice(0, 40));
}

console.log('=== 3) 没有桥时退化成复制 ===');
{
  const env = makeEnv({ androidBridge: false });
  vm.runInContext(cpCode, env.sandbox);
  const page = env.sandbox.window.__moleCrashPage;
  page.show('Ruffle panic', {});
  ok('share() 返回 false（无桥）', page.share() === false);
  ok('copy() 走 execCommand 成功', page.copy() === true);
}
{
  const env = makeEnv({ androidBridge: false, execCopy: false });
  vm.runInContext(cpCode, env.sandbox);
  const page = env.sandbox.window.__moleCrashPage;
  page.show('x', {});
  ok('复制被系统拒绝时返回 false', page.copy() === false);
}

console.log('=== 4) hide() ===');
{
  const env = makeEnv();
  vm.runInContext(cpCode, env.sandbox);
  const page = env.sandbox.window.__moleCrashPage;
  page.show('x', {});
  page.hide();
  ok('hide() 之后状态为未显示', page.state().shown === false);
}

/* ================================================================
 * 5) 关于弹窗
 * ================================================================ */
console.log('=== 5) 安卓走原生 AlertDialog ===');
{
  const env = makeEnv({});
  vm.runInContext(abCode, env.sandbox);
  const about = env.sandbox.window.__moleAbout;
  ok('__moleAbout 已导出', !!about);
  ok('三段文案齐全', about.lines.length === 3, about.lines.length);
  ok('第二段是红字', about.lines[1].red === true);
  ok('第一段不是红字', about.lines[0].red === false);
  ok('第二段写明「并非官方」', about.lines[1].t.indexOf('并非摩尔庄园官方项目') >= 0);

  const r = about.show(false);
  ok('返回 native', r === 'native', r);
  ok('调了 MoleBridge.showAbout(false)', env.aboutCalls.length === 1 && env.aboutCalls[0] === false,
    JSON.stringify(env.aboutCalls));
  ok('没有额外画页内弹窗', env.body.children.length === 0, env.body.children.length);

  about.show(true);
  ok('force=true 透传', env.aboutCalls[1] === true, JSON.stringify(env.aboutCalls));
}

console.log('=== 6) 纯血鸿蒙走 NativeBridge（ArkTS 原生弹窗）===');
{
  const env = makeEnv({
    ua: 'Mozilla/5.0 (Phone; OpenHarmony 5.0) AppleWebKit/537.36 ArkWeb/4.1.6.1 Mobile',
    harmonyBridge: true,
  });
  vm.runInContext(abCode, env.sandbox);
  const about = env.sandbox.window.__moleAbout;
  const r = about.show(false);
  ok('识别为 harmony 并返回 native', r === 'native', r);
  ok('调了 NativeBridge.showAbout(json)', env.harmonyCalls.length === 1);
  let payload = null;
  try { payload = JSON.parse(env.harmonyCalls[0]); } catch (e) {}
  ok('payload 是合法 JSON', !!payload, env.harmonyCalls[0]);
  ok('payload 带 title', payload && typeof payload.title === 'string' && payload.title.length > 0);
  ok('payload 三段文案', payload && payload.lines && payload.lines.length === 3);
  ok('payload 第二段 red=true', payload && payload.lines[1].red === true);
  ok('没有走安卓桥', env.aboutCalls.length === 0);
  ok('没有画页内弹窗', env.body.children.length === 0);
}

console.log('=== 7) 两桥都没有 → 页内兜底弹窗（红字段落仍在）===');
{
  const env = makeEnv({ androidBridge: false });
  vm.runInContext(abCode, env.sandbox);
  const about = env.sandbox.window.__moleAbout;
  const r = about.show(true);
  ok('返回 web', r === 'web', r);
  const mask = env.body.children.find(c => c.id === 'moleAboutMask');
  ok('页内弹窗已挂上', !!mask);
  const flat = JSON.stringify(mask, (k, v) => (k === 'parentNode' ? undefined : v));
  ok('带 red 样式', flat.indexOf('mab-p red') >= 0);
  ok('三句话都在', (flat.match(/mab-p/g) || []).length >= 3);
  ok('记住了已弹过（localStorage）', env.store.mole_about_v1 === '1');
}
{
  const env = makeEnv({ androidBridge: false });
  env.store.mole_about_v1 = '1';
  vm.runInContext(abCode, env.sandbox);
  const about = env.sandbox.window.__moleAbout;
  ok('已弹过则默认不再弹', about.show(false) === 'skip', about.show(false));
  ok('force 仍然能弹', about.show(true) === 'web');
}

console.log('');
if (fail) { console.log('FAILED  pass=' + pass + ' fail=' + fail); process.exit(1); }
console.log('ALL PASS  pass=' + pass + ' fail=' + fail);
