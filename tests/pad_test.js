/*
 * pad_test.js —— 验证 OmniPad 注入层的挂载与「触控板落点」几何
 * ==============================================================
 * 直接从 shell.html 切出最后一段（第 5 段）来跑，OmniPad 本体用桩替代，
 * 只测我们自己写的这部分：什么时候挂、挂在哪儿、转屏后会不会重算。
 *
 * 1.0.7 的判据变了：黑边按 **CSS px** 算（以前按物理像素估，导致每台真机
 * 都掉进右下角兜底）。所以这里既测「大视口」，也测真机 CSS 视口 800x360。
 */
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const shell = process.argv[2] || 'src/web/shell.html';
const src = fs.readFileSync(path.resolve(shell), 'utf8');

const blocks = [...src.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)].map(m => m[1]);
const code = blocks[blocks.length - 1];
if (code.indexOf('__molePad') < 0) throw new Error('未取到第 5 段脚本');

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra ? '  → ' + extra : '')); }
}

function fakeEl(id) {
  const el = {
    id: id || '', style: {}, className: '', textContent: '', children: [], parentNode: null,
    classList: { add() {}, remove() {}, contains() { return false; }, toggle() {} },
    appendChild(c) { c.parentNode = el; el.children.push(c); return c; },
    removeChild(c) { el.children = el.children.filter(x => x !== c); c.parentNode = null; return c; },
    setAttribute() {}, getAttribute() { return null; }, focus() {},
  };
  return el;
}

/* 造一个环境：给定视口与舞台视觉矩形 */
function makeEnv(opt) {
  const timers = [];
  const made = { targetZone: [], trackpad: [], padRoots: [], destroyed: 0 };
  const body = fakeEl('body');
  const wrap = fakeEl('wrap');
  let stageRect = opt.stage;
  let hasPlayer = opt.hasPlayer !== false;
  let hasCanvas = opt.hasCanvas !== false;

  wrap.getBoundingClientRect = () => ({
    left: stageRect.left, top: stageRect.top,
    right: stageRect.left + stageRect.width,
    bottom: stageRect.top + stageRect.height,
    width: stageRect.width, height: stageRect.height,
  });

  const doc = {
    body,
    getElementById: (id) => (id === 'wrap' ? wrap : null),
    querySelector: () => (hasPlayer ? {
      tagName: 'RUFFLE-PLAYER',
      instance: { paused: true },
      isPlaying: false,
      play() { made.played = (made.played || 0) + 1; },
      shadowRoot: hasCanvas ? { querySelector: (sel) => (sel === 'canvas' ? { tagName: 'CANVAS' } : null) } : null,
    } : null),
    createElement: () => { const e = fakeEl('div'); made.padRoots.push(e); return e; },
    /* 第 6 段（后台保活）会在 document 上挂 visibilitychange，这里给个空实现 */
    addEventListener() {},
    hidden: false,
  };

  const win = {
    innerWidth: opt.vw, innerHeight: opt.vh,
    OmniPad: opt.noOmni ? undefined : {
      TargetZone: function (container, o) {
        made.targetZone.push(o);
        this.el = fakeEl();
        this.updateConfig = (p) => { made.tzConfig = p; };
        this.markRectDirty = () => { made.tzDirty = (made.tzDirty || 0) + 1; };
        this.destroy = () => { made.destroyed++; };
      },
      VirtualTrackpad: function (container, o) {
        made.trackpad.push(o);
        this.el = fakeEl();
        this.updateConfig = (p) => { made.padConfig = p; };
        this.destroy = () => { made.destroyed++; };
      },
    },
  };

  const ctx = {
    window: win, document: doc,
    console: { log() {}, warn() {}, error() {} },
    setInterval: (fn, ms) => { const t = { fn, ms, cleared: false }; timers.push(t); return t; },
    clearInterval: (t) => { if (t) t.cleared = true; },
    JSON, Math, Number, String,
  };
  vm.createContext(ctx);
  vm.runInContext(code, ctx);

  return {
    win, made, timers,
    setStage(r) { stageRect = r; },
    setPlayer(v) { hasPlayer = v; },
    setCanvas(v) { hasCanvas = v; },
    tick(n = 1) { for (const t of [...timers]) if (!t.cleared) for (let i = 0; i < n; i++) t.fn(); },
  };
}

/* 由「舞台 contain 于视口」推出视觉矩形，和 __moleFit 的算法一致 */
function stageRectOf(vw, vh, mw = 960, mh = 560) {
  const f = Math.min(vw / mw, vh / mh);
  const w = mw * f, h = mh * f;
  return { left: (vw - w) / 2, top: (vh - h) / 2, width: w, height: h };
}

