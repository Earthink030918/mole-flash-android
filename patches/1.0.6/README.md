# 1.0.6 补丁 —— 触控板视觉隐藏 + 切后台不暂停

基线包：`mole-1.0.5.apk`（10,302,852 B，SHA-256 `f4c04f0b…26b72`）
产物：`mole-1.0.6.apk`（10,306,948 B，versionCode 7 / versionName 1.0.6）
SHA-256：`1811bc92c288ae92a88046163d64f2839c15494bf8ed4efe39a96df4f6b2a740`

本次只有两处行为改动，**都与游戏本体无关**：帧率 24、quality low、
画幅 960x560、节流器、服务器地址、OmniPad 的靶区与灵敏度，一律未动。

---

## 一、触控板视觉隐藏

要求：右下角那块虚拟触控板挡画面，隐藏掉，其余功能不变。

**做法：只改外观，不碰命中测试。**

```css
#pad.pad-invisible .omnipad-trackpad{opacity:0!important;}
```

为什么是 `opacity:0` 而不是 `display:none` / `visibility:hidden`：
后两者会让元素**退出命中测试**，拖动手势当场失效；`opacity:0` 的元素
照样接收 pointer 事件，所以「看不见」但「手感一点没变」。

- 挂载时 `padRoot.className = 'pad-invisible'`（默认隐藏）
- 靶区（TargetZone）、虚拟光标、click 映射、灵敏度 0.6 全部原样
- 运行时开关：`__molePad.trackpad('on')` 恢复半透明面板，
  `__molePad.trackpad('off')` 再隐藏；
  `__molePad.state().trackpadVisible` 可查当前状态

隐藏后仍能在原位置拖动/轻点 —— 只是看不见板子，光标会动，有反馈。

---

## 二、切后台不再暂停（紧急）

### 根因（ruffle.js 内联 bundle，`setupTabVisibilityHandling`）

```js
let A = this.loadedConfig?.backgroundExecutionMode ?? vA.None;
document.hidden
  ? (A === vA.MainThread
      ? (this.instance.enable_background_tick_mode(),
         this.lastActivePlayingState && this.startBackgroundTick())
      : this.instance.pause())
  : (A === vA.MainThread && (this.stopBackgroundTick(),
                             this.instance.restart_animation_loop()), ...)
```

走哪一边**完全由配置决定**。壳层原来写的是：

```js
backgroundExecutionMode: 'none',   // ← 1.0.5 及以前
```

于是页面一 hidden 就 `pause()`，同时 Java 侧 `onPause` 还补了两刀：

| 原动作 | 后果 |
| --- | --- |
| `BLUR_JS` → `element.pause()` | 游戏逻辑当场冻结 |
| `WebView.onPause()` | 内核侧暂停 rAF / 渲染更新 |
| `WebView.pauseTimers()` | 连 JS 定时器一起停，Worker 的 `setTimeout` 也停 |

冻结期间会话还挂着，不发心跳、不动时间轴。回来时：

- `web/src/lib.rs:1219`：`dt = timestamp − prev_timestamp` = 挂起时长
- `core/src/player.rs`：`frame_accumulator += dt` 后连跑 5 帧（`max_frames_per_tick`）
- `core/src/timer.rs:37`：`update_timers(dt)` 把所有到期定时器补跑一遍（`MAX_TICKS=10`）

游戏把积压逻辑一次性做完，每个包都带着跳变后的时间戳发出去 ——
服务器看到的就是「时间倒挂 / 顺序错乱」，随即踢下线。

### 修法

1. **配置改成 `backgroundExecutionMode: 'mainThread'`**
   让 Ruffle 走官方另一条路：它自己起一个 Web Worker，里面按影片帧率
   （`1000/24 ≈ 41.67ms`）`setTimeout` 调
   `instance.tick_for_background(performance.now())`。
   Worker 的定时器不受页面可见性节流，所以后台**真的在按 24fps 跑**，
   客户端时间轴与真实时间始终连续 —— 没有积压，也就没有补帧。
   （枚举值只有 `'none' | 'mainThread'`，写错会回落到 `none`。）

2. **Java `onPause` 不再暂停 WebView**
   删掉 `BLUR_JS`、`WebView.onPause()`、`pauseTimers()`，只留一句
   `evaluateJavascript("window.__moleEnterBackground&&window.__moleEnterBackground();")`。
   `pauseTimers` 必须删 —— 它会把 Worker 的定时器一起停掉，
   mainThread 后台 tick 就彻底跑不起来。

3. **`onResume` 通知壳层**
   `evaluateJavascript("window.__moleLeaveBackground&&window.__moleLeaveBackground();")`，
   由壳层负责「停 Worker → 恢复动画循环 → 对齐时间轴」。

### 壳层第 6 段补的三件事

Ruffle 自己没做好的地方：

| 问题 | 处理 |
| --- | --- |
| `startBackgroundTick` 不判重，它自己的可见性分支和我们都会调，重复调用会 `new` 出第二个 Worker，两个 Worker 各推 24fps → **游戏两倍速** | 实例上覆盖成幂等（`if (this.backgroundWorker) return`） |
| 极少数 WebView 在 Activity 不可见时不派发 `visibilitychange`（`document.hidden` 一直 false），Ruffle 永远等不到 hidden 分支 | `__moleEnterBackground` 检查 `document.hidden`，为 false 时代劳一次 |
| 后台喂给 core 的是 `performance.now()`，前台喂的是第 0 段的虚拟时间轴 `vTs`；不对齐的话 `dt` 恒为负（`lib.rs:1219` **没有负值保护**）→ 帧累加器只减不增 → **画面彻底冻住** | 只有「后台真跑过」才 `__moleAlignClock()`，把 `vTs` 直接对齐到真实时间；没跑过则维持原钳制（只推进 1 帧），绝不把挂起时长喂给 core |

