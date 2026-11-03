# 1.1.4-beta —— 好友列表 / 好友聊天框卡顿

基线 1.1.3-beta（versionCode 17）→ 本版 **1.1.4-beta**（versionCode 18）。
只改 `assets/ruffle/shell.html`，Java 壳层、画幅、画质、帧率、节流器、
输入法配置**一律未动**。

产物：`mole-1.1.4-beta.apk`，10,327,428 B，
SHA-256 `b1fa2024c710fca9f5bbe71373b6b5426931bb2b52075cf8e868f10faad0a16e`。

---

## 现象

群友反馈：打开好友列表、以及随后进入好友聊天框时卡顿明显；
地图里跑图、点 NPC 不卡。**只有文本密集的界面卡。**

## 定位（不是猜的，对着 Ruffle 源码逐行核对）

我们为了显示中文，从 1.1.0 起把 `deviceFontRenderer` 设成了 `'canvas'`
（`embedded` 只有 Noto Sans，无 CJK 字形，中文会整段消失）。
这条路径的实现是 `web/src/ui/canvas_font_renderer.rs`，两个成本点：

1. **`fn has_kerning_info(&self) -> bool { true }`**
   它声称自己有字距信息，于是 core 在**每一行文本布局**时对**每一对相邻字符**
   调一次 `calculate_kerning()`：

   ```rust
   let left_width  = self.calculate_width(&left.to_string())?;   // measure_text
   let right_width = self.calculate_width(&right.to_string())?;  // measure_text
   let both_width  = self.calculate_width(&format!("{left}{right}"))?; // measure_text
   ```

   → 1 个字符对 = **3 次 `measure_text`**，每次都要过 wasm → JS 边界并走
   浏览器整条字体 shaping 栈。好友列表一屏 30 个昵称、聊天框一屏 20 行 × 20 字
   ≈ 600 个字符对 ≈ **1800 次 `measure_text`**；而聊天框每来一条新消息、
   光标闪一次、列表滚一格都会重排整行 —— 于是这个量级**持续**发生。
   地图那边几乎没有成片的动态文本，所以不卡。

2. **`render_glyph_internal()`** 每渲染一个新字形都要
   `clear_rect` + `fill_text` + **`get_image_data`（同步 GPU 回读）** + 图集上传。
   打开好友列表＝一次冒出几百个从没出现过的汉字，是一波几百次回读。
   这一条无法在壳层消除（要拿像素就只能回读），第 1 条可以。

另外 `RuffleHandle::tick()` **每帧读一次 `window.devicePixelRatio`**
（源码注释 `// Changes via user zooming.`），而我们的 getter 每次调用都
`getElementById('wrap') + offsetWidth/offsetHeight` —— 两次强制同步布局；
更要命的是两次 tick 之间只要算出的值差一个 ulp，Ruffle 就走
`canvas.set_width/set_height + set_viewport_dimensions` 分支，
把渲染目标和全部位图纹理重建一遍。

## 改动（6 处，全部在壳层）

1. **文本度量记忆化（第 0.5 段，本版主修）**
   包装 `OffscreenCanvasRenderingContext2D.prototype.measureText`
   （同时包 `CanvasRenderingContext2D`），同样的 `(font, text)` 只真算一次，
   之后直接返回第一次的 `TextMetrics` 对象。key 里带 `ctx.font`；只缓存
   ≤ 8 字符的短串（Ruffle 只用单字/双字算宽度与字距）；上限 4096 条，
   满了整批丢弃；`document.fonts.ready` 后清一次兜底。
   返回值一个字段都没改 → **排版与原来逐像素一致**，这不是"改画质"，
   只是把重复计算删掉。`__moleText.stats()` 可读命中率。

2. **`devicePixelRatio` 记忆化（第 0.2 段）**
   返回值恒定 → 消除每帧两次强制布局，且 Ruffle 的"canvas 尺寸/DPR 变化 →
   重建渲染目标"分支在正常游玩期间永不触发。失效点只有 resize（走
   `__moleFit` → `refreshShownArea`）、预算变更、`__moleDprRefresh()`。

3. **console 管道丢弃路径零成本（第 1 段）**
   旧实现无论哪一级都先把所有参数 `String()` 拼成 `rawAll` 再判级别；
   现在先判级别，丢弃的 log/info/debug 直接 return（只多一次 `typeof`）。
   `[MoleShell]` 白名单改判首字符（`charCodeAt(0) === 91`）。

4. **触控板轮询先比视口签名（第 5 段）**
   `setInterval(applyLayout, 1000)` → `pollLayout`：先用
   `innerWidth/innerHeight/visualViewport.scale` 拼签名（纯数值，不触发布局），
   没变就直接返回。原来每秒一次 `getBoundingClientRect()`（强制布局）
   + 无条件重写 `#pad` 的 className。

5. **软键盘补挂不再每 800ms 重写样式（第 4.5 段）**
   已挂好且元素存活时立刻返回；`styleKb()` 的 20 条 `!important` 只在
   换元素时写一次（`openVirtualKeyboard` 里加了 `__moleKbStyled` 标记）。

6. **长帧探针（第 7 段，默认关闭）**
   `__molePerf.on()` 用**原生** rAF 采样主线程真实帧间隔（泵把
   `requestAnimationFrame` 限到了 24fps，量不到长帧），>120ms 记一行
   logcat，带文本缓存命中率 / 时间轴钳制状态 / DPR / canvas 尺寸。
   不开就一个 rAF 都不注册，零成本。

## 验证

- `node tests/text_test.js patches/1.1.4-beta/shell.html` → **ALL PASS 24/24**
  （新增；`clock_test` 34/34、`bg_test` 54/54 全绿；
  `pad_test` 79/17 是 1.1.1-beta 改几何后就没更新的既有红，与本次无关，
  对 1.1.3-beta 跑同样是 79/17）
- 包内 `assets/ruffle/shell.html` 与工作副本 `cmp` 一致（186,871 B，纯 LF）
- `aapt dump badging`：`versionCode='18' versionName='1.1.4-beta'`、
  `targetSdkVersion:'31'`、`minSdkVersion:'21'`（与上一版完全一致）
- `apksigner verify`：证书 `974ea1b9…0093`，与 v1.1.0～1.1.3-beta 同一把，
  可覆盖安装

## 真机要看的三行

```
adb logcat -s MoleShell | grep -E "文本度量缓存|长帧|帧统计"
```

1. `文本度量缓存已装载（offscreen+canvas，上限 4096 条）` —— 补丁挂上了；
2. 进出好友列表/聊天框后 `__moleText.stats()` 的 `hitRate` 应 > 0.6
   （可在控制台或 HUD 里读）；
3. 如果仍卡，`__molePerf.on()` 复现一次，看长帧那行里 `canvas` 尺寸
   与 `text.hitRate` —— 若 hitRate 已高而长帧照旧，剩下的就是
   `getImageData` 回读（第 2 条），只能靠内嵌真名字体走 `embedded` 路径解决，
   那属于改字体渲染配置，需要单独批准。
