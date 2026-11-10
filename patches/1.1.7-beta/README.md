# 1.1.7-beta —— 输入法焦点守卫（点输入框键盘不再闪退）

基线 1.1.6-beta（versionCode 20，已换新编译的三份 ruffle 引擎）→
本版 **1.1.7-beta**（versionCode 21）。
只改 `assets/ruffle/shell.html`，**纯插入 24 行**，其余 2152 行逐字节未动。

产物：`mole-1.1.7-beta.apk`，10,384,772 B，
SHA-256 `ae3f372c3e6e518be1754ce7f621f03fddfd224e81a72ea6d0e14f4400bcfff7`，
证书 `974ea1b9…0093`（同 v1.1.0，可覆盖安装）。

---

## 来源与一个必须说明的判断

群友给了一份 `shell.html`，说是"输入法应用相关"的改动。实测这份文件是
**1.0.7 基线 + 24 行新增**：

```
$ diff -u patches/1.0.7/shell.html <群友文件>
@@ -1025,6 +1025,30 @@       ← 唯一一处，+24 行
```

也就是说它**不含** 1.1.1 ~ 1.1.5 这五批修复。若按字面整体覆盖，会同时丢掉：

| 丢失项 | 现象 |
| --- | --- |
| 1.1.1-beta 像素预算 `budgetNow()` | DPR 回到固定 1.294，画面发糊（就是群里骂过那次） |
| 1.1.1-beta 平板触控兜底 `edgeFallback()` | 小米平板 5 Pro 可能又没触控板 |
| 1.1.2-beta 预算下限修正 | 手机端 DPR 被压到 0.818 |
| 1.1.3-beta 软键盘 `openVirtualKeyboard` 补丁 | 点输入框键盘闪退复发 |
| 1.1.4-beta 文本度量记忆化 | 好友列表 / 聊天框卡顿复发 |
| 1.1.5-beta 渲染后端降级阶梯 | 华为 / 鸿蒙红屏无兜底 |

与"不要动像素密度"这条要求直接冲突。因此**只取那 24 行**，
原样并入 1.1.6 的 OmniPad 挂载点。群友那 24 行一个字符都没改
（含注释、空格、`// A` / `// B` / `// C` 标记）。

## 改动位置

`shell.html` 第 5.4 段 `mount()`，`new OP.TargetZone(...)` 之后、
`log('OmniPad 已挂载：舞台靶区')` 之前。

```js
    stage = new OP.TargetZone(padRoot, {
      widgetId: '$stage',
      cursorEnabled: true,
      layout: { stickySelector: '#wrap' }
    });
+   /* 输入法守卫：正在输入时不让焦点被抢回画布…… */
+   var _sh = playerEl() && playerEl().shadowRoot, _cv = canvasEl();
+   ...
    log('OmniPad 已挂载：舞台靶区');
```

## 它解决什么

三段，互相配套：

- **A** 包一层 `canvas.focus`：`shadow.activeElement` 已经是 `#virtual-keyboard`
  就直接返回。OmniPad 的 `ensureFocus()` 最终就是调 `canvas.focus`，
  拦在这里等于把"抢焦点"这条路堵死。
- **B** `pointerdown` 记时间戳：用来区分"这一下是手指点的"和"浏览器自己触发的
  focusout"，后者不该抢回。
- **C** 监听 `shadow` 的 `focusout`：`#virtual-keyboard` 失焦、且不是转移到
  `#container` 时，下一拍（16ms）抢回。用 `_fixed` 保证一次点击最多抢一次，
  否则打字时手指微动会被 OmniPad 反复 `ensureFocus` 触发，最多 25 轮抢焦点，
  表现就是"打字卡"。

`if (_sh && _cv && _sh.addEventListener)` 是给测试桩留的防御：
`tests/pad_test.js` 的 shadow 桩只有 `querySelector`，没有 `addEventListener`。

## 没动的东西

像素预算（`budgetNow` / `MAXPIX` / `DENSITY` / `__moleDprCap` 全段哈希不变）、
画幅（`#wrap` 与 transform）、画质（`quality`）、帧率（`frameRate: 24` + rAF 泵）、
节流器、时间轴钳制、Ruffle 配置、文本度量缓存、后端降级阶梯、
`mole_boot.js`、任何 smali、服务器地址。

逐段哈希核对（改动前 vs 改动后）：

```
相同  像素预算段        3b3b894fc52c64a1 / 3b3b894fc52c64a1
相同  DPR getter       f64a375e1a5ede71 / f64a375e1a5ede71
相同  Ruffle 配置       d11472bf1d266275 / d11472bf1d266275
相同  时间轴钳制         eccf595b55157fef / eccf595b55157fef
```

整体校验：把这 24 行摘掉后，文件与改动前**逐行完全相同**。

## 验证

- 内联脚本语法：3 个块，0 错误
- `clock_test` 34/34、`bg_test` 54/54、`text_test` 24/24、`panic_test` 34/34 全绿
- `pad_test` 79/17 —— 改动前 79/17、改动后 79/17、1.1.5-beta 也是 79/17，
  1.1.1-beta 改几何后就没更新过的既有红，与本次无关
- 包内 `assets/ruffle/shell.html` 191,749 B，SHA-256 与工作副本一致（`2f58b56a…`），
  纯 LF（CR 计数 0）
- `aapt dump badging`：`versionCode='21' versionName='1.1.7-beta'`、
  `targetSdkVersion:'31'`、`minSdkVersion:'21'`
- `apksigner verify`：v1 / v2 / v3 三方案全 true，证书 `974ea1b9…0093`

## 真机验证要点

1. 点输入框一次 → 键盘应稳定弹出，不再"弹一下就缩回"
2. 中文输入法打字 → 汉字正常上屏，不出现重复/长串
3. 打字时手指在屏幕上移动 → 不出现卡顿（`_fixed` 防循环生效）
4. 关掉键盘后再点一次 → 仍能正常弹出（守卫不会把 focus 永久锁住）

日志：`adb logcat -s MoleShell | grep "OmniPad 已挂载"` 应能看到挂载行。
