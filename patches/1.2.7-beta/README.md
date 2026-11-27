# 1.2.7-beta — 给「还没崩」的时候也留一扇门（Android 28）

| 项 | 值 |
| --- | --- |
| 产物 | `mole-flash-1.2.7-beta.apk`，10,388,868 B（9.91 MiB） |
| versionCode / versionName | `28` / `1.2.7-beta` |
| SHA-256 | `8c2bcec6b6cd5c4f35a1cc8df8d9a5295f3ffdb569d5f6901f4e90ef600ab0ad`（r2）<br>`d12326313cb8b3bf91d470cb3079d78d80cd441e053f44f56d5ce3d06e258c37`（r1，已在 Release 上） |
| 签名 | `keystore/mole-release.jks`（alias `mole`），v1 + v2 + v3 |
| 证书 SHA-256 | `B9197126…AE845BEE`（与 1.2.4 / 1.2.5 / 1.2.6 同一把） |
| 改动面 | `assets/ruffle/shell.html`；r2 另动 `AboutDialog.smali` / `AboutDialog$1.smali`（`classes.dex` 仍是 **28 个类**），`mole_boot.js` 未变 |

---

## 一、需求原文

> 在游戏里面新增一个按钮，摆在手机横屏之后的右上角。点击以后跳转到日志分享的界面，
> 但是这个界面可以被返回，返回的上一级页面就是游戏的主页面。这个页面直接调用崩溃之后
> 会弹出来的分享界面，所有的功能（包括分享）都保留，但上面的日志要实时更新。
> 一旦用户点击分享，日志停止更新，并拉起分享窗口。

约束（原话）：

1. 不要对帧率、画质画幅、键盘守卫、回收机制等一切可能影响游戏本体、甚至可能导致崩溃的设置做修改；
2. 本地有代码仓库；
3. 完成后打包成 Android APK。

---

## 二、实现

### 2.1 一张页面，两个来路

崩溃页（1.2.6 的第 10 段）改成带 `mode` 的状态机，DOM 骨架只有一份：

| | `mode='crash'` | `mode='live'` |
| --- | --- | --- |
| 抬头 | 摩尔庄园 · 微端 · 崩溃现场 | 摩尔庄园 · 微端 · 运行日志 |
| 主按钮 | 重新进入（`location.reload()`） | ← 返回游戏（`close()`） |
| 日志 | 定稿快照 | 每 1 s 重抓 |
| `#pad` | `display:none`（player 已死，留着只会接走点击） | **不碰**（游戏还在用） |
| history | 不塞 | `pushState` 一条，用来吃返回键 |

两套 UI 各写一遍迟早长歪，所以 `applyMode()` 只换文案与按钮语义，节点不重建 ——
崩溃页 ↔ 日志页之间切换不闪、不丢滚动位置。

### 2.2 浮钮：`__moleLogBtn`（第 10-B 段）

```
position:fixed; right:calc(10px + env(safe-area-inset-right));
              top:calc(10px + env(safe-area-inset-top));
z-index:13;   /* OmniPad 是 9，崩溃页是 2147483647 */
width:52px; height:34px;
```

- 挂载**延后一个宏任务**：本文件解析完紧接着就是 Ruffle 起播，一个 `style`
  加一个 `div` 没必要挤在首帧的主线程上。`body` 没建好就退让重试（最多 20 次）。
- 点下去调 `__moleCrashPage.showLive()`；返回 false 时退化成
  `__moleCrash.share('手动上报')` —— 按钮永远不「点了没反应」。
- `hide()` / `show()` 由日志页在进出时调，避免浮钮压在浮层上多一层命中测试。

### 2.3 实时刷新：只重算该重算的

`tick()` 每秒一次，做三件事：重出正文、刷五行摘要、刷日志尾巴（最近 40 行）。

关键一处：`__moleCrash.build(kind, extra, { cachedGpu:true })`。

第 8 段原本每次 `build()` 都调 `gpuInfo()` —— 那是**新建一个 canvas + WebGL 上下文**，
用完立刻 `loseContext()`。崩溃现场这么做是对的（只此一次），但每秒一次就等于
「拿诊断工具当崩溃源」，正好撞在本段开头第 2 条禁区上。所以：

