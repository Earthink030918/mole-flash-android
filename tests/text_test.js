/*
 * text_test.js —— 验证「文本度量记忆化」（1.1.4-beta 的第 0.5 段）
 * ==================================================================
 * 为什么单独测它：这一版唯一真正的性能修复就是它 —— 把 Ruffle 的
 * canvas 设备字体渲染器在算字距时对 measure_text 的 3N 次调用压成
 * 每串一次。它一旦写错，表现是「排版错位 / 字挤在一起」，比卡顿更难查，
 * 所以这里把缓存语义逐条钉死：
 *
 *   1) 同样的 (font, text) 只真算一次，第二次起返回**同一个** TextMetrics；
 *   2) font 进 key —— 换字号/字重不能串味；
 *   3) 长串（> 8 字符）原样透传，不进缓存（Ruffle 不会这样问）；
 *   4) 空串透传，不污染缓存；
 *   5) 缓存有上限，满了整批丢弃而不是无限涨；
 *   6) OffscreenCanvasRenderingContext2D 与 CanvasRenderingContext2D 都包；
 *   7) 命中率能从 __moleText.stats() 读出来（真机排查靠它）；
 *   8) 原函数抛异常时不吞不缓存。
 *
 * 跑：node tests/text_test.js [shell.html]
 */
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const shell = process.argv[2] || 'src/web/shell.html';
const src = fs.readFileSync(path.resolve(shell), 'utf8');

/* 切第 0.5 段：从 MAX_ENTRIES 的声明往前找到所在 IIFE 的开头，
   往后找到紧随 console.log 的 `})();`。切的是打进包里那一份。 */
const aMark = src.indexOf('var MAX_ENTRIES');
const aOpen = src.lastIndexOf('(function () {', aMark);
const bMark = src.indexOf("文本度量缓存已装载", aMark);
const bEnd = src.indexOf('})();', bMark);
if (aMark < 0 || aOpen < 0 || bMark < 0 || bEnd < 0) throw new Error('未取到第 0.5 段脚本');
const code = src.slice(aOpen, bEnd + '})();'.length);

let pass = 0, fail = 0;
function ok(name, cond, extra) {
  if (cond) { pass++; console.log('  PASS  ' + name); }
  else { fail++; console.log('  FAIL  ' + name + (extra !== undefined ? '  → ' + extra : '')); }
}

/* ---- 假的 2D 上下文：measureText 记账，便于数真实调用次数 ---- */
function makeCtxClass(tag) {
  const calls = { measure: 0 };
  class Ctx {
    constructor() { this._font = 'normal 64px SimSun'; this.calls = calls; }
    get font() { return this._font; }
    set font(v) { this._font = v; }
    measureText(text) {
      calls.measure++;
      const s = String(text);
      /* 返回一个"快照"对象，字段够 Ruffle 用的那几个 */
      return {
        width: s.length * 32,
        actualBoundingBoxLeft: 0,
        actualBoundingBoxRight: s.length * 32,
        actualBoundingBoxAscent: 48,
        actualBoundingBoxDescent: 6,
        fontBoundingBoxAscent: 52,
        fontBoundingBoxDescent: 8,
        _tag: tag, _text: s,
      };
    }
  }
  Ctx.calls = calls;
  return Ctx;
}

const OffCtx = makeCtxClass('off');
const CanCtx = makeCtxClass('can');

const logs = [];
const sandbox = {
  console: { log: (...a) => logs.push(a.join(' ')), warn: () => {}, error: () => {} },
  document: { fonts: { ready: { then() {} } } },
  window: {},
};
sandbox.window.OffscreenCanvasRenderingContext2D = OffCtx;
sandbox.window.CanvasRenderingContext2D = CanCtx;

vm.createContext(sandbox);
vm.runInContext(code, sandbox);

const T = sandbox.window.__moleText;
const ctx = new OffCtx();
const cctx = new CanCtx();

console.log('=== 1) 两个原型都包上了 ===');
ok('OffscreenCanvas 被接管（原型上有补丁标记）',
  OffCtx.prototype.__moleMeasurePatched === 1,
  OffCtx.prototype.__moleMeasurePatched);
