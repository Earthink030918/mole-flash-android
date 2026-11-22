# 排障手册

先开日志，再看症状表。

```bash
adb logcat -c && adb logcat -s MoleShell:V MoleSocketBridge:V
```

页面侧 `console.*` 已被 `shell.html` 接管，转发成 `MoleShell` 的 `[js] …` 行；HUD 默认关闭
（`DIAG_HUD = false`），需要屏上日志时把 `MainActivity.DIAG_HUD` 拨到 `true` 重新编译。

---

## 症状 → 原因 → 处置

### 黑屏，日志停在 `致命：window.RufflePlayer 未定义 —— __mole_ruffle__.js 没下发成功`

`assets/ruffle/ruffle.js` 缺失，或 `shouldInterceptRequest` 没命中第 3 条路由。
先 `logs` 里找 `assets 缺失：ruffle/ruffle.js`。检查 assets 目录结构与文件名大小写。

### 黑屏，日志有 `wasm 下发失败：… —— Ruffle 请求的 wasm 名与 assets 不匹配`

换了 Ruffle 版本但只替换了 `ruffle.js`。三个文件必须同版本：`ruffle-<hash>.js`、
`ruffle_web_bg.<hash>.wasm.gz`、`ruffle_web-wasm_mvp_bg.<hash>.wasm.gz`。名称不匹配直接 404。

### 黑屏，日志有 `致命：#stage 不存在`

`shell.html` 的容器 id 被改过（代码里找 `id="wrap"`）。`mole_boot.js` 里 `stage()` 取的是 `#wrap`，两处必须一致。

### 黑屏，日志有 `polyfill 25 次(5s)未接管` 后跟 `→ polyfill 未接管，改走 createPlayer`

Ruffle 的 polyfill 没运行（通常是 `ruffle.js` 加载到一半报错）。看更早的 `[js]` 行有没有
`Ruffle 加载失败` 或 CSP 报错。兜底路径 `viaApi()` 会直接 `createPlayer()`，若它也失败说明是 wasm 没起来。

### 黑屏，日志有 `主页面加载失败：… code=… desc=…`

壳页本身没返回。这条只在**主框架**失败时打，说明拦截器第 1 条路由没命中 —— 检查 URL
是否严格以 `/__mole_shell__` 结尾（带 query 就会漏）。代码里是 `endsWith`。

### 画面出来但角色不动 / 一进地图就断线

Socket 桥没通。查 `MoleSocketBridge` 的日志：

- `上行结束：…` / `下行结束：…` → 真服务器断开，多半是目标地址过期
- 有 `补录服务器端口：x.***.***.***:N` 但之后仍不通 → 端口对了但主机不对，把该条从
  `SharedPreferences` 的 `socket_targets_v2` 里删掉重试
- 完全没有 `Missing WebSocket proxy` 告警 → `__SOCKET_PROXY__` 没注入成功，看 `socketProxy 目标已就绪，共 N 条`
  的 N 是否为 0（为 0 说明种子全部解码失败或端口表为空）

重置学习结果：

```bash
adb shell run-as com.taomee.mole rm -f /data/data/com.taomee.mole/shared_prefs/mole_shell.xml
adb shell am force-stop com.taomee.mole
```

### 一闪白光 / 偶发闪黑一帧

GPU 上下文丢失后重建，合成器按透明画布默认底色合成了一帧。`shell.html` 已给 `#wrap canvas`
铺黑底缓解；若频繁出现，说明显存在临界点，往下调预算（见下一条）。

### 玩一会儿崩溃，日志有 `页面报告 GPU 上下文异常：lost` 然后 `dead`

Adreno 显存池耗尽。内核直接 SIGTRAP 杀 RenderThread，Java 层拦不到，只能提前降载。处置顺序：

1. 先确认看护在工作：有没有 `负载档位 → N（预算 N px）` 或降采样的 `[js] 降载 budget=…` 日志
2. 缩小预算：把 `PIXEL_BUDGETS` 整体乘 0.7，或把 `GPU_SOFT_MB` 从 400 调到 350
3. 实在压不住就把 `preferredRenderer()` 从 `wgpu-webgl` 换成 `canvas`（CPU 软渲染，画面糙但不会 OOM）

1.2.4-beta 起这条链上多了两个可用的钩子：上下文丢失 **2.5s** 未恢复时会先落一份崩溃报告
（`crash/mole-crash-*.txt`，含当时的画布尺寸与预算），再上报 `dead`。报告比对相邻两份的
`像素预算` 字段，就能判断「是没降档」还是「降了还不够」。

### 崩溃以后停在一张「呜……好像卡住了」的页面上

