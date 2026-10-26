# 1.1.2 补丁：后台改为「逻辑 + 音频原子冻结」

> 基线：**v1.1.0 的 `shell.html`**（141,415 B，与本目录 `../1.1.0/shell.html` 一致）。
> 不是 1.1.1 的补丁叠加 —— 1.1.1 那条路经真机验证不成立，已放弃。

## 症状

1. 切到后台再切回来，声音有严重的爆破音
2. 回来的瞬间画面卡顿
3. 后台挂久了，应用自己崩溃

## 根因（三条，都能在源码里对上）

### 一、爆破音：`audio_skew_time()` 把流音硬停

`core/src/backend/audio.rs`，每个 tick 都会跑：

```rust
let stream_pos   = audio.get_sound_position(instance) / 1000.0;
let timeline_pos = (clip.current_frame() - start_frame) / frame_rate
                   + offset_ms / 1000.0;
let skew = stream_pos - timeline_pos;
if skew.abs() >= STREAM_RESTART_THRESHOLD {        // 1.0 秒
    audio.stop_sound(instance);                    // 硬切，波形中断
    self.sounds.swap_remove(i);
}
```

`timeline_pos` 由我们喂的 `dt` 决定；`stream_pos` 由「`mix()` 被调过几次」决定：

- `web/src/audio.rs` `Buffer::play()` 里才调 `mixer_proxy.mix()`
- `play()` 只由上一块 `AudioBufferSourceNode` 的 `onended` 触发
- `onended` 是**主线程**事件

页面 `hidden` 后主线程定时器被压到 1Hz，一秒内跑得到 2~3 次 `onended`，
`stream_pos` 每秒只走 92~743 ms，而 `timeline_pos` 走 1000 ms。
每秒欠 0.3~0.9 秒 → 1~4 秒必破 1.0 s 阈值 → `stop_sound` → 影片下一帧
`start_stream` 重启 → 循环。

这是 **pull 模型对主线程节流的硬依赖**，改喂法救不回来：

| 版本 | 后台喂法 | 结果 |
| --- | --- | --- |
| 1.0.6 | Ruffle 自己的 Worker（`setTimeout`） | Worker 定时器同样被节流，`dt` 一秒起步 |
| 1.1.0 | 让 Ruffle 补帧 | `frame_accumulator` 被清零，逻辑倒退 79% |
| 1.1.1 | 固定步长喂 `tick_for_background` | `timeline` 准了，`stream_pos` 照样掉队 |

### 二、卡顿：回前台第一帧 `dt` = 挂起时长

```
web/src/lib.rs      dt = 本次时间戳 − 上次时间戳（无负值保护）
core/src/player.rs  frame_accumulator += dt
                    while frame < max_frames_per_tick(≤5) run_frame()
                    update_timers(dt)          // MAX_TICKS = 10
```

一帧里连跑 5 帧逻辑 + 补跑 10 个定时器 + 重渲染。

### 三、崩溃：后台一直想跑，但主线程跑不动

后台每个 tick 都在补帧，`audio.tick()` 按 `dt` 生成样本，mixer 只能靠
`onended` 拉取；供大于求 → 样本被丢、`buffer_size` 一路翻倍到
`MAX_BUFFER_SIZE = 16384`；解码器/闭包/事件队列在 1Hz 下堆积。
再加上没有前台服务，应用进 cached 状态后会被系统冻结或回收。

## 改法

**整条链路原子冻结**，进程由前台服务保活。

`RuffleHandle` 上 `pause()` / `play()` 在 web 后端本身就是一对原子操作：

```rust
fn set_run_state(&mut self, state: RunState) {
    if play_audio { self.audio.play() } else { self.audio.pause() }
    self.run_state = state;          // Suspended → core::tick 直接 return
}
```

`AudioBackend::pause()` = `AudioContext.suspend()`。所以一次 `pause()` 就把
逻辑和音频停在同一时刻，两条时间轴一起冻结，`skew` 不再增长。

四道细节，缺一声都会「啪」：

1. **冻结前 70 ms 淡出到 0** —— `suspend()` 会在波形中途切断输出
2. **回前台先 `set_volume(0)`，`play()` 之后再 120 ms 淡回原音量**
3. **§0 的时钟在冻结期整段不推进 `vTs`、不 dispatch** —— 恢复时 `dt`
   恒为 1 个帧长，与 core 的 `last_tick` 停在哪一帧无关
4. **屏蔽 Ruffle 自己的 `visibilitychange`** —— 它回前台是**无条件**
   `instance.play()` + `audio_context().resume()`，对已经在播的流再来一次
   就是硬重启。在 `window` 捕获阶段 `stopImmediatePropagation()` 即可，
   `document` 上的监听器一个都跑不到

用 handle 的 `pause()` 而**不是** element 的 `pause()`：后者会把播放器 UI
置成暂停态，回前台会多出一个播放按钮。

## 文件

| 文件 | 改动 |
| --- | --- |
| `shell.html` | §0 时钟加冻结判断、删 `__moleAlignClock`；§5.3 `__moleAfterResume` 不再 `play()`；§6 整段重写 |
| `MoleKeepAlive.smali` | 新增。前台服务，`mediaPlayback` 类型，`START_NOT_STICKY` |
| `MainActivity.smali` | `onPause` 起服务、`onResume`/`onDestroy` 停服务 |
| `AndroidManifest.xml` | 加 `FOREGROUND_SERVICE`、`FOREGROUND_SERVICE_MEDIA_PLAYBACK`、`POST_NOTIFICATIONS`，注册 service |

## 验证

```bash
node tests/clock_test.js    # 34 项
node tests/bg_test.js       # 54 项
node tests/pad_test.js      # 96 项
```

`bg_test.js` 的主心骨：`pause()` 必须发生在最后一次 `set_volume(0)` 之后；
`leave()` 的第一件事必须是 `set_volume(0)`、第二件才是 `play()`；
Ruffle 的监听器一次都跑不到。

`clock_test.js` 的主心骨：冻结期一帧都不派发；解冻后 `dt` 有上界
（33~58 ms），绝不会等于挂起时长。

## 已知取舍

后台期间游戏逻辑是**停**的。这不是没做完，而是零爆音的前提：只要后台还在
tick，`stream_pos` 就必然掉队，1 秒内必触发 `stop_sound`。前台服务保证的
是「进程不被杀、回前台热恢复」，不保证「后台继续打怪」。

如果服务器有空闲超时，长时间挂机可能要求重新连接。
