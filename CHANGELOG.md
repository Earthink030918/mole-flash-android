# Changelog

格式参照 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [1.1.3] - 2026-10-26（未发布，待真机验证）

**只修一件事：切到后台之后 App 自己没了，切回来是从头启动的。**

### 根因

1. `WebView` 的渲染进程优先级默认是 `RENDERER_PRIORITY_WAIVED` +
   `waivedWhenNotVisible = true` —— 看不见了就别管它的死活。1.1.2 把后台做成
   「完全冻结」（不出帧、不出声、无定时器工作），渲染进程就成了系统眼里
   「占着上百 MB 却什么都不干」的头号回收对象。
2. `MainActivity$6` 没实现 `onRenderProcessGone`。渲染进程一死，WebView 的默认
   处理是 `Process.killProcess(myPid())` —— 整个 App 无声消失，连崩溃弹窗都没有；
   任务留在最近任务里，再点回来就是系统重建 Activity，看起来像「自动重启」。

1.1.0 / 1.1.1 是「挂久了才崩」，因为那时候后台还在出声出帧、能多扛一阵；
1.1.2 一冻结就立刻变成可回收对象。

### Fixed

- `onCreate()` 里在 `new WebView()` 之前调用
  `WebView.setRendererPriorityPolicy(RENDERER_PRIORITY_IMPORTANT, false)`（API 26+），
  不可见时不再把渲染进程的优先级作废
- `MainActivity$6` 实现 `onRenderProcessGone`：返回 `true` 接管，不再让 WebView
  杀进程；把 `didCrash` / `rendererPriorityAtExit` 打进 logcat（`MoleShell`）
- 渲染进程真的死掉时：Toast 提示 + 前台立刻 `recreate()`、后台等 `onResume`
  再重建。进程不死、任务不丢，只是页面重载
- `onPause` / `onResume` 增加 `rendererGone` 判断，不再往已经死掉的 WebView
  下发 JS

### 没有动

`shell.html` 一行没改（后台冻结逻辑原样保留），帧率 / 画幅 / 画质预算 / 节流器 /
服务器地址 / 前台服务保活逻辑全部不动。

## [1.1.2] - 2026-10-26（未发布，待真机验证）

**换掉了 1.1.1 的思路。** 1.1.1 试图「把后台跑准」，1.1.2 承认那件事在
WebView 里做不到，改成「逻辑与音频原子冻结」+ 前台服务保活。基线取自
v1.1.0 的壳层，不是 1.1.1 的补丁。

### 为什么 1.1.1 那条路走不通

`core/src/backend/audio.rs` 的 `audio_skew_time()` 每个 tick 都比一次：

```rust
let stream_pos   = audio.get_sound_position(instance) / 1000.0;
let timeline_pos = (clip.current_frame() - start_frame) / frame_rate + offset_ms / 1000.0;
if (stream_pos - timeline_pos).abs() >= STREAM_RESTART_THRESHOLD {   // 1.0s
    audio.stop_sound(instance);
}
```

`timeline_pos` 由我们喂的 `dt` 决定，`stream_pos` 却由「`mix()` 被调用了
几次」决定 —— 而 `mix()` 只在 `web/src/audio.rs` 的 `Buffer::play()` 里被调，
`play()` 只由上一块 `AudioBufferSourceNode` 的 `onended` 触发。**`onended`
是主线程事件**。页面 hidden 后主线程被压到 1Hz，`stream_pos` 每秒只能走
92~743ms，`timeline_pos` 走 1000ms，每秒欠 0.3~0.9 秒，1~4 秒必破阈值
→ `stop_sound` 硬切波形 → 爆音，然后影片下一帧 `start_stream` 重启，循环。

这是 pull 模型对主线程节流的硬依赖，改喂法救不回来：

| 版本 | 后台喂法 | 结果 |
| --- | --- | --- |
| 1.0.6 | Ruffle 自己的 Worker（setTimeout） | Worker 定时器同样被节流，dt 一秒起步 |
| 1.1.0 | 让 Ruffle 补帧 | `frame_accumulator` 被清零，逻辑倒退 79% |
| 1.1.1 | 固定步长喂 `tick_for_background` | timeline 准了，`stream_pos` 照样掉队 |

### Fixed