/* 从布局对象推回「距屏幕四边的距离」，用于检查有没有压到舞台 */
function box(lay) {
  return {
    top: parseInt(lay.top, 10), bottom: parseInt(lay.bottom, 10),
    left: parseInt(lay.left, 10), right: parseInt(lay.right, 10),
    w: parseInt(lay.width, 10), h: parseInt(lay.height, 10),
  };
}

/* 通用几何不变式：板子必须完全落在某一条黑边里，且离屏幕边缘 ≥ 20px */
function checkInsideBar(env, tag) {
  const lay = env.made.trackpad[env.made.trackpad.length - 1].layout;
  const b = box(lay);
  const vw = env.win.innerWidth, vh = env.win.innerHeight;
  const r = stageRectOf(vw, vh);
  const mR = vw - (r.left + r.width), mL = r.left;
  const mB = vh - (r.top + r.height), mT = r.top;
  const zone = env.win.__molePad.state().zone;

  ok(tag + ' 落点区域 = ' + zone, ['right', 'left', 'bottom', 'top'].indexOf(zone) >= 0, zone);

  if (zone === 'right') {
    ok(tag + ' 完全在右侧黑边内（' + b.right + '+' + b.w + ' ≤ ' + mR.toFixed(0) + '）',
       b.right + b.w <= mR + 0.5, JSON.stringify(lay));
    ok(tag + ' 离屏幕右缘 ≥20px（不碰系统返回手势区）', b.right >= 20, 'right=' + b.right);
  } else if (zone === 'left') {
    ok(tag + ' 完全在左侧黑边内', b.left + b.w <= mL + 0.5, JSON.stringify(lay));
    ok(tag + ' 离屏幕左缘 ≥20px', b.left >= 20, 'left=' + b.left);
  } else if (zone === 'bottom') {
    ok(tag + ' 完全在底部黑边内', b.bottom + b.h <= mB + 0.5, JSON.stringify(lay));
    ok(tag + ' 离屏幕下缘 ≥20px', b.bottom >= 20, 'bottom=' + b.bottom);
  } else if (zone === 'top') {
    ok(tag + ' 完全在顶部黑边内', b.top + b.h <= mT + 0.5, JSON.stringify(lay));
    ok(tag + ' 离屏幕上缘 ≥20px', b.top >= 20, 'top=' + b.top);
  }
  return { lay, b, zone };
}

console.log('=== 1) 等待「播放器 + 画布」，都就绪才挂载 ===');
{
  const env = makeEnv({ vw: 2400, vh: 1080, stage: stageRectOf(2400, 1080), hasPlayer: false, hasCanvas: false });
  env.tick(3);
  ok('播放器未出现时不挂载', env.made.trackpad.length === 0);
  env.setPlayer(true);
  env.tick(2);
  ok('有播放器但没画布时仍不挂载（影片还没起画面）', env.made.trackpad.length === 0);
  env.setCanvas(true);
  env.tick(1);
  ok('播放器 + 画布就绪后挂载成功', env.made.trackpad.length === 1);
  ok('靶区吸附舞台（stickySelector=#wrap）',
     env.made.targetZone[0] && env.made.targetZone[0].layout.stickySelector === '#wrap',
     JSON.stringify(env.made.targetZone[0] && env.made.targetZone[0].layout));
  ok('靶区开启虚拟光标', env.made.targetZone[0].cursorEnabled === true);
  ok('触控板绑定靶区', env.made.trackpad[0].targetStageId === '$stage');
  ok('触控板映射为鼠标左键',
     env.made.trackpad[0].mapping.type === 'mouse' && env.made.trackpad[0].mapping.button === 0);
  ok('灵敏度仍是 0.6（与 1.0.5 一致）', env.made.trackpad[0].sensitivity === 0.6,
     String(env.made.trackpad[0].sensitivity));
  const ids = env.win.__molePad.state();
  ok('__molePad.state() 报告已挂载', ids.mounted === true && ids.omni === true, JSON.stringify(ids));
}

console.log('=== 2) 真机 CSS 视口：必须进右黑边，不许再掉右下角 ===');
{
  /* 2800x1260、DPR≈3.5 的机器，WebView 里 window.innerWidth 只有 800 左右。
     1.0.6 用「≥104px」的阈值判黑边，这里算出 91px → 永远掉兜底。 */
  const env = makeEnv({ vw: 800, vh: 360, stage: stageRectOf(800, 360) });
  env.tick(1);
  const r = stageRectOf(800, 360);
  const mR = 800 - (r.left + r.width);
  ok('黑边确实只有 ~91px（1.0.6 的阈值就卡在这里）', mR > 85 && mR < 95, 'mR=' + mR.toFixed(1));
  ok('仍然挂上了触控板', env.made.trackpad.length === 1);
  const { b } = checkInsideBar(env, 'iQOO Neo9 800x360');
  ok('板宽 65px（黑边 91 - 系统手势 20 - 舞台缝 6）', b.w === 65, 'w=' + b.w);
  ok('高度 96px（不因窄黑边被压扁）', b.h === 96, 'h=' + b.h);
  ok('垂直居中', Math.abs((b.top + b.h / 2) - 180) <= 1, 'top=' + b.top);
  ok('不是角落兜底', env.win.__molePad.state().zone !== 'corner');
  ok('黑边里默认可见（看得见才找得到）',
     env.made.padRoots[0].className === '', JSON.stringify(env.made.padRoots[0].className));
}

