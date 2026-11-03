# 1.1.2-beta — 画质（渲染分辨率）、软键盘防抖、英文字母开关

基线：**1.1.1-beta** 的代码工作区（含 1.1.2~1.1.5 的后台冻结 / 保活 / 通知修复）。
本版号 `1.1.2-beta`（versionCode 16，需大于已装测试包的 15 才能覆盖安装）。
只改了 `assets/ruffle/shell.html` 一个文件，Java 壳层一行未动。未推 GitHub。

---

## 1) 画质：把渲染分辨率从「欠采样」拉回「屏幕原生像素」

### 根因（1.1.1-beta 自己引入的回归）

1.1.1-beta 的目标像素是「实际显示面积 × 1.44」，并用
`Math.max(eff, BUDGET * 0.4)` 兜底。这条兜底在手机上把分辨率直接打回 0.4 档：

```
横屏 800x360（CSS）：舞台显示 617x360 = 22.2 万 CSS px
  eff  = max(22.2万 × 1.44 = 32万, 90万 × 0.4 = 36万) = 36万
  DPR  = sqrt(36万 / 53.76万) = 0.818
  canvas 786x458  ——  要铺满 2160x1260 个物理像素
  放大 2.75 倍 → 糊
```

竖屏同理：canvas 786x458 对应 1260x735 物理像素，放大 1.60 倍。
**这就是「画面发糊、画质变差」的真正原因：不是 quality，是渲染分辨率不够。**

### 修法

```
nativePx = shownArea × DPR²                 // 屏幕原生像素，上限
want     = max(shownArea × 1.44, BUDGET)    // 基准档，不低于它
eff      = min(nativePx, want, BUDGET×1.6, MAXPIX)
```

三条约束的含义：

1. **原生像素是上限** —— 超过它纯属超采样，显存照付、肉眼看不出；
2. **BUDGET（Java 按崩溃历史分档注入）是基准** —— 不再低于它，恢复 v1.1.0 的观感；
3. `BUDGET × 1.6` 与 `MAXPIX` 仍是硬顶，GPU 看门狗降档照旧生效。

同时把 `devicePixelRatio` 的原始值提前到 0.2 段开头捕获 —— 因为段末会给
`window.devicePixelRatio` 装 getter，装完之后再读就是「自己算自己」。

### 实测换算（BUDGET = 90 万）

| 设备 | 旧 canvas | 新 canvas | 物理像素 | 放大率 |
| --- | --- | --- | --- | --- |
| 手机 横屏 800x360 | 786×458（36万） | **1242×725（90万）** | 2160×1260 | 2.75× → **1.74×** |
| 手机 竖屏 360x800 | 786×458（36万） | **1242×725（90万）** | 1260×735 | 1.60× → **1.01×** |
| 16:10 平板 1280x800 | 1536×896（137.6万） | 1536×896（137.6万） | 2560×1493 | 1.67× → 1.67×（不变） |
| 4:3 平板 1024x768 | 1229×717（88.1万） | 1242×725（90万） | 2048×1195 | 1.65× |

即「大屏上白花的像素」不再增加，手机端把预算用满：显存差额只有一块
**1242×725 RGBA 后备缓冲 ≈ +2.06MB**（1.37MB → 3.43MB），占整机 RSS 约 0.2%；
纹理池、音频缓冲、wasm 堆、DOM 全部未变，Java 注入的预算档位也没有调大。

### 为什么**没有**动 `quality`

Ruffle 源码里 `StageQuality` 只映射到 MSAA 采样数：

```rust
pub fn sample_count(self) -> u32 {
    Low => 1, Medium => 2, High => 4, Best => 4, ...
}
```

`Surface::new()` 用它开多重采样渲染目标 —— `quality: 'low' → 'high'` 会让
渲染目标显存直接 ×4，与「内存占用不变」正面冲突，而且它只影响边缘抗锯齿，
对「糊」没有任何改善（`quality.rs` 的注释也写明：该设置当前在 Ruffle 中
除采样数外无其它效果）。所以这一版不碰它。

**没动**：`#wrap` 尺寸与 `transform: scale(f)`（画幅）、帧率 24、rAF 节流器、
`quality`、服务器地址、OmniPad 布局。

---

## 2) 软键盘输入防抖 + 暂时关闭英文字母

### 根因（Ruffle web 播放器 × Android 输入法）

Ruffle 的虚拟键盘是一个 1px 透明的 `<input id="virtual-keyboard">`，
它把 `input` 事件里 `value` 的**每一个字符**拆成 keydown + keyup 派发，
然后清空 value：

```js
virtualKeyboardInput() {
  let v = this.virtualKeyboard.value;
  for (let ch of v)
    for (let t of ["keydown","keyup"])
      this.element.dispatchEvent(new KeyboardEvent(t, { key: ch, bubbles: true }));
  this.virtualKeyboard.value = "";
}
```

Android 输入法在**组合（composing）未结束**时，`value` 里是「到目前为止敲下的
整段拼音」；而把 value 置空并不能重置输入法的组合缓冲（InputConnection 会把
它同步回来）。于是每敲一个键就把全部内容重发一遍：

```
w → wo → woa → woa n …   层层叠加
```

落到游戏里就是 `wwwwooooooooaaaaaannnnnnnnniiiiiiiiiiiii`。
中文输入法打拼音时最明显 —— 而且那些拼音字母本来也不该进游戏。

### 修法（只拦截，不改 Ruffle、不改游戏逻辑）

在 **host（`ruffle-player`）的捕获阶段**拦下 `#virtual-keyboard` 的 `input` 事件，
早于 Ruffle 挂在 input 元素上的监听，派发权收回自己手里：

1. `stopImmediatePropagation()` —— 永远不让 Ruffle 自己那段重发逻辑跑；
2. **只派发增量**：输入法把旧内容又带上来时，用前缀 diff 取新尾巴；
3. **组合期间一个字都不派发**，等 `compositionend` 拿到汉字再派发；
   组合期间也绝不置空 value（否则输入法被打断）；
4. **暂时屏蔽英文字母** a-zA-Z（就是「暂时关闭英文字母」），
   恢复：`__moleKb.latin(true)`；
5. 防抖：同字符 35ms 内重复只算一次；100ms 内超过 8 个字符的突发直接丢弃；
6. 退格 / 删除（value 变短且是老值前缀）只更新状态，绝不把剩余字符重发；
7. 播放器或隐藏输入框被重建时自动重新绑定（轮询补挂）。

退格、回车、方向键走键盘事件通道，不经过这个 input，不受影响。

### 现场开关

```js
__moleKb.latin(true)   // 恢复英文字母
__moleKb.state()       // { latin, composing, hooked, value }
```

logcat 搜 `MoleShell`，出现 `软键盘防抖已挂载（英文字母=关）` 即生效。

---

## 验证

- 内联脚本 `node --check` 通过（3 个 script 块）。
- 键盘逻辑用真实代码 + DOM 桩跑过 6 组用例：
  英文累积（0 派发）、拼音组合期（0 派发）、`compositionend` 提交「蜗牛」、
  回声去重、退格（0 重发）、同字符洪泛（≤2 次）、`latin(true)` 放行。
- 包内核验：versionCode 16 / `1.1.2-beta` / sdk 21 / targetSdk 31 / compileSdk 35；
  `assets/ruffle/shell.html` 与源文件逐字节一致（165,130 B）；
  1.1.2~1.1.5 的壳层修复（`startForegroundService` / `onUserLeaveHint` /
  `onRenderProcessGone` / `setRendererPriorityPolicy`）全部还在。
