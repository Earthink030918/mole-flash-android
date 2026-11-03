# 1.1.1-beta — 鸿蒙 4.2 的 targetSdk、平板触控、像素预算

基线：已发布的 **V1.1.0** 谱系；本版号 `1.1.1-beta`（versionCode 15，需大于
已装测试包的 14 才能覆盖安装）。未推 GitHub。

---

## 1) targetSdk 35 → 31（只动这一个）

**唯一位置**：`apktool.yml` 的 `sdkInfo.targetSdkVersion`。

```yaml
sdkInfo:
  minSdkVersion: 21        # 未动
  targetSdkVersion: 31     # 35 -> 31，只有这一行变了
```

`AndroidManifest.xml` 里没有 `<uses-sdk>`（apktool 把它剥到 yml 了），
`android:compileSdkVersion="35"` 是编译期属性，不参与运行时判定，未动。

打包后核验：

```
package: ... versionCode='15' versionName='1.1.1-beta' compileSdkVersion='35'
sdkVersion:'21'            <- minSdk 未变
targetSdkVersion:'31'      <- 只有它降了
```

**为什么能同时兼容 32/33/34/35+ 设备**：`targetSdkVersion` 只声明「应用按哪一档
行为运行」，与「能装在哪个 Android 版本」无关（后者由 `minSdkVersion` 决定）。
降档后，Android 13/14/15 设备会对本应用回退到 API 31 的兼容行为集，
因此比原来更宽松，不会因为降档而装不上或跑不起来。

需要注意的行为变化（均已在代码侧覆盖）：

| 项 | targetSdk 31 下的表现 | 现有代码 |
| --- | --- | --- |
| 通知运行时权限 | Android 13 不再强制申请，默认允许 | 已有 `requestNotifyPermission()`，targetSdk<33 时系统直接返回 granted，无害 |
| 前台服务启动限制 | Android 12+ 仍生效 | 已用 `startForegroundService()` + 5s 内 `startForeground()` |
| PendingIntent 可变性 | 必须显式声明 | 已带 `FLAG_IMMUTABLE(0x04000000)` |
| `android:exported` | 必须显式声明 | Manifest 已声明 |

---

## 2) 小米平板 5 Pro 触控

### 已确定的问题：16:10 平板根本挂不上触控板

小米平板 5 Pro：2560x1600、DPR 2 → WebView CSS 视口约 **1280x800**。
舞台 960x560（12:7）按 contain 铺满后：

```
f = min(1280/960, 800/560) = min(1.333, 1.428) = 1.333
舞台显示 1280x746.7  →  上下黑边各 ≈ 26.7 CSS px
```

旧门槛 `MIN_BAR = 44`，且要先扣 `EDGE_GUARD 20 + STAGE_GAP 6`：

```
可用 = 26.7 - 20 - 6 = 0.7 < 44  → 上、下、左、右四条边全部不合格
```

`computeLayout()` 返回 `null` → **整块触控板不挂**，只留靶区。用户看到的就是
「没有触控板 / 触控板点了没反应」。所有 16:10 平板都落在这个坑里。

### 改动

| 常量 | 旧 | 新 | 原因 |
| --- | --- | --- | --- |
| `EDGE_GUARD` | 20 | 12 | 平板手势区比手机窄，20 把仅有的黑边吃光了 |
| `STAGE_GAP` | 6 | 4 | 同上 |
| `MIN_BAR` | 44 | 30 | 27px 的黑边仍差一点，30 是能按准的下限 |
| 满幅兜底 | 无（直接放弃） | `edgeFallback()` | 四边都不合格时，在**屏幕右侧中部**挂一块 60x72 半透明窄板 |

兜底窄板刻意不放在右下角（1.0.7 已证明右下角会盖住游戏操作区），而是垂直居中、
`opacity: .45`，并且 `__molePad.off()` 可一键拆除。

### 新增自救手势

屏幕**右上角 120x120 内快速点三下** → 立即 `__molePad.off()`，回到原生触控。
用于「合成事件被 WebView 拒收 → 点哪儿都没反应 / 登录框点不开」的死局，
用户不需要连电脑、不需要控制台。

