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

### 工具按钮 / 侧边菜单「点一下就消失」，或点了完全没反应

**已确诊并修复**，根因不在游戏，在 Ruffle 自带的右键菜单。

现场录像逐帧（银行 ATM，手指停留约 1 秒）：

| 时刻 | 画面 |
| --- | --- |
| 64.5s | 手指按在 ATM 上 |
| 65.0s | Ruffle 弹出右键菜单：音量控制 / 打开存档管理器 / 关于 Ruffle / 隐藏此菜单 |
| 66.0s | 菜单自行消失（松手触发 `{once:true}` 的 `pointerup` 收起） |
| 66.5s | 再点一次，才弹出游戏自己的「摩尔资料」 |

机理：触摸时 Ruffle 在 `pointerdown` 起一个长按计时器，到点就 `showContextMenu()`，
并注册 `document` 上的 `pointerup`（`{once:true}`）来收起自己，同时 `stopPropagation()`。
于是 SWF 只收到 `mouseDown`、永远收不到 `mouseUp` —— 点击不成立，覆盖层却「闪一下就没了」。

修复：`RufflePlayer.config.contextMenu = 'off'`。改完后长按 1 秒以上也不会再出现该覆盖层。

回归方法（不用手点，直接验证渲染层）：

```bash
# 按住不放 2.2 秒，期间截图；正常情况画面里不应出现「音量控制/关于 Ruffle」
(adb shell input swipe 1280 700 1280 700 2200 &) ; sleep 1.1
adb exec-out screencap -p > hold.png
```

### 进度条卡在 100%，一直「正在进入 XX」

两个独立原因，都会导致加载链断在同一个位置，要分别看日志。

**原因一：后端不支持离屏渲染。** 日志特征：

```
ERROR core/src/avm2.rs:702 Error running AVM2 construction for movie clip:
      RustError("Render backend does not support BitmapData.draw")
```

进场景必经 `BitmapData.draw`。三档实测：只有 `wgpu-webgl` 支持；
`webgl` 与 `canvas` 都会在影片剪辑**构造期**抛错，加载状态机再也不会推进。
所以 `preferredRenderer` 必须是 `wgpu-webgl`，不要为了省显存改成 `canvas`。

**原因二：套接字半包。** 日志特征：

```
ERROR core/src/avm2.rs:702 Error dispatching event "8755":
      Error: Error #2030: End of file was encountered.
```

服务端一个逻辑包被 TCP 拆成两段，本地桥每 `read()` 一次就发一个 WebSocket 帧，
SWF 读到半个包 → `readUnsignedInt` 抛 EOF → 加载停住。实机统计 4 次进服命中 3 次。

修复：`shell.html` 在 `ruffle.js` 之前替换 `window.WebSocket`，对本地桥连接做 8ms 合帧
（把 8ms 内到达的多个二进制帧合并成一次投递）。流式协议里「合并」永远安全，
「切开」才危险，所以这一步只会减少 `#2030`。验证：

```bash
adb logcat -d -s MoleShell | grep -c "2030"    # 期望 0
```

仍复现时 `StuckGuard` 会在满 10 秒后自动重载重试（仅限启动后 4 分钟内），
**重载后会回到「开始」页**，再点一次「开始」即可。

### 挂机一段时间后闪退

特征是进程被内核直接打死，JS 侧拿不到任何回调：

```
W Adreno-GSL: sharedmem_gpumem_alloc: mmap failed errno 12 Out of memory
E Adreno-GSL: kgsl_sharedmem_alloc ioctl failed! Allocation size: (4 KB)
F libc: Fatal signal 5 (SIGTRAP) ... in Chrome_InProcGp
```

连 4KB 都分配不出来，驱动拿到空指针 → Chromium CHECK 失败。注意这是**系统内存**吃紧
（kgsl 的分配来自系统页），不只是显存。

`shell.html` 的对策是 `IdleGuard`：

- 连续 5 分钟无触摸 → rAF 节流到 12fps（只降帧、不降分辨率），触摸瞬间恢复；
  Ruffle 的 `Timer`/`setInterval` 由真实时间驱动，与 rAF 解耦，所以挂机不会掉线；
- 渲染上限收到 2.5 倍（后备缓冲 2400×1400，比 3.0 时少约 30% 像素）；
- 每 20 秒读一次 `gl.getError()`，拿到 `0x505`（`GL_OUT_OF_MEMORY`）立刻压到画质下限。

要进一步延寿，把 `shell.html` 里的 `MAXCAP` 从 `2.5` 调到 `2.0`，或把 `IDLE_MS` 从 5 分钟调短。

### 画面发虚 / 分辨率过低

旧实现把 Java 注入的预算当绝对上限，960×560 算出来 DPR 只有 0.84~1.29；
而 2560 宽的屏上舞台被放大 1.185 倍、屏幕密度 2.25 —— 真正需要 2.67 倍。
一个渲染像素摊两个屏幕像素，中文 UI 必然发虚。

现在按 `raw × fit × SS` 反推预算（见 `shell.html` 的 `__moleRefreshBudget`），
且**不读** `offsetWidth` / `getBoundingClientRect`：Ruffle 的 wasm 会高频读
`devicePixelRatio`，每次读都强制一次同步重排，初始化阶段叠起来就是「UI 初始化卡顿」。

确认当前值：

```bash
adb logcat -d -s MoleShell | grep "分辨率："
# [MoleShell] 分辨率：DPR=2.50（raw=2.25 × fit=1.185 × SS=1.15） | 后备缓冲≈2400x1400 ...
```

### 一闪白光 / 偶发闪黑一帧

GPU 上下文丢失后重建，合成器按透明画布默认底色合成了一帧。`shell.html` 已给 `#wrap canvas`
铺黑底缓解；若频繁出现，说明显存在临界点，往下调预算（见下一条）。

### 玩一会儿崩溃，日志有 `页面报告 GPU 上下文异常：lost` 然后 `dead`

Adreno 显存池耗尽。内核直接 SIGTRAP 杀 RenderThread，Java 层拦不到，只能提前降载。处置顺序：

1. 先确认看护在工作：有没有 `[js] 降载 budget=…` 或 `WebGL OUT_OF_MEMORY` 日志
2. 缩小渲染上限：把 `shell.html` 里的 `MAXCAP` 从 `2.5` 调到 `2.0`
3. 缩短挂机判定：把 `IDLE_MS` 从 `5 分钟` 调到 `2 分钟`

**不要**把 `preferredRenderer` 改成 `canvas` 或 `webgl` 来“省显存” —— 这两档都不支持
`BitmapData.draw`，改完连场景都进不去（见上面「进度条卡在 100%」）。

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
