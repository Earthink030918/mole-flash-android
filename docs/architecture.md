# 架构

代码分四块：`MainActivity`（宿主 + 请求路由 + 资源调度 + 显存看护）、`SocketBridge`（本地 WebSocket→TCP 中继）、
`HttpCache`（静态资源落盘）、`CrashProbe`（崩溃史探测）。页面侧是 `shell.html` + `mole_boot.js` + Ruffle。

---

## 1. 启动时序

`MainActivity.onCreate()` 的顺序是有依赖的，调换会出问题：

| # | 动作 | 说明 | 关键日志 |
| --- | --- | --- | --- |
| 1 | `addFlags(FLAG_KEEP_SCREEN_ON)` | 挂机不断屏 | — |
| 2 | `setRequestedOrientation()` | `smallestWidthDp < 600` → `SENSOR_LANDSCAPE`(6)；否则 `FULL_SENSOR`(10)，平板/桌面跟传感器走 | `屏幕：smallestWidthDp=…` |
| 3 | `new SocketBridge().start()` | **必须早于 WebView**，壳页要拿端口号注入 `__SOCKET_PROXY__` | — |
| 4 | `new HttpCache(getCacheDir())` | 失败只降级为直连，不阻断 | `磁盘缓存初始化失败…` |
| 5 | `loadTargets()` | 种子目标 + 上次学习结果 | `socketProxy 目标已就绪，共 N 条` |
| 6 | `evaluateLoadLevel()` | 依据崩溃史定渲染档位 | `上次 N → 本次 M` |
| 7 | `startGpuWatch()` | 起 `HandlerThread("mole-gpu-watch")` | — |
| 8 | `FrameLayout` + `WebView` 塞进去 | 黑底，`setWebContentsDebuggingEnabled(true)` | — |
| 9 | `configure()` | WebSettings、`MoleBridge` 注入、UA 去 `; wv` | `UA = …` |
| 10 | `loadUrl("http://mole.61.com/__mole_shell__")` | 域名只为过同源，请求会被拦 | `→ http://…` |

`configure()` 里几项特别要紧：

- `setMixedContentMode(0)`（`MIXED_CONTENT_ALWAYS_ALLOW`）—— 壳页走 http，上游有 https 资源。
- `setAllowUniversalAccessFromFileURLs(true)`、`setAllowFileAccess(true)` —— 兼容 Ruffle 的 worker 加载。
- `setMediaPlaybackRequiresUserGesture(false)`。
- `setTextZoom(100)` 包在 try 里，部分 ROM 不支持。
- UA 去掉 `; wv` 是为了让上游按普通 Chrome 回页面而不是回降级版。

## 2. 请求路由表

`WebViewClient.shouldInterceptRequest` 按固定顺序判定，先命中先返回，全部落空才交回 WebView 原生加载：

| 序 | 条件 | 处理 | 内容来源 |
| --- | --- | --- | --- |
| 1 | URL 以 `/__mole_shell__` 结尾 | `shellResponse()` | `assets/ruffle/shell.html`，替换 4 个占位符 |
| 2 | URL 含 `/fonts/` | `fontResponse(basename)` | 系统字体文件，见 §5 |
| 3 | basename `== __mole_ruffle__.js` | `assetStream("ruffle/ruffle.js")` | `assets` |
| 4 | basename `== __mole_boot__.js` | `assetStream("ruffle/mole_boot.js")` | `assets` |
| 5 | basename `core.ruffle.*.js` | `assetStream` | `assets` |
| 6 | basename `core.ruffle.*.js.map` | `assetStream(..., "application/json")` | `assets` |
| 7 | basename 以 `.wasm` 结尾 | `wasmResponse(basename)` | `assets/<basename>.gz` → `GZIPInputStream` 解压直出 |
| 8 | 方法为 `GET` 且 host ∈ 淘米域 | `upstream(request)` | 真网络 + 磁盘缓存 |

`isTaomeeHost()` 的白名单：`61.com`、`*.61.com`、`taomee.com`、`*.taomee.com`、`*.51mole.com`。
其余域（含 `newmisc.taomee.com` 之外的统计/广告）一律不代理 —— 让它被 WebView 正常加载或失败，避免污染缓存。

### 壳页占位符

`shell.html` 里四个标记由 Java 侧字符串替换后下发（`Cache-Control: no-store`）：

