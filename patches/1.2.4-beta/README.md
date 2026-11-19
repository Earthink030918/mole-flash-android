# 1.2.4-beta — 平板卡顿/闪退 · 崩溃上报 · 虚拟方向键（Android 25）

## 基线 → 产物

| 项 | 基线 | 1.2.4-beta |
| --- | --- | --- |
| Android | `1.2.0`（versionCode 24，10,356,100 B） | `mole-flash-1.2.4-beta.apk`（versionCode **25**，10,368,388 B） |
| HarmonyOS | `1.2.0`（versionCode 7） | **本版不出 HAP**，见文末「为什么没有 HAP」 |

```
0b00716b9f94ad06a1e04d4a215b243be7dd82061a585837309624a2ec31ad02  mole-flash-1.2.4-beta.apk
```

签名证书（**新密钥**，与 1.2.0 及以前不兼容）：

```
DN      CN=Mole Flash Shell, OU=Mole Flash Android, O=Mole Flash Android, L=Beijing, ST=Beijing, C=CN
SHA-256 b9197126c1ce0bca61ac7dae5072244333f427d2d87c87bc16a9b69dae845bee
RSA 4096，10000 天，v1 + v2 + v3 三方案全部验签通过
```

升级前必须先卸载旧版：换了密钥，`INSTALL_FAILED_UPDATE_INCOMPATIBLE` 是预期行为，
且 `mole_shell` 里学到的服务器地址缓存（SharedPreferences）会一并丢——重进游戏自动重学。

## 改动清单

| 文件 | 变化 |
| --- | --- |
| `assets/ruffle/shell.html` | 194,969 B → **218,352 B**：预算法加软地板、新增第 8 段崩溃上报、第 9 段方向键浮钮 |
| `assets/ruffle/mole_boot.js` | 19,614 B → **22,973 B**：panic 时证据驱动降档、两处崩溃上报触发点 |
| `smali/…/CrashReport.smali` | 新增。写文件 + 主线程弹分享面板 |
| `smali/…/CrashReport$1.smali` | 新增。`Runnable`，构造 `ACTION_SEND` + `createChooser` |
| `smali/…/MainActivity$JsBridge.smali` | 新增 `reportCrash(String,String)V`，带 `@JavascriptInterface` |
| `apktool.yml` | `versionCode 24→25`、`versionName 1.2.0→1.2.4-beta` |

引擎三件套（`ruffle_web_bg.EFKRKUVC.wasm.gz` / `ruffle_web-wasm_mvp_bg.I56A2W5M.wasm.gz` /
`__mole_ruffle__.js`）、OmniPad 0.7.3、`AndroidManifest.xml`、其余 22 个 smali 类一个字节未动。

---

## 一、平板卡顿闪退：预算地板把后 5 档全废了

### 根因

`budgetNow()` 的第一行是：

```js
var base = Math.max(BUDGET, BUDGET_MIN);   // BUDGET_MIN = 1210000
```

`PIXEL_BUDGETS` 六档是 `121万 / 90万 / 66万 / 46万 / 32万 / 21万`，Java 的
`evaluateLoadLevel()` 按连崩次数注入档位。这行 `Math.max` 让**档位 1~5 全部等价于档位 0**：

| 档位 | 注入 `BUDGET` | 旧代码实际生效 | 新代码 tier≥3 生效 |
| --- | --- | --- | --- |
| 0 | 1,210,000 | 1,210,000 | 1,210,000 |
| 1 | 900,000 | 1,210,000 | 1,210,000（软地板保护） |
| 2 | 660,000 | 1,210,000 | 1,210,000（软地板保护） |
| 3 | 460,000 | 1,210,000 | 460,000×1.6 封顶 |
| 4 | 320,000 | 1,210,000 | 320,000×1.6 封顶 |
| 5 | 210,000 | 1,210,000 | 210,000×1.6 封顶 |

于是形成死循环：**native 崩溃 → `loadLevel++` → 预算纹丝不动 → 同样的分辨率再来一次 → 再崩**。
Adreno 上的 `sharedmem_gpumem_alloc mmap failed errno 12`（连 4KB 都分不出来）本来就是
「少给点像素就能活」的场景，可降档机制从 1.1.9 引入 `BUDGET_MIN` 地板起就再没真正生效过。

平板吃亏最狠：`shownArea` 大，`max(shownArea×1.7, base)` 被抬得很高，六档全撞在同一个数上。

### 改法（`budgetNow()` / 新增 `softFloor()`）

地板从**硬地板**改成**软地板**：只保护 0~2 档（这三档本来就在 46 万以上，是真·降质下限），
3 档及以下尊重 Java 真实押下来的预算。