console.log('=== 3) 大视口横屏：右黑边，宽度封顶 220 ===');
{
  for (const [vw, vh, name] of [[2400, 1080, '20:9'], [2800, 1260, 'iQOO Neo9 物理'], [2160, 1080, '18:9']]) {
    const env = makeEnv({ vw, vh, stage: stageRectOf(vw, vh) });
    env.tick(1);
    const { b, zone } = checkInsideBar(env, name);
    ok(name + ' 首选右侧', zone === 'right', zone);
    const r = stageRectOf(vw, vh);
    const expectW = Math.round(Math.min((vw - (r.left + r.width)) - 26, 220));
    ok(name + ' 宽度 = min(黑边-26, 220) = ' + expectW, b.w === expectW, 'w=' + b.w);
    ok(name + ' 高宽比接近 1:1（横竖拖动速度一致）',
       b.h / b.w > 0.9 && b.h / b.w < 1.15, 'h/w=' + (b.h / b.w).toFixed(3));
    ok(name + ' 标签齐全', env.made.trackpad[0].label === '拖动 · 轻点', env.made.trackpad[0].label);
  }
}

console.log('=== 4) 平板 4:3：黑边在上下，改落底部 ===');
{
  for (const [vw, vh, name] of [[1024, 768, '1024x768'], [2048, 1536, '2048x1536']]) {
    const env = makeEnv({ vw, vh, stage: stageRectOf(vw, vh) });
    env.tick(1);
    const { b, zone } = checkInsideBar(env, name);
    ok(name + ' 底部横条', zone === 'bottom', zone);
    ok(name + ' 水平居中', Math.abs((b.left + b.w / 2) - vw / 2) <= 1,
       'left=' + b.left + ' w=' + b.w);
  }
}

console.log('=== 5) 满幅舞台（四边都没有黑边）：不挂触控板，绝不压画面 ===');
{
  for (const [vw, vh, name] of [[960, 560, '正好铺满'], [640, 360, '16:9 只剩 11px']]) {
    const env = makeEnv({ vw, vh, stage: stageRectOf(vw, vh) });
    env.tick(2);
    const st = env.win.__molePad.state();
    ok(name + ' 不创建触控板', env.made.trackpad.length === 0);
    ok(name + ' 靶区照建（点哪走哪）', env.made.targetZone.length === 1);
    ok(name + ' state().zone 为空', st.zone === '', JSON.stringify(st));
    ok(name + ' state().mounted 仍为 true（图层在，只是没板子）', st.mounted === true);
    ok(name + ' 图层整体不可见', env.made.padRoots[0].className === 'pad-invisible');
  }
}

console.log('=== 6) __molePad.corner(true)：满幅机器上的显式兜底 ===');
{
  const env = makeEnv({ vw: 640, vh: 360, stage: stageRectOf(640, 360) });
  env.tick(1);
  ok('默认没有板子', env.made.trackpad.length === 0);

  ok('corner(true) 返回 true', env.win.__molePad.corner(true) === true);
  const lay = env.made.trackpad[0].layout;
  ok('按兜底尺寸建板 168x112', lay.width === '168px' && lay.height === '112px', JSON.stringify(lay));
  ok('zone=corner', env.win.__molePad.state().zone === 'corner');
  ok('压画面时必须隐藏（视觉不挡，交互仍在）',
     env.made.padRoots[0].className === 'pad-invisible');

  ok('corner(false) 返回 false', env.win.__molePad.corner(false) === false);
  ok('板子被拆掉', env.made.destroyed >= 1 && env.win.__molePad.state().trackpad === false,
     'destroyed=' + env.made.destroyed);
}