| 占位符 | 注入值 | 作用 |
| --- | --- | --- |
| `__FONT_SOURCES__` | `FONT_SOURCES` 数组 | Flash 文本用的字体 URL 列表 |
| `__SOCKET_PROXY__` | `[{host, port, proxyUrl:'ws://127.0.0.1:<port>/?host=…&port=…'}, …]` | 交给页面侧 polyfill |
| `__PIXEL_BUDGET__` | `pixelBudget()` | 渲染像素预算 |
| `__RENDERER__` | `'wgpu-webgl'` | Ruffle 后端名 |

> 占位符未被替换时，页面里用 `try { X = __FOO__ } catch(e) {}` 兜住，退化为默认值而不是整页白屏。

## 3. 上游代理 `upstream()`

- 缓存判定 `HttpCache.cacheable(url)`：去 query/fragment 后按扩展名白名单命中，且显式排除 `newmisc.taomee.com`
  （那台是动态接口）；命中后读缓存直出，加 `Cache-Control: public, max-age=604800`。
- 带 `Range` 请求头的一律绕过缓存（视频/分段 SWF）。
- 落盘条件：`cacheable && 响应码 200 && Content-Length ≤ 6 MiB`；超过 6 MiB 或未知长度只透传不落盘。
- 透传的请求头只有 `accept` / `accept-language` / `x-requested-with` / `range`，其余重写；
  `Referer` 重建成 `http://<上游 host>/`，`Accept-Encoding: identity`（自己不吃压缩，交给 WebView）。
- `Cookie` 从 `CookieManager` 取出来带上，响应的 `Set-Cookie` 再写回 `CookieManager`。
- 连接 15 s、读 25 s 超时；任何异常都 `return null` 交回 WebView 原生处理，不阻塞页面。

## 4. Socket 桥

Flash 的 `Socket` 在 Ruffle 里没有实现（浏览器给不了 raw TCP）。这里用「本地 WebSocket + Java 中继」补齐：

```
AS3 Socket.connect(host, port)
  → shell.html 里的 polyfill 改写为 new WebSocket('ws://127.0.0.1:<bridgePort>/?host=…&port=…')
    → SocketBridge 在该端口上完成 RFC6455 握手
      → 抽出 host/port，java.net.Socket 连真服务器
        → pumpClientToTcp / pumpTcpToClient 双向泵字节
```

实现细节：

- 端口由系统分配（`ServerSocket(0)`），`getPort()` 回读，所以每次启动都不同。
- 握手用固定 GUID `258EAFA5-E914-47DA-95CA-C5AB0DC85B11` + `Base64(SHA1(key+GUID))`。
- 帧处理：opcode `8` 关闭、`9` ping 回 pong、`10` pong 忽略；带 mask 时用 4 字节 key 异或还原；
  单帧上限 64 MiB，超过直接断开。`MAX_HEADER` 64 KiB。
- 目标地址校验 `plausibleIp()`，配合 `mask()` 打码后写日志（日志里只出现 `1.***.***.***`）。

### 目标发现（种子 + 学习）

1. **种子**：`SEED_HOSTS_ENC` 三条，base64 解码后逐字节 `^ 0x5A` 还原成主机名；
   与 `SEED_PORTS`（1860–1880、3195–3215、6650–6700，外加 1863/1865/3200/6665）做笛卡尔积。
2. **学习**：Ruffle 连不上代理时会 `console.warn("Missing WebSocket proxy for host X, port N")`，
   `shell.html` 捕获这句 → `MoleBridge.onMissingProxy(host, port)` → `learnMissingProxy()` 追加到
   `this.targets` 并写入 `SharedPreferences("mole_shell").socket_targets_v2`（逗号分隔），下次启动直接可用。
   `SocketBridge` 侧还有一条 `DiscoveryListener.report(host, port)` 的独立上报路径。

## 5. 渲染与降载

三套互补的降载手段，目标是绕开 Adreno 驱动「GPU 内存池耗尽 → SIGTRAP 杀进程」：

**(a) 启动档位 `loadLevel`（0–5）**

`CrashProbe.recentCrashStreak()`（`ApplicationExitInfo`，API 30+）读最近连续崩溃次数：

- 上次非正常退出（`boot_running_v1 == true`）→ 档位 +1，上限 `MAX_LEVEL`
- 上次干净退出 → 档位 −1，下限 0

对应像素预算 `PIXEL_BUDGETS = {1210000, 900000, 660000, 460000, 320000, 210000}`，持久化在 `boot_crashes_v4`。

