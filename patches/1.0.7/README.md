# 1.0.7 补丁 —— 触控板挪进屏幕右侧黑边（不再压游戏画面）

基线包：`mole-1.0.6.apk`（10,306,948 B，SHA-256 `1811bc92…b2a740`）
产物：`mole-1.0.7.apk`（10,311,044 B，versionCode 8 / versionName 1.0.7）
SHA-256：`7cb3408adb66b8a61bf1ce72236ba377834d9e7630c6faefde099363b0005c8b`

本次只动落点几何与可见性，**游戏本体一行未改**：帧率 24、quality low、
画幅 960x560、节流器、服务器地址、时间轴钳制、后台保活、OmniPad 的
靶区与灵敏度 0.6，一律未动。`classes.dex` 字节级未变。

---

## 一、根因：1.0.6 为什么几乎肯定掉进右下角

1.0.5 / 1.0.6 的判据是：

```js
var MIN_MARGIN = 104;   // 黑边窄于这个值就不往里塞，改用角落浮层
```

这个 104 是照着**物理像素**估的（2400x1080 的机器、左右各 274px）。
但 WebView 里 `window.innerWidth` 是 **CSS px**：

| 机型 | 物理 | DPR | CSS 视口 | 12:7 舞台 | 单侧黑边 |
| --- | --- | --- | --- | --- | --- |
| iQOO Neo9 横屏 | 2800x1260 | ≈3.5 | 800x360 | 617x360 | **91px** |
| 常见 19.5:9 | 2340x1080 | 3 | 780x360 | 617x360 | 81px |
| 常见 18:9 | 1080x2160 | 3 | 720x360 | 617x360 | 51px |
| 16:9 | 1920x1080 | 3 | 640x360 | 617x360 | 11px |

91 < 104 → 右侧不满足，左侧同理，上下黑边为 0 → 直接落到
`FALLBACK_LAYOUT = {right:10px,bottom:10px,168x112}`，也就是压在
游戏右下操作区上的那块板子。**这不是偶发，是每台真机都必然。**

> 窗口比例越接近 12:7，黑边越窄；只要 `vw/vh > 1.714`，黑边
> = `vw·(1 − 1.714·vh/vw)/2`。所以判据必须按视口比例算，不能写死像素。

---

## 二、新规则（1.0.7）

```js
var EDGE_GUARD = 20;   // 让开系统边缘手势区（Android 默认 20dp ≈ 20 CSS px）
var STAGE_GAP  = 6;    // 与舞台留缝，不贴游戏画面
var MIN_BAR    = 44;   // 板子窄于此值就不做
var MAX_BAR    = 220;  // 竖条最宽
var PAD_RATIO  = 0.93; // 高/宽
var MIN_H      = 96;
```

判定顺序：**右 → 左 → 下 → 上 → 不挂**。

```
竖条（右侧/左侧）：
  avail = 黑边 - 20 - 6
  avail < 44            → 换下一条边
  w = min(avail, 220)
  h = clamp(w / 0.93, 96, vh * 0.5)
  距屏幕边 = 20 + (avail - w) / 2      ← 保证不侵入系统返回手势区
  垂直居中

横条（下侧/上侧，4:3 平板 / 分屏）：
  avail = 黑边 - 20 - 6
  h = min(avail, 150)
  w = max(190, h / 0.93)    且不超过 vw/2
  水平居中
```

### 为什么板子刻意做成「接近正方」

`TrackpadCore.processInput()` 的位移换算是以**板子自身**的矩形为基准：

```ts
const deltaX = (dx / rect.width)  * 100 * sensitivity;
const deltaY = (dy / rect.height) * 100 * sensitivity;
```

板子又窄又长（比如 65x330）会让竖直方向每像素对应的光标位移只有水平的
1/5，手感直接废掉。所以高度按 `w / 0.93` 推、并夹在 `[96, vh/2]`，
真机上横竖两个方向的移动速度基本一致。

### 各档实际落点（CSS px）

| 视口 | 右黑边 | 结果 | 板子 |
| --- | --- | --- | --- |
| 800x360（iQOO 20:9） | 91 | 右侧 | 65x96，right 20，top 132 |
| 780x360（19.5:9） | 81 | 右侧 | 55x96，right 18 |
| 720x360（18:9） | 51 | **不挂** | — |
| 1024x768（4:3 平板） | 下 85 | 底部 | 190x59，bottom 20 |
| 640x360（16:9） | 11 | **不挂** | — |

---

## 三、没有黑边时：不挂板子，绝不压画面

`computeLayout()` 返回 `null` 时，`applyLayout()` 会把触控板
`destroy()` 掉，**只保留 TargetZone**（点哪走哪，等于原生单击），
并把 `#pad` 整体设为不可见。1.0.6 那种「168x112 浮层压右下角」的
兜底默认关闭。

需要悬停菜单的满幅机器，显式打开：

```js
__molePad.corner(true)    // 在右下角强行开一块（会压住一小块画面）
__molePad.corner(false)   // 关掉
```

转屏 / 分屏 / 影片分辨率校正后，`applyLayout()` 每秒重算一次：
从「有黑边」转到「满幅」会拆板子，转回来会自动重建 —— 不会留下一块
在错误位置的板子。