这是 1.2.6-beta 起**故意**的。以前 panic 之后 `MoleBridge.onPanic()` 只释放纹理
（`releaseTextures(true)`，带 15s 冷却，**没有任何 reload**），真正让页面回来的是
`mole_boot.js` 里那个 6 秒兜底 `location.reload()` —— 所以「红屏挂 6 秒」不是设计，
是没人接手的空档。现在这段空档由崩溃页接手：

- 点右上角 `↗ 分享日志` → 系统分享面板 → 选 QQ 发群；
- 点 `重新进入` → `location.reload()`，用的是**已经降好的**后端档位；
- 不想管它也行，txt 已经静默落在 `Android/data/com.taomee.mole/files/crash/`。

页面上 `崩溃次数` 读 `sessionStorage.mole_panic_n`（随本次启动重置），
与后端档位用的 `localStorage.mole_renderer_tier` 刻意分开计。

### 右上角那个「日志」按钮是干嘛的 / 怎么关掉

1.2.7-beta 起，横屏右上角有一枚 52×34 的半透明按钮。点开是**同一张**崩溃页，
但它叫「运行日志」，而且**能返回**：

- 日志每 1 秒刷新一次（摘要 + 最近 40 行），点 `↗ 分享日志` 会立刻**冻结**再拉起
  系统分享面板 —— 发出去的就是你眼前那一份，文件名 `mole-log-*.txt`；
- `← 返回游戏` 或系统返回键退回去。这一路**不 reload、不降档、不碰 OmniPad**，
  下面的游戏一直在跑，回去还是原来那一帧；
- 页面开着的时候如果真崩了，它会自己切回崩溃终局（主按钮变回「重新进入」）。

想彻底不要它：控制台 `__moleLogBtn.hide()` 只藏本次；改 CSS 也行
（`#moleLogBtn{display:none}`）。按钮点下去毫无反应则是 `__moleCrashPage.showLive()`
返回了 false（`document.body` 还没建好 / 浮层被拆），此时会退化成「直接生成一份
报告并拉起分享」并打一行 `日志页不可用，降级为直接分享`。

### 连「呜……好像卡住了」都不出现，只有红屏

说明覆盖层没建起来，`mole_boot.js` 会写一行
`!! 崩溃页建不起来，退回自动分享 + 重载` 然后走老路。三种可能：

1. panic 发生在 `document.body` 生成之前（启动期就炸）—— 这时确实没 DOM 可用；
2. `shell.html` 的第 10 段没进包（`dexdump` 查不到没用，得 `unzip` 出
   `assets/ruffle/shell.html` 搜 `__moleCrashPage`）；
3. 页面被上一次的 `location.reload()` 打断在半路。

### `页面报告 Ruffle panic → 强制清空重载`，反复出现

wgpu 在特定驱动上过不了 `create_render_pipeline` 的 VERTEX shader 校验。这是 Ruffle + 驱动的组合问题，
换 Ruffle 版本或换后端，改代码无解。日志里若出现 `主动释放已达 10 次上限`，说明在死循环重载，
此时应停手排查而不是继续加自动重载次数。

1.2.4-beta 起多一行判据：`后端档位连续崩溃 N`。同一后端档位第二次崩即自动降档
（不再依赖 panic 文案命中关键词——ColorOS 上文案常常只有 `Something went wrong`）。
若报告里 `判定` 一栏一直是「证据驱动·后端不可用」且档位已经到 `canvas` 还在崩，
说明不是后端问题，往下看 `JS 运行时错误` 段与 `panic 正文`。

### panic 正文是 `arena already borrowed`，同一秒还有 `Maximum call stack size exceeded`

1.2.5-beta 之前这条会被判成「非渲染类」，后端不动，重载之后照撞。现在看报告的 `判定`：

```
判定: 核心重入类（borrow 重入，wgpu 回调整疑）   ← 下次启动会换 webgl
判定: 核心重入类（非 wgpu 后端，不动）          ← 已经不在 wgpu 上了，没有可降的
判定: 内容/内存类（换后端无用）
```

这是 Ruffle 的 `enter_arena_mut()` 在 arena 已被借用时又被人调了一次 —— **重入**。
wasm 里的栈溢出会直接从 JS 侧抛出，Rust 的借用守卫来不及析构，紧跟的那次调用就撞上「已借用」；
所以 `Maximum call stack`（`window.onerror` 里）和这条 panic 通常同秒出现。

判定只认 15 秒内的 JS 错误（`__moleLastErrAt`），80 秒前路过的一条无关 RangeError 不会算到这次头上。
如果想确认触发源，看报告里 `[最近日志]` 段 panic 前 20 行在做什么：方向键 / 触控板 / 切后台都会留下痕迹。

