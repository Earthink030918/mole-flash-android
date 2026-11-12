# 1.1.9-beta —— 修「一进游戏全屏马赛克」（像素预算地板）

基线 1.1.8-beta（versionCode 22，ruffle 三件套换成本轮新编译）→
本版 **1.1.9-beta**（versionCode 23）。
只改 `src/web/shell.html`，**引擎三件套一个字节没动**，画幅 / 帧率 / 节流器 /
输入法守卫 / 回收机制全部未动，Java（smali）未改。

产物：`mole-1.1.9-beta.apk`，10,343,812 B，
SHA-256 `82827a375f37ff86dd77508170d5a8735d0b8a179f9741998c64c704b92a0dff`，
证书 `974ea1b9…0093`（同 v1.1.0，可覆盖安装）。

---

## 现象

换上新城引擎（`ruffle.js` + `MK7STBFJ` / `JTCYPQ5T` 两个 wasm）后，
**一进游戏就是整屏马赛克**，块状明显，不是"略糊"。

时间上和"换引擎"完全重合，所以第一反应都会怀疑引擎。**不是引擎。**

## 定位（三处证据，逐条可复查）

1. **画质档位 `quality` 与分辨率无关。**
   `core/src/display_object/stage.rs::set_quality()` 只做三件事：
   存值 → `use_bitmap_downsampling`（注释写明 "currently ignored in Ruffle"）
   → `context.renderer.set_quality()` 请求重绘。**没有任何 width/2、
   render_scale 之类的路径。** 所以 `quality: 'low'` 不是元凶。

2. **分辨率只有一个来源：`canvas.client_width * devicePixelRatio`。**
   `web/src/lib.rs::tick()`。壳层把 `devicePixelRatio` 钳成 `compute()` 的返回值，
   所以画质 = 预算的单调函数。

3. **预算被"连崩次数"打到了最低档。**
   `MainActivity.evaluateLoadLevel()`：

   ```smali
   CrashProbe.recentCrashStreak()  →  loadLevel = min(streak, MAX_LEVEL)
   pixelBudget() → PIXEL_BUDGETS[loadLevel]
   ```

   `PIXEL_BUDGETS` 六档 = 1,210,000 / 900,000 / 660,000 / 460,000 / 320,000 / 210,000。
   换引擎前后那几次红屏 panic + 手动杀进程，把 streak 顶到 4~5，
   预算 = 210,000：

   ```
   byBudget = sqrt(210000 / (960×560)) = 0.625
   DPR 上限 = min(0.625, …) ≈ 0.79
   canvas  = 759×443      ← 要铺满 2304×1344 的显示区
   物理放大 = 2560 / 759 = 3.37 倍   ← 这就是"马赛克"
   ```

   旧版看起来正常只是因为它跑在档位 0/1（1.21M / 900k）。

## 改法（一处计算，四个常数）

`budgetNow()` 里给"参与算 DPR 的预算"加地板：

```js
var base = Math.max(BUDGET, BUDGET_MIN);   // BUDGET_MIN = 1210000
```

- `BUDGET`（Java 档位 / 运行时显存看护推送）**照旧往下走**，
  只是不能把渲染分辨率拖进"马赛克档"；
- `__moleSetBudget(BUDGET, true)` 的"改容器尺寸 → 重建渲染目标"路径不变，
  **无损纹理回收能力不受影响**（它只换渲染目标，不依赖预算数值）；
- `DENSITY 1.44 → 1.7`、`MAXPIX 160万 → 220万`、`FLOOR 0.5 → 0.7`：
  在"画幅不变"的前提下把大屏该有的像素补回来。

### 数值效果（960×560 舞台，平板按 1280×800 CSS / DPR 2 模拟）

| 场景 | 预算 | 目标像素 | DPR | canvas | 物理放大 |
| --- | --- | --- | --- | --- | --- |
| 现状（档位 5） | 210,000 | 336,000 | 0.79 | 759×443 | **3.37×** |
| 1.1.7 基线（档位 1） | 1,210,000 | 1,376,256 | 1.60 | 1536×896 | 1.67× |
| **1.1.9（档位 5 + 地板）** | 1,210,000 | 1,624,747 | 1.74 | 1669×974 | **1.53×** |

手机（915×412 CSS / DPR 2.625）：`1242×725 → 1440×840`，
物理放大 `1.49× → 1.29×`，且仍低于屏幕原生像素上限。

## 新增的一行诊断

启动 3s 后打一次（不轮询、不改行为）：

```
[MoleShell] 渲染实况 budget=…（生效 …） DPR=… canvas=宽x高 元素=宽x高 显示=宽x高
```

`canvas / 元素` 的比值 > 1.6 就是肉眼可见的发虚，> 2.5 就是马赛克。
下次再有画质问题，看这一行就能定性，不必再猜。

## 回归

`tests/` 四套全绿：text 24 / panic 34 / clock 34 / bg 54 = **146 项全过**。