```js
var PIXEL_LEVELS = [1210000, 900000, 660000, 460000, 320000, 210000];  // 与 PIXEL_BUDGETS 逐项对齐
var SOFT_FLOOR_FROM = 3;

function softFloor() {
  var lv = budgetLevel(BUDGET);
  return lv >= SOFT_FLOOR_FROM ? BUDGET : BUDGET_MIN;
}
var base = Math.max(BUDGET, softFloor());
```

实测像素数（`MAXPIX` 220 万、`DENSITY 1.7`、`FLOOR 0.7` 均未动）：

| 机型 | 档位 | 1.2.0 | 1.2.4-beta |
| --- | --- | --- | --- |
| 平板 1280×800 CSS / DPR 2 | 3 | 1,740,000 | 1,056,000（−39%） |
| 平板 1280×800 CSS / DPR 2 | 5 | 1,740,000 | 336,000（−81%） |
| 手机 915×412 CSS / DPR 2.625 | 3 | 1,210,000 | 660,000（−45%） |
| 手机 915×412 CSS / DPR 2.625 | 5 | 1,210,000 | 336,000（−72%） |

**正常路径 0~2 档与 1.2.0 逐像素相同**——干净安装、没连崩过的机器看到的画面一模一样。
只有「已经连崩 3 次以上」的机器才真正降到更低档，而那台机器原本每次都是必崩。
回升走 Java 既有逻辑：`boot_good_runs_v4` 连续 2 次平稳启动就 `level−1`（`evaluateLoadLevel` 里的
`连续 2 次平稳启动 → 画质回升一档`），不改 Java 一行。

### 顺带修掉一个静默异常

启动诊断那行 `预算=…` 引用了 `BUDGET` / `softFloor` / `budgetLevel`——它们都是 IIFE 闭包内的局部变量，
外层那段 IIFE 根本看不见，`ReferenceError` 被外面的 `try{}catch{}` 吞掉，日志里那一栏一直是空的。
新增 `window.__moleBudgetInfo()` 导出，诊断行改走它，现在能读到
`预算=1210000px（生效 1210000px，档位 0）`。

## 二、OPPO 红屏更频繁：后端档位永远降不下来

### 根因

`mole_boot.js` 的 `onPanicDom()` 里，降档条件是「panic 文案命中 GPU 关键词」：

```js
var looksGpu = /webgl|gpu|context|shader|wgpu|out of memory|…/i.test(flat);
if (looksGpu) { __moleRendererBump(); }
```

ColorOS 的 WebView 上 Adreno 驱动 panic 时，Ruffle 面板给出的文案经常只有一句
`Something went wrong`，正文被截断或压根没填——`looksGpu` 判 false，后端**永远不降**，
下次进来还是 `wgpu-webgl`，还是同一处崩。OPPO 机器因此表现为「红屏比别的机型勤，而且永远好不了」。

### 改法：把「重复」本身当证据

```js
var tierKey = 'mole_panic_tier_' + (window.__moleRendererTier || 0);
var tierN = (parseInt(sessionStorage.getItem(tierKey) || '0', 10) || 0) + 1;
sessionStorage.setItem(tierKey, String(tierN));
var repeatTier = tierN >= 2;
…
if (looksGpu || repeatTier) { __moleRendererBump(); }
```

同一个后端档位**第二次**崩，不管文案是什么，直接降档。判据从「猜原因」改成「看结果」——
连续两次死在同一个后端上，这个后端在这台机器上就是不可用，理由不重要。
首次崩溃仍按原逻辑（可能是脚本 bug 而非 GPU），不会白白降画质。

## 三、崩溃上报：自动生成 txt + 系统分享（可直接发 QQ）

### 触发点（三处，全部在 `mole_boot.js`）

1. `onPanicDom()` —— Ruffle panic 面板出现时，**重载之前**采样（此时 `sessionStorage`、
   画布尺寸、后端档位都还读得到）；
2. WebGL 上下文丢失 2.5s 未恢复 —— 这是 native 崩溃的前兆（`onGpuExhausted('dead')` 之前），
   先把现场写下来；
3. `shell.html` 第 8 段自己抓的 `window.onerror` / `unhandledrejection`（只入环形缓冲，
   不单独弹窗，避免高频骚扰）。

节流：自动分享 10 秒一次、每会话最多 2 次；超了只写日志不弹窗。

### 报告内容

`window.__moleCrash.build()` 拼出来的是给人看的中文 `txt`（字段名与顺序如下，
`extra` 是触发点各自塞的现场信息）：