**(b) 运行时 DPR 预算**

`shell.html` 用 `Object.defineProperty` 接管 `window.devicePixelRatio`，把它钳到
`min(3, sqrt(BUDGET / (lw*lh)))`，下限 0.5。Ruffle 只在容器尺寸变化时才重读 DPR，
所以 `__moleSetBudget()` 用「宽度 +1px → 下一帧还原」的跨帧抖动骗它重建 canvas。

**(c) GPU 显存看护**

`MainActivity$1` 在独立 `HandlerThread` 上轮询：

| 常量 | 值 | 含义 |
| --- | --- | --- |
| `GPU_POLL_MIN_MS` / `GPU_POLL_MAX_MS` | 8000 / 60000 | 轮询间隔上下限，稳定后逐步放宽 |
| `GPU_SOFT_MB` | 400 | 越过即调 `__moleSetBudget()` 就地降采样，不重载 |
| `GPU_RELEASE_MB` | 410 | 越过即 `releaseTextures()`，空白页中转 |
| `MAX_RELEASES` | 10 | 主动释放次数上限 |
| `RELEASE_COOLDOWN_MS` | 120000 | 两次释放的最小间隔（panic 强制时 15 s） |
| `STABLE_AFTER_MS` | 300000 | 连续 5 分钟不崩才允许升档 |
| `MAX_AUTO_RELOADS` | 8 | 自动重载保险丝 |

显存读数来自 `ActivityManager.getProcessMemoryInfo` 的 `summary.graphics`（KB），除 1024 取 MB。

**(d) 帧率还原**

解析 SWF 文件头得到官方客户端是 **24 fps**，而 Ruffle 默认跑满 60，表现为「小游戏开了倍速」。
`shell.html` 在 `ruffle.js` **之前**装节流器，把渲染帧固定到 24 fps，同时降低 GPU 负载。

## 6. JS 桥 `MoleBridge`

`addJavascriptInterface(new JsBridge(), "MoleBridge")`，只暴露 5 个方法，全部走 UI 线程回调：

| 方法 | 方向 | 用途 |
| --- | --- | --- |
| `bridgePort()` | JS → Java | 壳页取 WebSocket 端口，拼 `proxyUrl` |
| `log(String)` | JS → Java | 页面日志转发到 logcat（tag `MoleShell`，前缀 `[js]`） |
| `toast(String)` | JS → Java | 调试提示 |
| `onMissingProxy(host, port)` | JS → Java | 补录服务器目标 |
| `onPanic()` | JS → Java | Ruffle panic → 清空重载 |
| `onGpuExhausted(kind)` | JS → Java | `webglcontextlost` 上报：`lost` 降一档，`dead`（2.5 s 未恢复）重载 |

## 7. 生命周期

- `onPause`：对 `ruffle-player` 挨个 `pause()`，再 `pauseTimers()` —— 不暂停会一直在后台跑帧。
- `onResume`：`resumeTimers()` + `goImmersive()`。
- `onConfigurationChanged`：重进沉浸式，向页面派发 `resize`。
- `onTrimMemory(≥80)`：`clearCache(false)` 释放 WebView HTTP 缓存。
- `onDestroy`：停看护线程、`markCleanExit()`（写 `boot_running_v1=false`）、停 `SocketBridge`、
  `loadUrl("about:blank")` 后 `destroy()`，并从父容器摘除 —— 顺序反了会泄漏 WebView。
- `onBackPressed`：能回退就回退，否则退出。

## 8. 沉浸式

API 30+ 用 `WindowInsetsController.hide(systemBars())` + `BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE`(2)；
以下用 `setSystemUiVisibility(5894)`（`FULLSCREEN | HIDE_NAVIGATION | IMMERSIVE_STICKY | LAYOUT_*`）。

## 9. 反编译代码的阅读约定

`src/java` 里大量 `access$NNN` 是 **javac 为内部类生成的合成访问器**，不是原始方法。
原文应为 `private` 字段/方法的直接访问，例如：

```java
// 反编译产物
MainActivity.access$2100(this.this$0).getPort();
// 原始写法
this$0.bridge.getPort();
```

阅读时按「`access$1000+x` 递增分配」的规律对照字段表（见 `MainActivity` 字段声明顺序），
或直接忽略它们、只看调用链。其余失真点见 [`decompile-report.md`](decompile-report.md)。
