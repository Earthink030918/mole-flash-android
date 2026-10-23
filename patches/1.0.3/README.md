# 1.0.3 补丁：长跑卡死 + 边缘手势回归

基线：`mole-flash-android-1.0.1.apk` + 1.0.2 的 7 处补丁（全部保留）。
本版只动两件事，**画面、画幅、帧率、24fps 节流器、像素预算数值、服务器 IP 一律未改**。

---

## 一、安卓边缘手势失效（1.0.2 引入的回归，已撤销）

**触发点**：`MainActivity$6.onPageFinished()`

1.0.2 在这里调用了：

```java
web.setSystemGestureExclusionRects(Arrays.asList(
    new Rect(0, 0, width * 3 / 100, height),
    new Rect(width - width * 3 / 100, 0, width, height)));
```

**为什么错**：这个 API 的语义是「这块区域**不要**给系统手势用」。一旦申请，
系统在左右各 3% 宽度内就不再响应「返回 / 回桌面」，用户进游戏后左右滑动退不出去。
它是全局副作用，与用户点的是哪个按钮无关——影响面比原来「偶尔点不中贴边按钮」大得多。

**修法**：整段删除，不申请任何排除区，恢复系统默认。贴边按钮的命中问题
交给壳层的输入加固段（多指锁 + 视口缩放复位）处理，那部分不占用系统手势区。

**验证**：新 dex 的字符串池里 `setSystemGestureExclusionRects` 已完全消失。

---

## 二、长跑之后直接卡死

**触发链**（两处，同一个根因）：

| 位置 | 1.0.2 的行为 |
|---|---|
| `MainActivity$1`（显存看护，3s 采样） | 显存 ≥400MB / ≥410MB → `raiseLoadLevel(loadLevel+1)` |
| `MainActivity$JsBridge$3`（WebGL 上下文丢失） | `lost` → `raiseLoadLevel(+1)`；`dead` → `raiseLoadLevel(MAX_LEVEL)` + `reload()` |

**根因**：`raiseLoadLevel` 是靠**降低像素预算**换显存，两个致命问题：

1. **它改的是画质**。每越闸一次降一档，用户能直接看出画面变糊，
   而 `PIXEL_BUDGETS` 只有 6 档（`MAX_LEVEL=5`）。
2. **到顶之后完全失效**。`raiseLoadLevel` 内部有
   `if (newLevel <= loadLevel) return;`，档位到 5 以后越闸就**什么都不做**——
   显存一路涨到驱动分配不出来。此时驱动不会崩进程，而是让 WebGL 上下文
   反复丢失/重建、渲染线程空转：画面冻死，但 CPU 侧一切正常，
   `dumpsys` 里看不到崩溃，ANR 也抓不到。这就是「为了不重启，跑久了直接卡死」。

另外 `dead` 分支那句 `raiseLoadLevel(MAX_LEVEL)` 还会**把降档永久写进配置**：
`reload()` 之后 `evaluateLoadLevel()` 从 `boot_crashes_v4` 读回这个高值，
画质越用越糊，而且只能靠「连续 2 次平稳启动回升一档」慢慢爬回来。

**修法**：引入**无损纹理回收**，不再动预算。

### 2.1 壳层新增 `__molePurgeTex()`（`src/web/shell.html`）

```js
window.__molePurgeTex = function (minGapMs) { ... }   // 默认 240000ms 冷却
```

它复用 0.3 段已有的重建机制：让 `#wrap` 做一次「+1px → 下一帧回原位」的跨帧抖动，
Ruffle 的 ResizeObserver 因此重建渲染目标，旧 canvas 的后备缓冲随上下文丢弃，
驱动侧那块纹理内存归还；而 **AVM2 里的游戏状态、已建立的 Socket、登录态全部保留**
——玩家看不到掉线，也看不到黑屏，只有一帧的 1/960 尺寸变化。

配套给 `__moleSetBudget(px, force)` 加了第二个参数：`force=true` 时跳过
`if (px === BUDGET) return true;` 的早退，实现「预算不变也重建」。

### 2.2 Java 侧三个调用点改为调它

- `MainActivity$1` 硬闸（410MB）/ 软闸（400MB）→ `evaluateJavascript("__molePurgeTex()")`
- `MainActivity$JsBridge$3` 的 `lost` 分支 → `__molePurgeTex(30000)`（紧急信号，冷却缩到 30s）
- `MainActivity$JsBridge$3` 的 `dead` 分支 → **删掉 `raiseLoadLevel(MAX_LEVEL)`**，
  只保留 `reload()` 兜底（上限 8 次）

改完后 `raiseLoadLevel` 在整个 app 里**没有任何调用点**，运行期不会再自动降画质；
启动时的分档（`evaluateLoadLevel`）和自动回升机制保持原样。

---

## 三、为什么这样改不会碰游戏本体

- `ruffle.js`、`core.ruffle.*.js`、两个 `*.wasm.gz`、`mole_boot.js` 字节级未变
- `PIXEL_BUDGETS` 数值、`devicePixelRatio` 钳制公式、`--f` 等比缩放、24fps 节流器未变
- Ruffle 配置项（`frameRate:24` / `quality:'low'` / `letterbox:'on'` / `scale:'showAll'` /
  `preferredRenderer` / `deviceFontRenderer`）未变
- 服务器 IP / 端口池 / `socketProxy` 注入逻辑未变
- 1.0.2 的 S1/S2/S3（socket 线程泄漏）、T1（缩放开关）、C1（缓存白名单）全部保留

---

## 四、本地验证（无真机，用 mock 跑壳层逻辑）

`bugfix/verify/purge_test.js` + `fit_seg.js`，20 项断言全部通过：

- DPR 按 1210000px 预算钳制到 1.500（物理 3.5），预算生效
- 同预算普通调用仍早退（1.0.2 行为不变）
- `force` 调用产生 `["961px","960px"]` 抖动序列，rAF 后复位
- 预算常量与 DPR 钳制值在 purge 前后**完全一致**（画质不变的直接证据）
- 冷却：1s 后拦、239.999s 仍拦、满 240s 放行、放行后立即又拦
- 不传参数默认 4 分钟冷却
- `NaN` / 负值 / 0 预算被拒绝，不会打断渲染循环

---

## 五、遗留

- 鸿蒙端（`harmony/`）未同步：它的 `Index.ets` 没有显存看护逻辑，也不存在
  `setSystemGestureExclusionRects`，本次两个问题都不适用。若后续要给鸿蒙也加
  长跑回收，在 `Index.ets` 里定时 `runJavaScript("__molePurgeTex()")` 即可，
  壳层函数已就位。
- 若设备在 1.0.2 期间已被降到低档，装 1.0.3 后画质会按「连续 2 次平稳启动回升一档」
  自动爬回；想立刻恢复默认档，清除应用数据即可。