console.log('=== 7) 转屏：右黑边 ←→ 满幅，板子跟着建/拆 ===');
{
  const env = makeEnv({ vw: 2400, vh: 1080, stage: stageRectOf(2400, 1080) });
  env.tick(1);
  ok('起始有板子', env.made.trackpad.length === 1);
  const reflowTimer = env.timers.find(t => t.ms === 1000);
  ok('挂载后启动了 1s 的重新贴边定时器', !!reflowTimer);

  env.setStage(stageRectOf(640, 360));
  env.win.innerWidth = 640; env.win.innerHeight = 360;
  reflowTimer.fn();
  ok('转成满幅后板子被拆（不压画面）',
     env.win.__molePad.state().trackpad === false && env.made.destroyed >= 1);

  env.setStage(stageRectOf(2400, 1080));
  env.win.innerWidth = 2400; env.win.innerHeight = 1080;
  reflowTimer.fn();
  ok('转回带黑边后自动重建', env.made.trackpad.length === 2,
     'n=' + env.made.trackpad.length);
  checkInsideBar(env, '转回来');
}

console.log('=== 8) 画幅变化后重新定位（不重复 updateConfig） ===');
{
  const env = makeEnv({ vw: 2400, vh: 1080, stage: stageRectOf(2400, 1080) });
  env.tick(1);
  const reflowTimer = env.timers.find(t => t.ms === 1000);
  const before = JSON.stringify(env.made.trackpad[0].layout);

  env.setStage(stageRectOf(2400, 1080, 960, 640));      // 影片分辨率校正后画幅变化
  reflowTimer.fn();
  ok('画幅变化后调了 updateConfig', !!env.made.padConfig);
  ok('落点跟着变', JSON.stringify(env.made.padConfig.layout) !== before,
     before + ' → ' + JSON.stringify(env.made.padConfig.layout));
  ok('label 一并带过去', 'label' in env.made.padConfig, JSON.stringify(Object.keys(env.made.padConfig)));

  const n = env.made.tzDirty || 0;
  ok('同时让靶区重算矩形', n >= 1, 'dirty=' + n);

  env.made.padConfig = null;
  reflowTimer.fn();
  ok('布局没变时不重复 updateConfig', env.made.padConfig === null);
}

console.log('=== 9) 后台恢复钩子 ===');
{
  const env = makeEnv({ vw: 2400, vh: 1080, stage: stageRectOf(2400, 1080) });
  env.tick(1);
  ok('__moleAfterResume 已定义', typeof env.win.__moleAfterResume === 'function');
  env.win.__moleAfterResume(120000);
  ok('暂停态会被重新 play', env.made.played === 1, 'played=' + env.made.played);
}

console.log('=== 10) 退路：__molePad.off() 拆图层 ===');
{
  const env = makeEnv({ vw: 2400, vh: 1080, stage: stageRectOf(2400, 1080) });
  env.tick(1);
  const s1 = env.win.__molePad.state();
  env.win.__molePad.off();
  const s2 = env.win.__molePad.state();
  ok('off 后 mounted=false', s1.mounted === true && s2.mounted === false, JSON.stringify([s1, s2]));
  ok('#pad 已从 body 摘掉', env.made.padRoots[0].parentNode === null);
}

console.log('=== 11) OmniPad 缺席时安全降级 ===');
{
  const env2 = makeEnv({ vw: 2400, vh: 1080, stage: stageRectOf(2400, 1080), noOmni: true });
  let threw = false;
  try { env2.tick(2); } catch (e) { threw = true; }
  ok('没有 OmniPad 时不抛异常', threw === false);
  ok('没有 OmniPad 时不建图层', env2.made.trackpad.length === 0 && env2.made.targetZone.length === 0);
  ok('但仍提供 __moleAfterResume', typeof env2.win.__moleAfterResume === 'function');
  ok('状态里 omni=false', env2.win.__molePad.state().omni === false);
}

console.log('=== 12) 视觉开关：只碰外观，不碰命中测试 ===');
{
  const env = makeEnv({ vw: 800, vh: 360, stage: stageRectOf(800, 360) });
  env.tick(1);
  const root = env.made.padRoots[0];
  ok('黑边里默认可见', root.className === '');
  ok('state().trackpadVisible === true', env.win.__molePad.state().trackpadVisible === true);

  ok('trackpad("off") 返回 true', env.win.__molePad.trackpad('off') === true);
  ok('已隐藏', root.className === 'pad-invisible');
  ok('隐藏后靶区仍在', env.made.targetZone.length === 1);
  ok('隐藏后触控板仍在（只是看不见）', env.win.__molePad.state().trackpad === true);
  ok('隐藏不改落点', env.win.__molePad.state().zone === 'right');

  ok('trackpad("auto") 返回 false', env.win.__molePad.trackpad('auto') === false);
  ok('恢复可见', root.className === '');
}

console.log('\n' + (fail === 0 ? 'ALL PASS' : 'FAILED') + '  pass=' + pass + ' fail=' + fail);
process.exit(fail === 0 ? 0 : 1);