ok('stats().patched 含 offscreen', String(T.stats().patched).indexOf('offscreen') >= 0, T.stats().patched);
ok('stats().patched 含 canvas', String(T.stats().patched).indexOf('canvas') >= 0, T.stats().patched);

console.log('=== 2) 同一 (font, text) 只真算一次 ===');
const m1 = ctx.measureText('好');
const m2 = ctx.measureText('好');
const m3 = ctx.measureText('好');
ok('真实调用只发生 1 次', OffCtx.calls.measure === 1, 'calls=' + OffCtx.calls.measure);
ok('返回的是同一个对象', m1 === m2 && m2 === m3);
ok('数值原样（width=32）', m1.width === 32, m1.width);
ok('stats 命中 2 次', T.stats().hits === 2, JSON.stringify(T.stats()));
ok('stats 未命中 1 次', T.stats().miss === 1, JSON.stringify(T.stats()));

console.log('=== 3) font 进 key，换字号不串味 ===');
ctx.font = 'normal 32px SimSun';
const small = ctx.measureText('好');
ok('换字号后重新测量', OffCtx.calls.measure === 2, 'calls=' + OffCtx.calls.measure);
ok('返回对象不同', small !== m1);
ctx.font = 'normal 64px SimSun';
ok('换回来直接命中', ctx.measureText('好') === m1 && OffCtx.calls.measure === 2);

console.log('=== 4) 长串 / 空串透传，不占缓存 ===');
const before = T.stats().entries;
const longStr = '这是一个超过八个字符的字符串';
const lm = ctx.measureText(longStr);
ok('长串结果正确', lm.width === longStr.length * 32, lm.width);
ok('长串不入缓存', T.stats().entries === before, T.stats().entries + ' vs ' + before);
const n0 = OffCtx.calls.measure;
ctx.measureText(longStr);
ok('长串每次都真算', OffCtx.calls.measure === n0 + 1);
const e0 = T.stats().entries;
ctx.measureText('');
ok('空串不入缓存', T.stats().entries === e0);
ok('空串计数进 pass', T.stats().pass >= 3, T.stats().pass);

console.log('=== 5) 普通 canvas 上下文同样生效 ===');
const c1 = cctx.measureText('嗨');
const c2 = cctx.measureText('嗨');
ok('同一对象', c1 === c2);
ok('只算一次', CanCtx.calls.measure === 1, CanCtx.calls.measure);
ok('互不干扰（tag）', c1._tag === 'can' && m1._tag === 'off');

console.log('=== 6) 上限行为：满了整批丢弃，不无限涨 ===');
T.clear();
let maxSeen = 0;
const big = new OffCtx();
for (let i = 0; i < 4200; i++) {
  big.measureText(String.fromCharCode(0x4e00 + i));
  const n = T.stats().entries;
  if (n > maxSeen) maxSeen = n;
}
ok('缓存条目从未超过 4096', maxSeen <= 4096, 'max=' + maxSeen);
ok('清空后能重新装（至少 1 条）', T.stats().entries >= 1, T.stats().entries);

console.log('=== 7) clear() 把计数也归零 ===');
T.clear();
ok('hits/miss/pass 归零', T.stats().hits === 0 && T.stats().miss === 0 && T.stats().pass === 0,
  JSON.stringify(T.stats()));

console.log('=== 8) 原函数抛异常时不吞不缓存 ===');
let boom = 0;
class ThrowCtx {
  constructor() { this._font = 'normal 64px X'; }
  get font() { return this._font; }
  measureText() { boom++; throw new Error('boom'); }
}
sandbox.window.CanvasRenderingContext2D = ThrowCtx;
vm.runInContext(code, sandbox);           // 重新装载，接管新原型
const tc = new ThrowCtx();
let caught = 0;
try { tc.measureText('甲'); } catch (e) { caught++; }
try { tc.measureText('甲'); } catch (e) { caught++; }
ok('异常原样抛出（两次都抛）', caught === 2, caught);
ok('异常结果没有被缓存（每次都真算）', boom === 2, boom);

console.log('');
if (fail) { console.log('FAILED  pass=' + pass + ' fail=' + fail); process.exit(1); }
console.log('ALL PASS  pass=' + pass + ' fail=' + fail);