```js
var gpuCache = '';
function gpuInfo(cached) {
  if (cached && gpuCache) return gpuCache;   // 实时刷新走这里
  ...                                        // 崩溃上报仍然现探
  if (!gpuCache) gpuCache = out;             // 一次会话只探一次
  return out;
}
```

崩溃上报（`show()`）**不带** `cachedGpu` —— panic 之后上下文状态可能已经变了，
报告里要的是那一刻的真相。

### 2.4 分享即冻结

顺序不能反：

```js
if (live) freeze('分享');   // 1) 停表 + 定稿 + 摘要行改「已冻结在分享前这一刻」
var txt = lastText;         // 2) 取正文
MoleBridge.reportCrash(name, txt);  // 3) 落盘 + 系统分享面板
```

先取正文再冻结的话，就可能发出「比页面多一行」的报告 —— 用户会以为自己在看假日志。
文件名 `mole-log-<yyyymmdd-hhmmss>.txt`（崩溃上报仍是 `mole-crash-*.txt`），
落在同一个 `getExternalFilesDir(null)/crash/` 里，不需要任何权限。

### 2.5 返回：不 reload 是硬要求

`MainActivity.onBackPressed()` 本来就写着 `canGoBack() → goBack()`，所以只要
**往 history 里塞一条同文档状态**，系统返回键就正好兜住：

```js
history.pushState({ moleLog: 1 }, '');   // 不传 URL：同文档，绝不触发真实导航
```

收到 `popstate` → `close(true)`（不再自己 `back()`，否则连退两级）。
点「← 返回游戏」→ `close(false)` → 先把 `pushed` 置 false 再 `history.back()`，
余波里的 `popstate` 就是空操作。

还加了 300ms 的余波保护：刚打开就收到 `popstate`，只可能是上一次「退回游戏」
那一下迟到的一跳，不能拿它把刚打开的页面收掉。

`pushState` 万一被拒（老内核 / 非 http 上下文），`pushed` 保持 false，
退化成「只能点按钮返回」—— 功能不减，只是系统返回键会退出应用。

### 2.6 横屏两栏（只在 `.live` 下）

`(orientation:landscape) and (min-width:600px)`：

```
"head log"     左栏：标题 / 摘要（两列网格）/ 提示 / 三个按钮 / 脚注
"rows log"     右栏：日志正文（max-height: calc(100vh - 150px)）
"tip  log"
"btns log"
"foot log"
```

手机横屏的 CSS 视口只有 400 出头，单栏竖着码下来，五个摘要行加提示能把
「返回游戏」顶到屏幕外 —— 用户会以为这一页出不去。所以横屏下同时收：

- 表情整个不显示，`h1` 17px；
- 摘要改两列网格（键列 42px），引擎行 `grid-column:1 / -1` 不折行，
  「日志行数」这条摘要直接让位（行数已经写在日志区标题里）；
- 三个按钮 `flex:1 1 0` 排一行，12px 不换行。

800×360 与 932×430 两种视口都用无头 Edge 截图核过：三个按钮与脚注都在首屏内。

---

## 三、验收

```bash
cd mole-flash-android
node tests/logpage_test.js      # 59 条
for t in text clock bg crashui dpad pad panic; do node tests/${t}_test.js; done
```

| 项 | 结果 |
| --- | --- |
| `tests/logpage_test.js` | **59/59 通过**（实时刷新 / cachedGpu / 冻结后不再改写 / 无桥退化 / 开着时 panic 切终局 / 浮钮挂载与降级 / 返回键余波） |
| 其余 7 套 | `text 24`、`clock 34`、`bg 54`、`crashui 40`、`dpad 22`、`panic 50` 全通过；`pad` 79/17 —— 17 条触控板几何失败是 1.1.x 起的既有基线，与本次改动无关（改动前后逐条 diff 过） |
| `aapt2 dump badging` | `com.taomee.mole` / `versionCode 28` / `versionName 1.2.7-beta` / minSdk 21 |
| `apksigner verify` | v1 true、v2 true、v3 true |
| `zipalign -c 4` | 通过 |
| `dexdump` 类数 | **28**（与 1.2.6 相同，本轮零 Java 改动） |
| 包内 `assets/ruffle/shell.html` | md5 `4a488b6dff2db0d7374de1a955c00622`，与 `src/web/shell.html` 一致 |
| 视觉 | 无头 Edge 截图核过 800×360（日志页 / 崩溃页 / 游戏主界面）与 932×430（日志页） |