- **切后台 / 回前台的声音爆破音**
  - 冻结前先用 70ms 把音量淡到 0：`AudioContext.suspend()` 会在波形中途
    切断输出，不淡出就是那声「啪」
  - 回前台先 `set_volume(0)` 盖住恢复瞬间，`play()` 之后再 120ms 淡回原音量
  - 屏蔽 Ruffle 自己的 `visibilitychange`：它回前台是**无条件**
    `instance.play()` + `audio_context().resume()`，对已经在播的流再来一次
    就是硬重启。我们在 `window` 捕获阶段 `stopImmediatePropagation()`,
    `document` 上的监听器一个都跑不到
- **回前台的画面卡顿**
  - 根因是回前台第一帧的 `dt = 挂起时长`，`Player::tick` 里连跑 5 帧
    （`max_frames_per_tick`）+ 补跑 10 个定时器（`MAX_TICKS`）+ 重渲染
  - 修法：§0 的时钟在冻解期**整段不推进 `vTs`、不 dispatch**。恢复时
    `dt` 恒为 1 个帧长，与 core 的 `last_tick` 停在哪一帧无关
  - 删掉 1.1.0 的 `__moleAlignClock()`：它把 `vTs` 对齐到真实时间，
    等于给 core 一个几分钟的 `dt`，正是卡顿的来源
- **后台挂久了应用崩溃**
  - 根因一：后台还在 tick，`audio.tick()` 按 dt 生成样本，而 mixer 只能靠
    `onended` 拉取，供大于求 → 样本被丢、`buffer_size` 一路翻倍到
    MAX(16384)，解码器与事件队列在 1Hz 下堆积 → OOM / 被判死
  - 根因二：没有前台服务，应用进 cached 状态后被系统冻结或回收
  - 修法：冻结期间零 tick、零 CPU、零内存增长；新增 `MoleKeepAlive`
    前台服务（`mediaPlayback` 类型，`START_NOT_STICKY`），
    `onPause` 起、`onResume` / `onDestroy` 停
- **`__moleAfterResume` 不再擅自 `play()`**：播放状态统一由 §6 管，
  两边都去 `play()` 就是对同一条流连续 resume 两次

### Changed

- §6 整段重写为「原子冻结」状态机：`inst.pause()` / `inst.play()`。
  这两个在 web 后端本来就是一对：`set_run_state(Suspended)` 顺带
  `AudioBackend::pause()` → `AudioContext.suspend()`，逻辑与音频停在同一时刻
- 用 handle 的 `pause()` 而**不是** element 的 `pause()`：后者会把
  播放器 UI 置成暂停态，回前台会多出一个播放按钮

### Unchanged

画幅 960x560、`frameRate 24`、`quality low`、DPR 预算、节流器、服务器地址、
Ruffle 二进制与 `classes.dex` 的游戏逻辑 —— 差异只在 `shell.html` §0/§6
与新增的一个 Service 类。

### Known Issues

后台期间游戏逻辑是**停**的（这正是零爆音的前提）。如果服务器有空闲超时，
长时间挂机可能要求重新连接 —— 这是「后台不跑」的代价，不是 bug。
前台服务只保证进程不被杀、回前台是热恢复。

## [1.1.1] - 2026-10-26

修掉 1.1.0 后台挂机的两个硬伤：**音乐爆破音**、**仍然被踢**。两者同源，
问题不在「有没有继续跑」，而在「跑的时候一次推了多久」。改动只落在
`shell.html` §6 与 §0 的十几行节拍逻辑上，画幅 / 帧率 / 画质 / 节流器 /
服务器地址 / Ruffle 二进制一律未动。

### Fixed

- **后台挂机音乐严重爆破音**
  - 现象：切后台后游戏 BGM 持续出现撕裂式爆音，回前台即恢复
  - 根因：`startBackgroundTick()` 拼出的 Worker 是 `setTimeout(41.67) → postMessage`
    的递归节拍，主线程收到就 `tick_for_background(performance.now())`。
    它假定 Worker 的定时器不受页面可见性节流 —— 错的，hidden 之后
    Chromium 对 Dedicated Worker 的 timer 同样有 1 秒下限。
    于是 `dt` 一跳就是 1000ms，`Player::tick` 末尾的 `self.audio.tick()`
    一次生成 44100 个样本（整整 1 秒）压进 WebAudio 队列，而音频线程
    这一秒只消费真实经过的那一点，队列立刻错位、环形缓冲互相覆盖，
    接缝处就是爆音。dt 每抖一次响一次
  - 修法：节拍改由壳层接管，时间轴换成自维护的合成轴，**每拍只推一帧**
    （恒 41.666ms）。音频每帧固定 1837 个样本，首尾相接，不再有接缝