### 方向键按住时角色一直走，松开也不停 / 某个方向键从此失灵

1.2.5-beta 修的。根因是面板收起后 `pointer-events:none`，收不到 `pointerup`，KEYUP 发不出去，
OmniPad 的 `isPressed` 卡在 true —— 这个方向在游戏里永久按下，而且 `press()` 会被 `isPressed` 挡掉，
表现为「这个键没反应」。现在收起 / 拆浮钮 / 切后台 / 失焦都会 `DPadCore.reset()` + 补发 4 个 KEYUP。

如果**升级后仍然复现**，说明还有第三条路径没覆盖（比如别的地方把面板藏了），临时处置：

```js
__moleDpad.off()        // 拆掉浮钮，彻底回到原生触控
__moleDpad.state()      // { mounted, open, engine }
```

1.2.6-beta 起这两个数是**同源**的（都读 `__moleBudgetInfo()`）。如果你在 1.2.5 及以前的日志里
看到 `budget=460000（生效 1210000）`，那是启动日志里的旧表达式没跟着软地板一起改，
**不是降档失效** —— 同一份报告的「像素预算」栏才是真值。

### 从来没弹出过崩溃报告 / 找不到 txt

三处触发都要求 Ruffle 面板或 canvas 已经存在，装完就崩在启动阶段的看不到弹窗。依次查：

1. `adb shell ls /sdcard/Android/data/com.taomee.mole/files/crash/` —— 文件在不在。
   在，说明只是分享面板没弹（`createChooser` 抛了 `ActivityNotFoundException`，
   日志有 `分享崩溃日志失败`），手动把文件发出去即可；
2. 节流：自动分享 10s 一次、每会话 2 次，超了只写日志。日志有
   `本次会话已自动分享 2 次，后续只记录不弹窗` 就是撞上限了；
3. 手动触发：`chrome://inspect` 连上后在 Console 里 `__moleShareCrash('随手试试')`，
   能弹说明通道正常，问题在触发点；弹不出说明 `MoleBridge.reportCrash` 没注入（检查 dex 里
   有没有 `MainActivity$JsBridge;->reportCrash`）。

### 左下角没有方向键按钮 / 点了没反应

- 按钮只在播放器元素出现后 500ms 内挂载，最多等 30s；超时日志有一条
  `方向键浮钮放弃：60 次（30s）内没等到播放器元素`——那是黑屏问题，先修黑屏；
- `__moleDpad.state()` 看 `engine`：`omnipad` 正常，`native` 是兜底模式（OmniPad 没挂上，
  或 `#pad` 还没建起来）。兜底模式功能不减，只是皮肤朴素；
- 按键无反应但状态正常：游戏内那个小游戏可能不吃 `Arrow*`（有的吃 `WASD` 或直接吃鼠标）。
  先用 `__moleDpad.off()` 关掉，改用触控板点；
- 十字键挡住了游戏面板：`__moleDpad.toggle(false)` 收起。位置写死在左下角 `10px`，
  本版不做拖动。

### 文字全是方块 / 中文不显示

`fontResponse()` 找不到系统 CJK 字体。`CJK_FONT_CANDIDATES` 只列了 `NotoSansCJK-Regular.ttc` 和
`NotoSansCJKsc-Regular.otf`，部分 ROM 用的是 `DroidSansFallback.ttf` 之类。把实际路径加进候选数组：

```bash
adb shell ls /system/fonts | grep -iE "cjk|fallback|noto"
```

### 小游戏「开了倍速」

帧率节流器没生效。它必须挂在 `ruffle.js` **之前**（`shell.html` 第 0 节），且解析出的
官方帧率是 24。若某个子 SWF 本身是 30/60 fps，需要在节流器里按 SWF 头部帧率动态调整，
硬编码 24 会把这部分子游戏拖慢。

### 画面被放大、UI 被裁切

舞台按 960×560 原始坐标 1:1 贴图，而视口更小。正确做法是让播放器元素严格等于影片原生尺寸，
再用 CSS `transform: scale()` 整体缩放（`shell.html` 第 0 节已实现）。若改回「撑满视口 + `showAll`」，
AS3 一旦把 `stage.scaleMode` 改成 `NO_SCALE` 就会复现。

### `磁盘缓存初始化失败，退化为直连`

`getCacheDir()` 不可用（存储满或被清理策略锁）。功能不受影响，只是每次冷启动都重新拉 SWF。

### 日志里看不到任何 `[js]` 行

`MoleBridge` 没注入或页面脚本在最早期就抛异常。检查 `configure()` 里
`addJavascriptInterface(..., "MoleBridge")` 是否执行到，以及 `configure()` 是否在 `loadUrl()` **之前**调用。