---

## 四、没有动的

| 项 | 状态 |
| --- | --- |
| 画幅 | 960×560 + letterbox，`#wrap` 与 `transform: scale(f)` 未动 |
| 帧率 | `frameRate 24`、rAF 泵未动 |
| 节流器 | 未动 |
| 画质 / 像素预算 | `quality:'low'`、`DENSITY` / `MAXPIX` / `FLOOR` / `budgetNow()` 未动 |
| 输入法守卫 | 五层守卫未动 |
| 纹理回收 | `__molePurgeTex` / `__moleSetBudget` 未动 |
| OmniPad | 本体未动；**日志页不再 `display:none` 掉 `#pad`**（只有崩溃页还这么干） |
| 环形日志缓冲 | 未动（没有加「清空日志」这类会销毁现场的功能） |
| `mole_boot.js` | 未动 |
| `classes.dex` / Manifest / 权限 | 未动 |

---

## 五、构建与签名

```bash
# 1) 网页资源同步进 dec
cp mole-flash-android/src/web/shell.html build-env/dec/assets/ruffle/

# 2) 版本号：dec/apktool.yml → versionCode 28 / versionName 1.2.7-beta

# 3) 重打包
java -jar apktool.jar b dec -o unsigned-1.2.7-beta.apk

# 4) 对齐 + 签名（v1 + v2 + v3）
zipalign -p -f 4 unsigned-1.2.7-beta.apk aligned-1.2.7-beta.apk
apksigner sign --ks keystore/mole-release.jks --ks-key-alias mole \
  --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true \
  --min-sdk-version 21 --out mole-flash-1.2.7-beta.apk aligned-1.2.7-beta.apk
```

密钥：`build-env/keystore/mole-release.jks`（PKCS12，RSA 4096，alias `mole`，
口令 `MoleFlash2026#beta`）。**不进仓库。**

---

## 六、这一版没做的

- **HAP 仍然没出**：DevEco / SDK / ArkTS 工程 / 签名材料本机都不在，且这轮改动
  全在 `rawfile/shell.html`，鸿蒙壳层只要换资源即可（`NativeBridge` 侧不涉及）。
- **触控板几何抖动**（51↔30px 宽度、top 133↔132）仍在观察，疑似 fit 引擎里
  两个交替的缩放系数，与本版无关。

---

## 七、r2：弹窗文案与「不再弹出」

> 需求原话：**仅更新弹窗里面的文字**；末尾加一行小字，右下角加「by 尘墨」，
> 第三行加入「欢迎来到我的小窝一起玩，QQ小窝的群号是：1125775110」；
> 再加一枚「不再弹出」的按钮 —— 安装后第一次打开才看得到，点过之后下次不再弹，
> 但**覆盖安装要再弹一次**。版本号保持 1.2.7-beta 不动。

### 7.1 顺手修掉一个一直存在的事实错误

旧 `AboutDialog$1.run()` 的分支是反的：

```
if-eqz v2, :after      # v2 = 已弹过 → 为 0 时跳走（＝没弹过反而跳去显示）
... putBoolean(true)
goto :after            # 弹过的那条路也落到显示
:after  show()
```

两条路最后都落到 `show()`，所以 **`mole_about_v1` 写了等于没写，每次启动都弹**。
这正是需求里「用户仅在第一次打开游戏的时候才能够看到」要修的东西。

### 7.2 判定依据：安装戳，不是版本号

```
PackageInfo.lastUpdateTime  ←→  SharedPreferences("mole_shell").getLong("mole_about_stamp", 0)
```

| 场景 | `lastUpdateTime` | 结果 |
| --- | --- | --- |
| 首次安装后第一次启动 | 首次安装时刻 | 戳不同 → **弹**，并立即记下戳 |
| 同一份安装里再次启动 | 不变 | 戳相同 → 跳过 |
| **覆盖安装**（含同 versionCode） | 被系统刷成安装时刻 | 戳不同 → **再弹一次** |