```
===== 摩尔庄园 Flash 客户端 · 崩溃报告 =====
报告类型: Ruffle panic
触发时间: 2026-11-19 16:02:11
客户端版本: 1.2.4-beta（Android）

----- 设备 -----
UA: Mozilla/5.0 (Linux; Android 14; PJZ110 …
屏幕: 915x412 | 视口: 915x412 | DPR: 2.625
GPU: Adreno (TM) 740 | Qualcomm
JS 堆: 148 MB / 512 MB

----- 渲染状态 -----
后端: wgpu-webgl（降级档位 2）
画布: 1440x840（CSS 915x412）
像素预算: 660000 px（生效 1210000，档位 0）
影片: 960x560 | 缩放: 0.953
已运行: 37s
本次会话 panic 次数: 1
OmniPad: mounted=true 落点=… 靶区=…
后台状态: frozen=false hidden=false playing=true audio=true

----- 现场 -----
渲染后端: wgpu-webgl（档位 2）
后端档位连续崩溃: 2
判定: 证据驱动·后端不可用
已运行: 37s
panic 标题: …
panic 正文: Something went wrong

----- JS 运行时错误（最近 N 条）-----
…

----- 运行日志（最近 N 行）-----
…[MoleShell] 渲染实况 budget=…

===== 报告结束 =====
```

日志行经 `maskIp()` 抹成 `1.2.*.*`，与既有日志脱敏一致。


### 落到磁盘 + 分享（smali）

`window.__moleCrash.share()` → `MoleBridge.reportCrash(name, txt)`（新增的 `@JavascriptInterface`）
→ `CrashReport.share(ctx, name, text)`：

1. 写 `getExternalFilesDir(null)/crash/mole-crash-<时间戳>.txt`，UTF-8；
   **不需要任何存储权限**（`/Android/data/<pkg>/files/` 是应用私有外置目录），也不污染相册；
2. `Handler(getMainLooper()).post(...)` 切回主线程；
3. `Intent(ACTION_SEND)` + `type=text/plain` + `EXTRA_SUBJECT`（文件名）+ `EXTRA_TEXT`（全文）
   → `Intent.createChooser(…, "分享崩溃日志（可直接发给开发者）")` → `startActivity`。

选「QQ」就是发到 QQ 好友/群，选微信、备忘录、邮件同理——用系统选择器而不是硬编码包名，
QQ / TIM / 微信都装了的机器上不会打架。

写文件那段的 catch handler 第一条指令是 `move-exception v0`（1.1.5 的 `MoleKeepAlive` 栽在这上面过，
这次用 `apktool d` 回解产物逐条核对过，见「验证」）。

### 手动上报

控制台（或 `chrome://inspect`）里：

```js
__moleShareCrash('切地图后卡死')     // 立刻生成并弹分享
__moleCrash.info()                   // { ring, errs, autoShared }
__moleDpad.state()                   // { mounted, open, engine }
```

## 四、虚拟方向键：OmniPad `VirtualDPad`，找不到就自己画

先查了 OmniPad 0.7.3 的导出面：`VirtualDPad` / `Button` / `Joystick` / `InputZone` / `RootLayer` ……
**有 `VirtualDPad`**，`DPadCore` 构造是 `new T(targetStageId, mapping?.[方向])`，
按下发 `KEYDOWN`、抬起发 `KEYUP`，内置键表 `Z` 里 `ArrowUp/Down/Left/Right` 的 keyCode 是 37~40；
皮肤也不用画——`omnipad-0.7.3.css` 里 `.omnipad-dpad-cross-bg` / `.dpad-arm.top|bottom|left|right` /
`.dpad-arm.on` 全套都在，连按下高亮的 CSS 变量都备好了。所以直接用，不造轮子。

- 左下角一个 46×46 半透明圆钮，点一下展开 132×132 十字键，再点收起；
- 收起用 `opacity + visibility` 而不是 `display:none`——后者会让 OmniPad 量到的 rect 变 0，
  重新展开时方向键全落在原点；
- 挂载点 `targetStageId: '$stage'` 复用第 5 段那个 `TargetZone`，转屏后跟着第 5 段一起重算，
  不额外抢焦点（第 5 段为焦点打过三轮补丁，这里只做输入不改焦点）；
- **兜底**：`VirtualDPad` 不在（内核太旧）或 `#pad` 还没建起来时，退化成四个自绘键
  + 原生 `KeyboardEvent` 直接派发到 `ruffle-player`（`keyCode`/`which` 用 `defineProperty` 补，
  这两个属性在 `KeyboardEvent` 上是只读的）。功能不减，只是没有 OmniPad 那层皮；
- `setInterval` 每 500ms 试一次，最多 60 次（30s）；兜底模式每 10 次（≈5s）尝试升级成 `VirtualDPad`，
  升上了就清掉自绘键。

关闭：`__moleDpad.off()`（`toggle()` 只管展开/收起）。

## 五、明确没有动的东西

按需求原文，以下一律未改：**画质参数（`quality`）、帧率（24 / 节流器）、画幅（`letterbox` / `scale` /
`960×560`）、键盘守卫（五层输入法补丁）、无损纹理回收、`PIXEL_BUDGETS` 数组本身、Java 的降档逻辑**。