### 新增诊断日志

挂载时打一行几何信息，平板问题一眼可辨：

```
[MoleShell] 几何 viewport=1280x800 舞台显示=1280x747 DPR=1.60 黑边[上27 下26 左0 右0]
[MoleShell] 触控板落点：edge（满幅舞台兜底窄板，半透明，右侧中部）
```

> ⚠ 关于「小米平板无法登录」：如果日志显示 `触控板落点：right/bottom`（有板子）
> 但仍然点不动，那是合成事件层面的问题，需要一次 `adb logcat -s MoleShell`
> 才能定位（重点看点击时有没有 `pointerdown` 之后 Ruffle 的响应）。本版先保证
> 「一定有板子 + 有手势可退」，不做无依据的猜测性改动。

---

## 3) 降内存 + 提像素密度

### 根因：预算与实际显示面积完全脱钩

旧逻辑里 `BUDGET` 是绝对值（Java 注入 90 万），而 `#wrap` 的**布局尺寸恒为
960x560**（靠 CSS transform 缩放到屏幕）：

```js
byBudget = sqrt(900000 / (960*560)) = 1.294   // 与屏幕多大无关
```

于是 canvas 后备缓冲恒定 **1242x725**：

- **小屏手机**（舞台实际只有 800x467）：1.55 倍线性超采样 —— 多出来的一半
  像素肉眼无差别，却实打实吃 GPU 显存与带宽。这是「内存占用高」的主要来源。
- **大屏平板**（舞台 1280x747）：1242x725 **欠采样**，画面被轻微拉伸 —— 这就是
  「像素密度不够、看着糊」。

### 改动

```js
目标像素 = 实际显示面积 × 1.44          // 线性 1.2x 超采样
实际上限 = min(目标, Java档位×1.6, 160万)  // 保留看门狗降档 + 防显存爆
实际下限 = max(结果, Java档位×0.4)        // 防分屏/小窗糊掉
```

`getBoundingClientRect()` 会强制同步 layout，而 `compute()` 挂在
`devicePixelRatio` 的 getter 上是高频调用，所以**只在 fit / resize / 预算变更时
测一次并缓存**，getter 里只读缓存值。

实测（模拟计算，非估算）：

| 设备 | 旧 canvas | 新 canvas | 变化 |
| --- | --- | --- | --- |
| 小屏手机 800x467 | 1242x725 (0.90M) | 960x560 (0.54M) | **−40% 像素** |
| 大屏平板 1280x747 | 1242x725 (0.90M) | 1536x896 (1.38M) | **+53% 像素** |
| 4:3 平板 1024x597 | 1242x725 (0.90M) | 1228x717 (0.88M) | −2% |

小屏省显存、大屏提密度，同一套公式两个方向都吃到。

### 没动

`#wrap` 的 CSS 尺寸、`transform: scale(f)` 的 `f`、`--f` 变量、帧率（24）、
节流器、`quality: 'low'`、服务器地址 —— 一个都没碰。画幅与游戏本体不变。

---

## 产物

`bugfix/mole-1.1.1-beta.apk` · versionCode 15 · versionName `1.1.1-beta`
10,319,236 B · SHA-256 `dcb36fb20753c46846750fce25de8a7a74655317ca85bc7108752edd6fa81e41`
签名同源 `974EA1B9…`，可直接覆盖 1.1.0 ~ 1.1.5。

## 验证要点

1. `aapt dump badging` 应为 `sdkVersion:'21'` + `targetSdkVersion:'31'`。
2. 鸿蒙 4.2 设备：安装 / 启动 / 触控是否恢复正常。
3. 小米平板 5 Pro：切后台再看，日志应出现 `触控板落点：edge` 或 `right/bottom`；
   右上角三连击应打印「已拆除 OmniPad」。
4. 像素密度：`adb logcat -s MoleShell | grep 降载` 看 `canvas=` 尺寸是否符合上表。
