# 1.1.1 壳层补丁 —— 后台节拍器换成音频时钟

本目录只归档 `assets/ruffle/shell.html` 一份文件。1.1.1 相对 1.1.0
的**全部**差异都在这个文件里：`classes.dex`、`AndroidManifest.xml`、
`ruffle.js`、两份 `*.wasm.gz` 全未改动。

## 用户报的两个问题

1. 后台挂机时游戏内置音乐出现**严重爆破音**
2. 仍然因为**数据包对不上**被服务器踢出

## 一条根因

`ruffle.js` 里 `startBackgroundTick()` 现场拼一个 Worker：

```js
const intervalMs = 1000 / (this.metadata?.frameRate || 24);   // 41.67
self.onmessage = () => { setTimeout(() => self.postMessage("tick"), intervalMs); };
setTimeout(() => self.postMessage("tick"), intervalMs);
```

主线程：

```js
c.onmessage = () => {
  this.backgroundWorker === c &&
    (this.instance?.tick_for_background(performance.now()), c.postMessage("ack"));
};
```

它假定「Worker 里的 `setTimeout` 不受页面可见性节流」。**这个假定是错的。**
页面 `hidden` 之后，Chromium 对 Dedicated Worker 的 timer 同样施加 1 秒下限
（进入 intensive throttling 后更慢）。所以真正喂进 core 的 `dt` 一秒起步。

`core/src/player.rs` 的 `Player::tick` 拿到这个 dt 后：

```rust
self.frame_accumulator += dt;                       // +1000ms
while frame < max_frames_per_tick && acc >= frame_duration { run_frame(); }
if self.frame_accumulator >= frame_duration {
    self.frame_accumulator = FloatDuration::ZERO;   // 剩余 792ms 丢掉
}
...
self.update_timers(dt);                             // 一次补跑 10 个定时器
...
self.audio.tick();                                  // 一次生成 44100 个样本
```

三条后果正好对上两个现象：

| 路径 | 后果 | 对应现象 |
|---|---|---|
| 累加器归零，每秒只走 5 帧（208ms） | 逻辑时间落后真实时间约 79%，`getTimer()` 变慢 | 包时间戳滞后 → 被踢 |
| `update_timers(1000)` 一次跑 10 个 | 心跳/动作包同毫秒连发 | 顺序错乱 → 被踢 |
| `audio.tick()` 一次 44100 样本 | WebAudio 队列错位、环形缓冲互相覆盖 | 爆破音 |

## 改法

节拍权从 Ruffle 手里收回，时间轴换成壳层自维护的合成轴 `bg.ts`，
**每拍只推一帧**（恒 41.666ms）：

```
enterBackground
  ├─ disarm(player)           startBackgroundTick → 空函数（Worker 不再创建）
  ├─ enable_background_tick_mode()   取消 rAF、置后台标志
  ├─ keepAudio(ctx)           state !== running 就 resume，并挂 statechange 自愈
  ├─ setInterval(pump, 50)    兜底节拍
  └─ startWorklet(ctx)        AudioWorklet 24Hz（音频线程，不受页面节流）

pump()
  n = floor((now - bg.ts) / 41.666)，cap 120
  for n: bg.ts += 41.666; instance.tick_for_background(bg.ts)
```

两个节拍源都只是「叫一下 `pump()`」，`pump` 自己按 `performance.now()`
算欠几帧，天然幂等。worklet 在跑时定时器算出来是 0；worklet 挂了定时器独撑。

## 顺带修掉的三处隐患

- **双节拍器打架**：Ruffle 的 hidden 分支会 `startBackgroundTick()`，
  壳层也在推，一个喂 `performance.now()`、一个喂合成轴，`dt` 正负横跳。
  现在 Worker 根本不会创建（`__moleBg().worker === false`）
- **回前台双倍速**：Ruffle 的 visible 分支和壳层各调一次
  `restart_animation_loop()`，rAF 队列里两个同样的 handler，一帧推两帧逻辑。
  §0 的 `requestAnimationFrame` 现在对同一回调去重
- **`__moleAlignClock()` 把欠账一次性喂给 core**：原实现回前台把 `vTs`
  对齐到真实 rAF 戳，后台若被冻结过就是几秒的 `dt`，补帧风暴重演。
  现在接收合成轴最后一帧，从 `bg.ts + 41.67` **接续**

## 没动的

画幅 `960x560` / `letterbox`、`frameRate 24`、`quality low`、DPR 预算、
节流器、服务器地址与端口池、Ruffle 二进制 —— 全部原样。

## 验证

```bash
node tests/clock_test.js     # 36 项
node tests/bg_test.js        # 43 项
node tests/pad_test.js       # 96 项
```

共 175 项，全绿。`bg_test.js` 的主心骨只有一条：

> 相邻两次喂给 `tick_for_background` 的时间戳差恒等于 41.666ms，
> 不论节拍器被节流成多慢、单轮补多少帧。

## 真机自查

```bash
adb logcat -s chromium:V | grep MoleShell
```

正常应看到：

```
[MoleShell] 已接管后台调度：Ruffle 的 setTimeout Worker 不再启用
[MoleShell] 进入后台：固定步长 41.67ms 推进（音频上下文=running）
[MoleShell] 后台节拍器：AudioWorklet（音频线程 24Hz，不受页面节流）
[MoleShell] 回到前台：后台推进 N 帧 / 墙钟 Xms（单轮最多 M 帧，节拍器=worklet）
```

若出现 `AudioWorklet 加载失败，降级到定时器`，说明内核不支持 worklet，
此时按 setInterval 的节奏走，逻辑仍然正确，只是后台 CPU 占用会高一些。

运行时也可以直接读：

```js
__moleBg()
// {on, hidden, mode:'worklet', ticks, catchup, ts, audio:'running',
//  disarmed:true, worker:false, playing:true}
```
