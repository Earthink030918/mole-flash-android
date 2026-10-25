# 1.0.5 补丁说明

基线：`mole-1.0.3.apk`（线上 v1.0.3，SHA-256 `df6a3085…8910`）。
1.0.4 是弃用的过渡版本，未纳入本条基线。
本次**只改了 `assets/ruffle/shell.html`**，`classes.dex`、`ruffle.js`、两份 `*.wasm.gz`、
`mole_boot.js` 字节级未变（可用 zip 内 md5 逐个核对）。

---

## 一、紧急修复：切后台回来被服务器踢下线

### 现象
把游戏切到后台，再返回时服务器收到**大量时间顺序对不上的异常数据包**，随即踢人。

### 根因（Ruffle 源码实证，版本 `0.8.0-nightly.2026.10.16`，commit `ff5321cd`）

```
web/src/lib.rs:1220     dt = timestamp − prev_timestamp        // 就是 rAF 时间戳差
core/src/player.rs:550  frame_accumulator += dt;
                        while (frame < max_frames_per_tick(≤5) && acc >= frame_duration)
                            run_frame();
                        ...
                        update_timers(dt);
core/src/timer.rs:37    cur_time += dt; 然后 while(...) 逐个补跑到期定时器（MAX_TICKS=10）
```

Java 侧 `MainActivity.onPause()` 做了三件事：

```java
evaluateJavascript(BLUR_JS)      // → element.pause()
web.onPause()                    // → 渲染与 rAF 停摆
web.pauseTimers()                // → 全进程 JS 定时器冻结
```

于是返回时第一个 rAF 时间戳已经是几分钟之后，`dt` 直接等于挂起时长。一次 tick 里：

- 连跑 5 帧（`max_frames_per_tick` 上限）
- `update_timers(dt)` 把每个到期的 `setInterval` 再补跑最多 10 次
- 影片内的时间轴凭空前进几分钟

游戏在这一个瞬间里把积压逻辑全跑了一遍，每个包都带着跳变后的时间戳发出去 ——
服务器看到的就是「时间倒挂 / 顺序错乱」的一串包。

### 修法（`shell.html` 第 0 段：时间轴钳制）

**只改喂给 Ruffle 的时间戳，不碰任何真实计时。**

```js
var step = ts - lastReal;                 // 真实间隔
if (step > 800)  step = FRAME_MS;         // 后台恢复：只推进 1 帧
else if (step > 250) step = 250;          // 单帧异常掉帧：截断
vTs += step;                              // 虚拟时间轴
...
cbs[i](vTs);                              // ← 交给 Ruffle 的是 vTs，不是原生 ts
```

- 平时 `vTs` 与真实时间 1:1，一毫秒不差，**帧率仍是 24fps**
- 后台恢复只走 1 帧 → `frame_accumulator` 只加一帧 → 不补帧、定时器不补跑、时间轴不跳
- 250ms 的截断阈值高于任何真实掉帧，不会造成时间膨胀

诊断：`window.__moleClock()` → `{stallMs, resumes, vTs}`；
logcat 里会出现 `[MoleShell] 长间隔 xxxxxms（切后台/主线程停顿）→ 只推进 1 帧…`

### 附带：暂停态兜底
`BLUR_JS` 里的 `element.pause()` 与 Ruffle 自己的 `visibilitychange` 回调用的是
「挂起前记录的播放状态」，两者存在竞态（pause 先跑 → 记录到 false → 回来不 play，
屏幕上会多个播放按钮）。恢复时若检测到 `isPlaying === false` 就补一次 `play()`。

---

## 二、触控：注入 OmniPad 虚拟触控板

来源：<https://github.com/omnipad-js/omnipad>
commit `c91b3828`（2026-09-05），包 `@omnipad/vanilla@0.7.3`，MIT。
按仓库 README 的「tag 引入」方式接入，只把 unpkg 的 UMD 与 CSS 换成本地内联
（App 内没有外网 CDN）：

| 文件 | 大小 | SHA-256 |
| --- | --- | --- |
| `vendor/omnipad-0.7.3.global.js` | 69,902 | `9aa2a5dd…e54928` |
| `vendor/omnipad-0.7.3.css` | 9,937 | `57f9f547…9cc9b2` |

许可证见 `vendor/LICENSE-omnipad.txt`。

### 挂了什么（`shell.html` 第 5 段）

| 组件 | 作用 |
| --- | --- |
| `TargetZone`（`$stage`，`cursorEnabled`） | 吸附在 `#wrap` 上的靶区，把触点翻译成 canvas 上的 `PointerEvent`（`pointerType:'mouse'`、`composed:true`）+ 对应 `MouseEvent`，穿透 Ruffle 的 Shadow DOM；单指点哪就点哪 |
| `VirtualTrackpad`（`$pad`） | 黑边里的触控板：拖动 = 只移动光标（悬停菜单因此能停住），轻点 = 在当前光标处按下并松开 |

- 落点优先占黑边（左右 ≥104px 用竖条，否则上下横条），都放不下才压右下角 168×112 浮层
- 每秒校验一次落点，转屏 / 影片分辨率校正后自动重贴
- 挂载门禁：必须「`<ruffle-player>` + 其 shadow root 里的 `canvas`」都存在才挂，否则 500ms 后重试，30s 放弃并保持原生触控
- OmniPad 解析失败（内核过旧）时只打一条日志，游戏照常可玩

### 退路 / 调试口子

```js
__molePad.state()   // { mounted, layout, omni }
__molePad.off()     // 立即拆掉图层，恢复原生触控
__molePad.on()      // 重新挂上
__moleClock()       // 时间轴钳制统计
```

调灵敏度：`__molePad` 建立后，触控板实例的 `updateConfig({ sensitivity })`；
默认 `0.6`（满幅拖动 ≈ 舞台宽度的 60%）。

---

## 三、验证（离线，未真机）

```bash
cd <工作区>/bugfix
node verify/clock_test.js dec-105/assets/ruffle/shell.html   # 19 项
node verify/pad_test.js   dec-105/assets/ruffle/shell.html   # 41 项
```

两套都是**从 shell.html 里切出真实代码**跑的，不是复制一份改着测。

`clock_test.js` 覆盖：平时 1:1 不改变节奏、300s 挂起后只进 1 帧、
阈值边界（800/801ms）、时间戳回退、钳制后帧间隔仍落在 33.3~50.1ms。

`pad_test.js` 覆盖：等待「播放器+画布」才挂载、20:9 / iQOO Neo9 / 18:9 落右侧黑边且不覆盖舞台、
4:3 平板落底部、铺满屏幕时退回角落浮层、转屏后重贴、暂停态兜底 play、
`off()` 拆图层、OmniPad 缺席时安全降级。

**仍未做真机验证**（无设备）。建议观察：

1. 挂机 10 分钟 → 切后台 3 分钟 → 返回：看是否还有 `长间隔 …` 日志、是否被踢
2. 悬停菜单：用右下（或右侧黑边）触控板把光标移到菜单上，看子菜单是否停住，再轻点确认
3. 走路/点 NPC：直接点舞台应当和 1.0.3 一样
4. 若舞台变得点不动：`__molePad.off()` 可立即恢复原生触控

---

## 四、回滚

1.0.3 的壳层在 `patches/1.0.3/shell.html`；把 `shell.html` 换回 1.0.3 版、
`apktool.yml` 的 versionCode/versionName 改回 4 / 1.0.3 重新打包即可。