为什么不用 `versionCode`：这一版按要求**不动版本号**，同版本覆盖安装也必须重弹，
只有安装戳靠得住。也没有用「写一个布尔值再在安装时清掉」—— 那需要 `MY_PACKAGE_REPLACED`
广播接收器，多一个组件多一份风险，而安装戳是系统本来就替我们记着的。

戳在**弹之前**就写：用户直接杀进程、按返回键、或者只是没点按钮，都不会造成下次再被拦一次。
`force=true`（崩溃页的「关于本作」）既不读也不写戳 —— 用户主动点的，不能被「已弹过」吞掉。

任何 `Throwable`（无包管理器、无偏好）都按「没弹过」处理：宁可多弹一次，
也不能让「非官方声明」根本没人看见。

### 7.3 文案

```
第一段   谢谢你选择了我这么一个小小的开源项目～能在这里遇见你，真的很开心！♡
第二段   <font color='#E23A3A'>（真红字）小提醒一下：本作并非摩尔庄园官方项目……
第三段   欢迎来到我的小窝一起玩，QQ小窝的群号是：1125775110。本作目前还在开发阶段……
小字     （每次安装只出现一次，点「不再弹出」就不再打扰你啦）
落款                                                    by 尘墨
```

- 小字与落款都用 `<font color='#8A8A90'><small>` —— `Html.fromHtml` 里 `<small>` 就是
  `RelativeSizeSpan(0.8)`，跟系统字体缩放一起走，不是写死的 px。
- **右下角**：`AlertDialog` 的 message 只吃一个 `CharSequence`，`Html.fromHtml` 不产出段落对齐，
  所以包一层 `SpannableStringBuilder`，对最后 5 个字符补
  `AlignmentSpan.Standard(Layout.Alignment.ALIGN_OPPOSITE)`。落款前面有 `<br>` 独立成段，
  span 不会波及正文。
- **「不再弹出」放 neutral 位**：Android 的按钮顺序是 neutral → negative → positive，
  于是「不再弹出」在左、「我知道啦 ♡」在右，符合「次要动作靠左」的直觉。
- 两枚按钮都**不挂 listener**：`AlertController` 在 listener 为空时照样 dismiss，
  所以没为一个空实现多出一个 class —— dex 里仍然是 **28 个类**。

### 7.4 网页侧与鸿蒙侧同步

- `shell.html` 第 11 段：`LINES[2]` 加群号，新增 `NOTE` / `BY` / `DISMISS`，
  `payload()` 一并带给鸿蒙（`{title, lines, ok, note, by, dismiss}`），
  页内兜底弹窗也画了小字、右下角落款与两枚按钮。
- 鸿蒙侧的 ArkTS 参考实现（`patches/1.2.6-beta/harmony/AboutDialog.ets`）已同步
  同一套字段与安装戳判定（`bundleManager` 的 `updateTime`），仍**未编译进 HAP**。

### 7.5 验收

- `tests/crashui_test.js` 40 → **51 条**：群号、小字、落款、新按钮文案、
  鸿蒙 payload 三个新字段、页内兜底的两枚按钮与落款样式。
- 既有 7 套全绿（`pad_test` 的 17 条触控板几何失败是 1.1.x 的既有基线，与本次无关）。
- 包内 `assets/ruffle/shell.html` 与源文件 md5 一致；`classes.dex` 里检到
  `getPackageInfo` / `lastUpdateTime` / `getLong` / `putLong` / `ALIGN_OPPOSITE` /
  `setSpan` / `setNeutralButton` 七条关键指令，`class_defs_size` 仍是 28。
- v1 + v2 + v3 三项签名通过，证书仍是 `B9197126…AE845BEE`，可直接覆盖 1.2.4 起的任何一版。

**没有动的**：帧率 24、画幅与 `quality: 'low'`、节流器、`DENSITY` / `MAXPIX` / `FLOOR`、
`budgetNow()`、五层输入法守卫、纹理回收、OmniPad 本体、服务器地址与端口池、
`AndroidManifest.xml`、`mole_boot.js`。

