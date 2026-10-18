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

### 账号被踢出 / 提示在其他设备登录 / 突然掉回登录页

先**按一次返回键**。`MainActivity.onBackPressed()` 在 `WebView` 可回退时执行 `goBack()`，
会把页面退回上一层的登录界面，重新登录即可继续，不需要强杀进程。

如果按返回键直接退出应用（说明当前是历史栈第一页，`canGoBack()` 为 `false`），那就只有重开。
反复被踢通常是同一账号在别处登录，或服务端判定会话失效，与壳本身无关。

### 一闪白光 / 偶发闪黑一帧

GPU 上下文丢失后重建，合成器按透明画布默认底色合成了一帧。`shell.html` 已给 `#wrap canvas`
铺黑底缓解；若频繁出现，说明显存在临界点，往下调预算（见下一条）。

### 玩一会儿崩溃，日志有 `页面报告 GPU 上下文异常：lost` 然后 `dead`

Adreno 显存池耗尽。内核直接 SIGTRAP 杀 RenderThread，Java 层拦不到，只能提前降载。处置顺序：

1. 先确认看护在工作：有没有 `负载档位 → N（预算 N px）` 或降采样的 `[js] 降载 budget=…` 日志
2. 缩小预算：把 `PIXEL_BUDGETS` 整体乘 0.7，或把 `GPU_SOFT_MB` 从 400 调到 350
3. 实在压不住就把 `preferredRenderer()` 从 `wgpu-webgl` 换成 `canvas`（CPU 软渲染，画面糙但不会 OOM）

### `页面报告 Ruffle panic → 强制清空重载`，反复出现

wgpu 在特定驱动上过不了 `create_render_pipeline` 的 VERTEX shader 校验。这是 Ruffle + 驱动的组合问题，
换 Ruffle 版本或换后端，改代码无解。日志里若出现 `主动释放已达 10 次上限`，说明在死循环重载，
此时应停手排查而不是继续加自动重载次数。

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