---

## 四、可见性：黑边里显示，压画面时隐藏

```css
#pad.pad-invisible .omnipad-trackpad{opacity:0!important;}
```

- 落在黑边（right/left/bottom/top）→ **可见**。那里本来就是黑的，
  看得见才找得到位置；面板半透明 + 虚线框 + 标签，不挡游戏。
- 落在角落兜底（zone=corner）或用户手动关 → `opacity:0`。
  用 opacity 而不是 `display:none`/`visibility:hidden`：后两者会让元素
  退出命中测试，拖动手势当场失效；`opacity:0` 照样收 pointer 事件。

开关（只碰外观，不碰命中）：

```js
__molePad.trackpad('off')    // 隐藏（交互保留）
__molePad.trackpad('auto')   // 回到默认策略
__molePad.state()            // {mounted, layout, zone, trackpad, trackpadVisible, omni}
```

---

## 五、改动清单

```
assets/ruffle/shell.html      136,131 → 141,415
  · 第 5 段 5.1  computeLayout 重写：CSS px 自适应 + 右/左/下/上优先级 + 无黑边返回 null
  · 第 5 段 5.2  新增 applyLayout / createPad / destroyPad / setVisual（建、移、拆一体）
  · 第 5 段 5.3  __moleAfterResume 走 applyLayout（原来走 reflow）
  · __molePad     新增 corner(v)；trackpad() 语义改为 auto/off；state() 增加 zone/trackpad
  · 删除        MIN_MARGIN(104)、FALLBACK_LAYOUT 默认兜底、mount 内的重复建板
  · CSS         注释更新（1.0.7 起只在压画面时才用 pad-invisible）
AndroidManifest.xml            版本号 7 / 1.0.6 → 8 / 1.0.7
META-INF/*                     重新签名（证书 974EA1B9… 与 1.0.1~1.0.6 同源）
```

`classes.dex`、`ruffle.js`、`core.ruffle.*.wasm.gz`、`mole_boot.js`、
OmniPad 的 UMD/CSS **字节级未变**。

---

## 六、离线验证

```bash
node verify/pad_test.js    dec-105/assets/ruffle/shell.html   # 96 项
node verify/clock_test.js  dec-105/assets/ruffle/shell.html   # 27 项
node verify/bg_test.js     dec-105/assets/ruffle/shell.html   # 34 项
```

`pad_test` 全部是**从 shell.html 里切真实代码**跑的，不复制：

- 真机 CSS 视口 800x360：黑边 91 → 板宽 65、高 96、right 20、top 132，
  且断言 `right + width ≤ 黑边`（一个像素都不进舞台）
- 大视口 20:9 / 18:9 / 4:3：宽度公式、高宽比 0.9~1.15、离屏边 ≥20px
- 满幅 960x560 与 16:9 640x360：**不创建触控板**、靶区照建、图层不可见
- `corner(true)` 建 168x112 且强制不可见；`corner(false)` 拆掉
- 转屏往返：右黑边 → 满幅拆板 → 转回自动重建（实例数 1→2）
- 画幅变化只 `updateConfig` 一次，布局没变则完全不调

`clock_test`（时间轴钳制）与 `bg_test`（后台保活）作为回归，全过。

---

## 七、真机验证建议

1. 进游戏后，右侧黑边里应当出现一块半透明的虚线板（iQOO 20:9 约
   65x96，位于屏幕右缘内 20px、垂直居中）。
2. 在板子上拖动 → 光标移动，悬停子菜单能停住；轻点 → 在光标处确认。
3. **重点**：在游戏画面右下角连点几下（走路、点 NPC、商城按钮），
   应当与 1.0.6 之前一样灵敏 —— 那块 168x112 的浮层已经不再存在。
4. 从屏幕最右缘向内划，应当**退出/返回**（说明手势区没被侵占）；
   在板子上拖动则不应触发返回。
5. 若机身是 18:9（CSS 视口约 720x360），黑边只有 51px，本版**不挂板子**，
   logcat 会有 `本机四边都没有可用黑边：只提供靶区…`；
   这种情况下 `__molePad.corner(true)` 可换回角落兜底。

诊断口子：`__molePad.state()` → `zone` 告诉你板子落在哪条边。

---

## 八、代价与边界

- **18:9 及更窄的机型不挂板子**：黑边 51px 扣掉 20px 系统手势区 +
  6px 舞台缝只剩 25px，做出来按不准，还不如不做。可用 `corner(true)` 换回。
- **板子偏小**：65x96 的板子拖动行程短，灵敏度仍是 0.6，
  一次满幅拖动 ≈ 舞台宽的 60%。若觉得太灵/太钝，改 `sensitivity`
  即可（不动几何）。
- **仍需要一个手势区**：Android 从屏幕边缘 20dp 内起划会触发系统返回，
  这段空间是硬扣的，任何"铺满整条黑边"的方案都会和它打架。

## 回退

```js
__molePad.off()          // 整个图层拆掉，回到原生触控
__molePad.corner(true)   // 角落兜底（1.0.6 的位置）
```