需要说明一处边界：第一节的软地板**会让 3 档以下的机器真的降分辨率**，这在效果上等于动了画质。
但它只在「同一个包已经连崩 3 次以上」时生效，且恢复走既有 `boot_good_runs_v4`——
不改就是无限崩溃循环（原本已经在 1.1.9 被判定为 bug 并用硬地板修过一次，硬地板修好了马赛克、
埋掉了降档）。0~2 档与干净安装的机器，输出与 1.2.0 逐像素一致。

## 六、构建与签名

```bash
# 1) 反编译基线
java -jar apktool.jar d base-1.2.0.apk -o dec

# 2) 替换 assets + 补 smali + 改 apktool.yml（versionCode 25 / versionName 1.2.4-beta）

# 3) 重打包
java -jar apktool.jar b dec -o unsigned-1.2.4-beta.apk

# 4) 新密钥
keytool -genkeypair -keystore keystore/mole-release.jks -storetype PKCS12 \
  -alias mole -keyalg RSA -keysize 4096 -validity 10000 \
  -dname "CN=Mole Flash Shell, OU=Mole Flash Android, O=Mole Flash Android, L=Beijing, ST=Beijing, C=CN"

# 5) 对齐（必须 -p：4 字节对齐 + 共享库页对齐）
zipalign -p -f 4 unsigned-1.2.4-beta.apk aligned.apk

# 6) 签（v1 给 Android 5/6，v2/v3 给 7+）
apksigner sign --ks keystore/mole-release.jks --ks-key-alias mole \
  --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true \
  --min-sdk-version 21 --out mole-flash-1.2.4-beta.apk aligned.apk
```

工具链：Microsoft JDK 17.0.21.1+2、apktool 2.11.1、build-tools 35.0.0（`aapt2` / `zipalign` / `apksigner` / `dexdump`）。

## 七、验证

| 项 | 结果 |
| --- | --- |
| `aapt2 dump badging` | `com.taomee.mole` / `versionCode='25'` / `versionName='1.2.4-beta'` / minSdk 21 / targetSdk 31 |
| `apksigner verify --print-certs` | Verifies；v1 ✔ v2 ✔ v3 ✔；SHA-256 `b9197126…45bee` |
| `zipalign -c -v 4` | Verification succesful（`shell.html` 为 compressed，属预期） |
| `dexdump -f` | 26 个类，含 `CrashReport;`、`CrashReport$1;`、`MainActivity$JsBridge;`、`JsBridge.reportCrash(Ljava/lang/String;Ljava/lang/String;)V` |
| APK 内 assets | `shell.html` md5 `1d8ff563…326f`、`mole_boot.js` md5 `d359f8a9…1cbe`，与 `src/web/` 同源文件一致 |
| 回解复核 | `apktool d` 回解签名后的 APK，`CrashReport.smali` 的 `:catch_0` 首条指令为 `move-exception v0` |
| 离线断言 | `text_test` 24/24、`clock_test` 34/34、`bg_test` 54/54、`panic_test` 34/34 全绿；`pad_test` 79/17 —— 与 1.2.0 基线完全一致（17 红是 1.1.1-beta 改几何留下的既有红，见 `patches/1.2.0/README.md`），**本版零新增失败** |

`node --check` 通过：三段内联脚本 + `mole_boot.js`。

## 八、已知限制

1. **本版没有 HAP。** 需求里要的鸿蒙包需要 DevEco + API SDK 重编 ArkTS；开发机上
   `D:\DevEco Studio` 与其 SDK 已删除，仅靠改 `rawfile` + 重签容器无法把新的
   `shell.html` / `mole_boot.js` 和新 smali 等价物带进 HAP（HarmonyOS 侧的 `NativeBridge`
   没有 `reportCrash` 通道，`getExternalFilesDir` 与 `Intent.ACTION_SEND` 都得换 ArkTS API）。
   HAP 留到下一轮环境就绪后单独做。
2. 崩溃上报**只覆盖 JS 层与 panic / 上下文丢失**。纯 native 段错误（`SIGSEGV` 直接杀进程、
   WebView 渲染进程被 OOM killer 干掉）在 Java 层没有 `try/catch` 机会，只能靠下次启动时
   `CrashProbe` 的连崩计数间接体现——这也是第一节软地板的输入。
3. 第一次弹分享面板时若系统里没有任何能收 `text/plain` 的应用（极简 ROM），
   `createChooser` 会抛 `ActivityNotFoundException`，已被 catch 并写 `MoleShell` 日志；
   `txt` 文件仍会落在 `/Android/data/com.taomee.mole/files/crash/`。
4. 方向键浮钮默认在左下角，可能与游戏内部分小游戏面板重叠；`__moleDpad.off()` 可关，
   后续版本考虑做成可拖动（本版不做，避免碰触控命中的几何）。