「后台真跑过」的判据：拦在 `startBackgroundTick` / `stopBackgroundTick`
里记标记 —— Ruffle 自己的 visible 分支会先 `stopBackgroundTick`，
等我们反应过来 `backgroundWorker` 已经是 null 了，只有拦在方法里才抓得住。

### 回调重复导致双倍帧率的防护

`onResume` 不能无条件 `restart_animation_loop()`：Ruffle 的 visible 分支
已经 restart 过一次，再调一次会多登记一个 rAF 回调 → 双循环 → 双倍速。
所以只有「worker 还在（说明它的分支没跑）」时才由我们 restart。

---

## 改动清单

```
assets/ruffle/shell.html      123,664 → 136,131
  · 第 2 段  backgroundExecutionMode: 'none' → 'mainThread'
  · 第 0 段  pendingAlign / __moleAlignClock / dispatch() 抽取
  · 第 3.5  __molePurgeTex 在后台 tick 期间跳过（不重建渲染目标）
  · 第 5 段  pad-invisible 默认隐藏 + __molePad.trackpad()
  · 第 6 段  新增「后台保活」（约 150 行）
classes.dex                    51,020 → 51,112
  · MainActivity.onPause   删 BLUR_JS / WebView.onPause / pauseTimers
  · MainActivity.onResume  加 __moleLeaveBackground
AndroidManifest.xml            版本号 6 / 1.0.5 → 7 / 1.0.6
META-INF/*                     重新签名（证书 974EA1B9… 与 1.0.1~1.0.5 同源）
```

`ruffle.js`、`core.ruffle.*.wasm.gz`、`mole_boot.js`、OmniPad 的 UMD/CSS
**字节级未变**。

---

## 离线验证

```bash
node verify/clock_test.js  dec-105/assets/ruffle/shell.html   # 27 项
node verify/pad_test.js    dec-105/assets/ruffle/shell.html   # 52 项
node verify/bg_test.js     dec-105/assets/ruffle/shell.html   # 34 项
```

三套都是**从 shell.html 里切真实代码**来跑的，不是复制：

- `clock_test`：平时 1:1、250/800ms 阈值边界、时间戳回退、
  对齐分支（vTs 直接等于真实时间戳、stallMs 归零、随后 3 帧推进 50ms）
- `pad_test`：落点几何（20:9 / 18:9 / 4:3、转屏重贴、兜底浮层）、
  挂载门禁、OmniPad 缺席降级、**默认隐藏 + 开关往返**
- `bg_test`：幂等防双 Worker、hidden 时不抢活、visibility 不变时接管、
  暂停态不维持时间轴、回前台不重复 restart、没跑过绝不对齐

dex 侧用 `dexdump -d` 核对字节码：`onPause` 只剩
`invoke-super` + `iget-object web` + `evaluateJavascript`，
`pauseTimers` 在常量池里已为 0 次。

---

## 真机验证建议

1. **后台不暂停**：进游戏挂机 → 切后台 3~5 分钟 → 返回。
   - 应当**不掉线**、不出现「被服务器踢出」
   - logcat 看 `[MoleShell] 回到前台：后台一直在跑，时间轴对齐真实时间（不补帧、不跳变）`
   - 若看到的是 `长间隔 …ms → 只推进 1 帧`，说明 Ruffle 的后台 Worker 没起来，
     需要把 `backgroundExecutionMode` 的解析结果和
     `Unable to create background Worker` 一起抓给我
2. **触控板隐藏**：右下角应当看不见板子；在原来的位置拖动，光标会动；
   轻点能在光标处确认。想恢复外观：控制台 `__molePad.trackpad('on')`。
3. **回归**：走路、点 NPC、金豆商城、悬停子菜单应当与 1.0.5 一致。

诊断口子：`__moleClock()`（时间轴 / 对齐次数）、
`__moleBg()`（hidden / worker / playing）、`__molePad.state()`。

---

## 代价与已知边界

- **后台会持续渲染**：`tick_for_background` 内部就是完整 `tick()`，
  包含 `core.render()`。所以后台仍占 GPU 与电量 —— 这是「后台继续跑」
  的固有代价，也是不掉线的根本原因。
- **后台不回收显存**：`__molePurgeTex` 在 worker 存在期间直接返回 false，
  避免在一个没人看的上下文上反复销毁/重建渲染目标。回到前台后照常回收。
- **游戏本身是暂停态时**不做后台维持（`is_playing()` 为 false 就不启 Worker），
  这种情况走原来的「只推进 1 帧」钳制。
- 若系统把整个进程冻结（Doze / 厂商清理器），Java 与 JS 一起停，
  回来时仍会走钳制分支 —— 至少不会发出跳变的数据包。

## 回退

- 触控板外观：`__molePad.trackpad('on')`
- 后台行为：把第 2 段改回 `backgroundExecutionMode: 'none'`，
  Java 侧 `onPause` 恢复 `pauseTimers()` —— 即回到 1.0.5 的「冻结 + 钳制」策略