- **仍然因「数据包对不上」被服务器踢**
  - 根因同上，只是落在另外两条路径上：
    ① `frame_accumulator += 1000` 之后 `max_frames_per_tick` 只让跑 5 帧
    （208ms），剩余 `if frame_accumulator >= frame_duration { = ZERO }`
    被直接丢弃 → 每秒只推进 208ms，逻辑时间落后真实时间约 79%，
    `getTimer()` 随之变慢，包时间戳越来越滞后；
    ② `update_timers(dt)` 收到 1000ms，一次把 `MAX_TICKS`(10) 个到期
    定时器全部补跑，心跳与动作包在同一毫秒连发十个 → 服务器看到
    「时间倒挂 / 顺序错乱」
  - 修法：同一条合成轴。每帧 `update_timers(41.67)` 最多出 1 个回调，
    逻辑时间按真实墙钟推进，时间戳不再漂移
- **两个节拍器互相打架**（1.0.6 隐患）：Ruffle 的 hidden 分支会
  `startBackgroundTick()`，壳层也在推，一个喂 `performance.now()`、
  一个喂合成轴，`dt` 正负横跳。现在把实例上的 `startBackgroundTick`
  摘成空函数，Worker 根本不会创建（`__moleBg().worker === false` 可验）
- **回前台可能双倍速**（1.0.6 隐患）：Ruffle 的 visible 分支和壳层
  各调一次 `restart_animation_loop()`，rAF 队列里就有两个同样的 handler，
  一帧推两帧逻辑。§0 的 `requestAnimationFrame` 现在对同一回调去重
- **`__moleAlignClock()` 会把欠账一次性喂给 core**：原实现回前台时把
  `vTs` 对齐到真实 rAF 戳。后台若被冻结过，差值几秒 → 一次大 `dt` →
  补帧风暴重演。改成接收合成轴最后一帧，从 `bg.ts + 41.67` **接续**，
  core 侧看到的 `dt` 仍是 41.67，一帧都不多给

### Added

- **AudioWorklet 节拍器**：跑在音频线程上，页面 hidden 时完全不受 timer
  节流 —— 这是「B 站式后台听歌」能持续的原因。每攒够一个影片帧的采样数
  就 `postMessage` 一次，主线程收到即推进。输出全零、只接 `destination`
  当心跳负载，不产生声音、不影响 Ruffle 自己那条音频链
- **定时器兜底**：`setInterval(50)` 与 worklet 同时叫同一个 `pump()`，
  后者按 `performance.now()` 自己算欠几帧，天然幂等。worklet 不可用
  （老内核 / `addModule` 失败 / `AudioWorkletNode` 构造失败）时自动降级，
  被节流到 1 秒一次也只是「一次补 24 帧」，每帧仍是 +41.67ms，无跳变
- **AudioContext 保活**：进后台立刻 `resume()`，并监听 `statechange`
  反复拉回。Android WebView 在页面 hidden / 失去音频焦点时会把上下文
  挂起，挂起后音频线程停摆 —— 既没声音，worklet 节拍器也停
- 诊断口子扩写：`__moleBg()` 现在返回
  `{on, hidden, mode, ticks, catchup, ts, audio, disarmed, worker, playing}`，
  `mode` 会告诉你节拍器是 `worklet` 还是 `timer`

### Changed

- `__moleAlignClock(contTs)` 新增可选参数：传合成轴时间戳则接续，
  不传仍退回「对齐真实时间」（保持向后兼容）
- `versionName` `1.1.0` → `1.1.1`；`versionCode` Android `9` → `10`、
  HarmonyOS `5` → `6`；UA `MoleShell/1.1.1`
- 后台日志口径改为
  `回到前台：后台推进 N 帧 / 墙钟 Xms（单轮最多 M 帧，节拍器=worklet）`

### Unchanged

- 画幅（`960x560`、`letterbox`）、`frameRate 24`、`quality low`、
  节流器与画面参数
- 服务器地址与端口池
- Ruffle 二进制：`ruffle.js` 与两份 `*.wasm.gz` 字节级一致；
  `classes.dex` 未改（本次差异只在 `assets/ruffle/shell.html`）

### Known Issues

- 后台仍耗 GPU：`tick_for_background` 内部走完整 `tick()`，渲染由
  `needs_render()` 门控，但每帧仍在跑 `core.render()`
- 页面被系统整体冻结（长时间后台且系统回收）时，合成轴会落后；
  `catchup` 上限 120 帧（5 秒）是防死循环的保险，超出部分不追
- 未做真机长跑验证，需用户按
  `回到前台：后台推进` 与 `后台节拍器：AudioWorklet` 两条日志确认

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
