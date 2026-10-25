# Changelog

格式参照 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [1.1.0] - 2026-10-25

自 1.0.3 之后的三轮内部迭代（`1.0.5` / `1.0.6` / `1.0.7`，均未单独发布）合并为本次发布，
内容分两类：**操作方式**（触控）与**后台存活**（时序）。Android 与 HarmonyOS 同步到同一版本。

### Added

- **虚拟触控板**：接入 [OmniPad](https://github.com/omnipad-js/omnipad) `@omnipad/vanilla@0.7.3`（commit `c91b3828`，MIT），按仓库 README 的 UMD 方式引入，仅把 unpkg 的 JS / CSS 换成本地内联（App 内无外网 CDN）。UMD 与 CSS 原样保留，逻辑未改
  - `TargetZone`：吸附在 `#wrap` 上的靶区，把触点翻译成 canvas 上的 `PointerEvent` / `MouseEvent`（`pointerType:'mouse'`、`composed:true`），穿透 Ruffle 的 Shadow DOM
  - `VirtualTrackpad`：`sensitivity 0.6`、`mapping {type:'mouse'}`；**拖动只移动光标**（悬停才展开的菜单因此能停住），**轻点才在当前光标处按下并松开**
  - 板子只挂在屏幕黑边里，优先级 右 → 左 → 下 → 上；四边都没有余量时**不挂**，只保留靶区，绝不覆盖游戏画面
  - 板子做成接近正方（`PAD_RATIO 0.93`）而非细长条，因为 `TrackpadCore.processInput` 以板子自身尺寸换算位移，窄长板会让竖直方向速度只剩水平的 1/5
  - 新增调试口：`__molePad.state()` / `.on()` / `.off()` / `.trackpad('on'|'off')` / `.corner(true)`
- **虚拟时间轴**：`shell.html` §0 的 rAF 泵改为可注入虚拟时间戳，`__moleClock()` 返回 `{stallMs, resumes, vTs}`
- **后台保活接口**：`window.__moleEnterBackground()` / `__moleLeaveBackground()`，供宿主生命周期调用

### Fixed

- **切后台返回被服务器踢下线**（紧急）：`onPause` 里 `element.pause()` + `web.onPause()` + `web.pauseTimers()` 让 rAF 停摆，返回时首个 `dt` 等于挂起时长，一次 tick 连跑 5 帧（`max_frames_per_tick`）并把到期的 `setInterval` 各补跑最多 10 次，影片时间轴凭空前进数分钟，期间发出的每个包都带跳变时间戳——服务器看到的就是「时间倒挂 / 顺序错乱」
  - 根因修复：`backgroundExecutionMode` 由 `'none'` 改为 `'mainThread'`，切后台时 Ruffle 在 Worker 里按 41.67ms 持续推进，时间轴连续
  - 兜底：虚拟时间轴把 `>800ms` 的间隔钳制为「只推进 1 帧」，`>250ms` 截断到 250ms；平时与真实时间 1:1，帧率仍是 24fps
  - `startBackgroundTick` 在 Ruffle 原实现里不判重（重复调用会起两个 Worker、双倍速），壳层覆盖为幂等
  - 部分 WebView 不派发 `visibilitychange`，改为同时检查 `document.hidden`
  - `dt` 无负值保护：只有「后台确实跑过」才用 `__moleAlignClock()` 对齐真实时间，否则仍走钳制
- **悬停菜单点不到**：触摸的 down/up 同帧完成，`update_mouse_state()` 算出 `rollOver` 时手指已抬起，子菜单来不及展开；由触控板的「拖动移光标 + 轻点落点」还原 PC 式交互
- **触控板遮挡游戏右下角**：1.0.5 / 1.0.6 的落点判据用物理像素估算（`MIN_MARGIN=104`），但 `window.innerWidth` 是 CSS px（2800×1260、DPR≈3.5 → 视口 800×360 → 单侧黑边 91px），判据永远不满足，每台真机都退到右下角 168×112 浮层。1.0.7 全部重写为 CSS px 几何

### Changed

- `MainActivity.onPause` 只下发 `__moleEnterBackground()`，删除 `BLUR_JS`、`WebView.onPause()`、`pauseTimers()`；`onResume` 恢复 `onResume()` + `resumeTimers()` + `__moleLeaveBackground()` + `goImmersive()`
- 触控板默认**可见**（在黑边里，看得见才找得到）；压画面或 `trackpad('off')` 时用 `opacity:0` 隐藏——不用 `display:none` / `visibility:hidden`，那会让元素退出命中测试、拖动当场失效
- `versionName` `1.0.3` → `1.1.0`；`versionCode` Android `4` → `9`、HarmonyOS `4` → `5`（中间 5~8 为内部迭代占用，不跳号回溯）
- HarmonyOS 端 `rawfile/ruffle/shell.html` 同步为同一份文件，UA 由 `MoleShell/1.0.3` 改为 `MoleShell/1.1.0`

### Unchanged

- 画幅（`960x560`、`letterbox`）、`frameRate 24`、`quality low`、节流器与画面参数一律未动
- 服务器地址与端口池未动
- Ruffle 二进制未动：`ruffle.js` 与两份 `*.wasm.gz` 字节级一致；Android 侧 `classes.dex` 也未改（本次差异只在 `shell.html`、`AndroidManifest`、`META-INF`）

### Known Issues

- 后台仍耗 GPU 与电量：`tick_for_background` 内部就是完整 `tick()`（含 `core.render()`），这是「不被踢」的代价
- 16:9 满幅机型（如 640×360 视口）四边皆无黑边，触控板不会出现，只能靠靶区直接点
- 未做真机长跑验证：切后台 3~5 分钟返回是否仍被踢，需用户按 `回到前台：后台一直在跑，时间轴对齐真实时间` 日志确认

## [1.0.3] - 2026-10-23

修复自 `1.0.1` 以来的稳定性与适配问题，含未单独发布的 `1.0.2` 内部迭代。

### Fixed

- **长时间运行后画面冻死**：`1.0.2` 的降载路径是 `raiseLoadLevel(+1)`，升到 `MAX_LEVEL` 后整条路径 `return` 空转；显存真正分配到失败时会进入 `context lost` 循环，进程不崩但画面再也不动。改为**无损纹理回收**：新增 `__molePurgeTex(minGapMs)`，复用 `#wrap` 跨帧 `+1px → 复位` 抖动让 Ruffle 重建渲染目标，仅归还纹理、不降画质档位；默认 240 秒冷却，避免抖动过于频繁
- **安卓边缘手势失效**：`1.0.2` 在 `onPageFinished` 里下发的 `setSystemGestureExclusionRects` 把屏幕两侧边缘划为游戏独占，系统侧滑返回被吃掉。整段移除，恢复系统手势
- `JSBridge` 的 `lost` 分支同样改走 `__molePurgeTex()`；`dead` 分支不再连带 `raiseLoadLevel(MAX_LEVEL)`，只保留 `reload`
- 三个显存闸门（`PIXEL_BUDGETS` 逐级下调点）的调用点全部替换为 `__molePurgeTex()`，`raiseLoadLevel` 在整个 App 内已无调用点

### Fixed（1.0.2，本次一并发布）

- **APP 隔一段时间自动重启**：三个来源合流——① GPU 看护里的 `releaseTextures` 会先白页再重建，观感等同重启；② `MainActivity$7` 补录端口后直接 `web.reload()`；③ `SocketBridge` 上行结束时把两侧一起 `closeQuietly`、下行 `read<=0` 时不同步关闭，`join` 永久挂死且线程池无界增长（实测线程 92→89 不回落）。三者分别改为：升档而非强释放、只落盘不重载、上下行对称关闭 + `newFixedThreadPool(24)`
- **进入金豆商城卡死**：`HttpCache` 把 `xml/ini/js/css/txt/json/cfg` 也纳入 7 天磁盘缓存，一次空响应就被钉死。改为静态扩展名白名单，只缓存 `swf/png/jpg/jpeg/gif/webp/bmp/mp3/wav/ogg/dat/bin`
- **触控 / 鼠标逻辑混乱**：`user-scalable=no` 在 Chrome 32+ 已失效，WebView 的捏合缩放仍开着，系统手势也会在边缘抢事件。`configure()` 内 `setSupportZoom` / `setBuiltInZoomControls` / `setDisplayZoomControls` 全部置 `false`，壳层补「输入加固」段：多指锁、屏蔽 `contextmenu` / `selectstart` / `gesturestart`、`overscroll-behavior: none`、`visualViewport` 缩放复位
- **一加全系平板 / ColorOS 17、红米 K90 适配**：随上述触控与手势修复一并覆盖（两者崩溃日志均来自边缘手势冲突与缩放状态残留）

### Changed

- `src/web/shell.html` 新增 `__molePurgeTex(minGapMs)`；`__moleSetBudget(px, force)` 增加 `force` 参数，可跳过早退强制重算
- `versionName` `1.0.1` → `1.0.3`，`versionCode` `2` → `4`

### Unchanged

- 画幅（`960x560`、`letterbox`）、`frameRate 24`、`quality low`、节流器与画面参数一律未动
- 服务器地址与端口池未动（`123.206.131.236` / `123.206.131.63` / `123.150.163.118`，端口 `1863/1865/3200/6665`）
- Ruffle 二进制未动：`assets/ruffle/ruffle.js` 与两份 `*.wasm.gz` 字节级一致，改动仅在 `shell.html`、`classes.dex`（约 50 KB 壳）

## [1.0.1] - 2026-10-19

本次更新更新了 APP 图标，图标来自群友授权赞助，感谢。

### Changed

- 应用图标更换为群友授权的摩尔庄园主题图标（`res/mipmap-*` 五档密度，48/72/96/144/192 px）
- `versionName` `1.0` → `1.0.1`，`versionCode` `1` → `2`

### Unchanged

- 除图标与版本号外，安装包内容与 `1.0.0` 完全一致（`assets/`、`classes.dex`、`resources.arsc` 未改动）

## [0.1.0] - 2026-10-18

首次公开。内容为对一个已构建 APK（`com.taomee.mole` v1.0，versionCode 1）的反编译整理。

### Added

- `src/java/`：23 个类的 Java 源码（androguard 4.1.4 / DAD 反编译）
- `src/web/`：`shell.html`、`mole_boot.js` 原件
- `src/manifest/AndroidManifest.xml`：AXML 解码结果
- `docs/architecture.md`：启动时序、请求路由表、Socket 桥、三档降载机制
- `docs/decompile-report.md`：工具链、失真清单、未覆盖部分
- `docs/build.md`：从源码重建 APK 的步骤
- `docs/troubleshooting.md`：按 logcat 原文的症状对照表
- `tools/run_decompile.py`：可复现的反编译脚本

### Known issues

- `src/java/` 中局部变量的静态类型不可信（DAD 推断较弱），不能直接编译
- `resources.arsc` 未解析为明文，清单里保留 `@7F020000` 形式的原始资源 ID
- Ruffle 二进制未纳入仓库，需从官方 releases 自取
