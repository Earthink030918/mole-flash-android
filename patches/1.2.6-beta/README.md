# 1.2.6-beta — 崩了就停在一张说人话的页面上，顺手把「关于本作」交回系统（Android 27）

## 基线 → 产物

| 项 | 值 |
| --- | --- |
| 基线 | 1.2.5-beta（`versionCode 26`），仓库提交 `378cbe2` |
| 产物 | `mole-flash-1.2.6-beta.apk`，10,380,676 B（9.90 MiB） |
| versionCode / versionName | `27` / `1.2.6-beta` |
| SHA-256 | `f9cb58141d955ddf7b1b8247a3c68fcb08fedd6cd7842bffe4d640bf51005340` |
| 签名 | 沿用 1.2.4-beta 那把密钥（证书 SHA-256 `B9197126…AE845BEE`），**可覆盖升级** |
| 鸿蒙 | **本轮未出 HAP**，原因见第五节 |

改动面：`shell.html`（第 8 段补 `save()`、新增第 10/11 段）、`mole_boot.js`（panic 收场）、
`AboutDialog.smali` + `AboutDialog$1.smali`（新增）、`CrashReport.smali`（拆出 `save`）、
`MainActivity$JsBridge.smali`（+`saveCrash` / +`showAbout`）。

---

## 这一版面对的两份日志

| | 日志 A | 日志 B（「刚登陆就崩溃」） |
| --- | --- | --- |
| 设备 | PHZ110 | 24117RK2CC |
| SoC / GPU | Mali-G720-Immortalis MC12 | 骁龙 8 Gen3 / Adreno 750 |
| 系统 | Android 16，Chromium 138 | Android 16，Chromium 156 |
| 后端 / 档位 | wgpu-webgl，档位 0 | wgpu-webgl，档位 0 |
| 像素预算 | 460000（档位 3） | 900000（档位 1） |
| 崩在 | 启动后 27s | 启动后 32s |

两台机器、两个 GPU 厂商、两个 Chromium 大版本、两个渲染档位，错误的**顺序**一模一样：

```
JSERR| Uncaught RangeError: Maximum call stack size exceeded  @wasm://wasm/ruffle_web.wasm-…
JSERR| Uncaught RuntimeError: unreachable
ERROR| panicked at core\src\player.rs:485:16: arena already borrowed
```

两台不同的机器在同一处、以同一顺序倒下，说明既不是 Mali 的驱动，也不是 Adreno 的显存。
日志 B 的标题写「刚登陆就崩溃」，而两份日志的 `已运行` 都不到 35 秒 —— 也就是**登录前后那几十秒**。

---

## 一、`arena already borrowed` 是尸检报告，不是死因

Ruffle core 的 `Player::enter_arena_mut()`（`core/src/player.rs:485`）用
`arena.try_borrow().ok().expect("arena already borrowed")` 保护 GC arena：**借不到就直接 panic**。
而「借不到」的唯一原因是**重入** —— 有人还握着 arena，又进来调了一次 Player。

真正的死因是它上面那一行：`Maximum call stack size exceeded`，位置在 `@wasm://…`，
也就是**浏览器在 wasm 帧上抛的 RangeError**。栈溢出从 JS 侧抛出来，穿过 Rust 帧时
**析构函数一个都不会跑**，`gc_arena` 的借用守卫就这么永久留在「已借出」状态；
紧接着 panic hook 自己的 `global_init` 又要进 arena，于是撞上 485 行，
再 `unreachable`、再红屏。

所以 1.2.5-beta 的「判定为核心重入 → 降一档重试」虽然认得对，但**治不了**：
换后端换掉的是 GL 抽象层，AS3 的递归深度一分不减，深度该爆还是爆。
这一版不再假装能修它，只做两件确定能改善体验的事：

1. **别把用户困在红屏里** —— 见第三节；
2. **把现场完整交出去** —— 崩溃页右上角一键分享到 QQ 群。

---

## 二、顺手揪出来的两个真 bug

### 1. 启动日志里的「生效」一直是错的（诊断层面）

`shell.html` 第 0.4 段那行启动日志写的是 `Math.max(BUDGET, BUDGET_MIN)` ——
那是 1.1.9 的**硬**地板，1.2.4 换成**软**地板时这行没有跟着改。于是每次启动都印：

```
渲染实况 budget=460000（生效 1210000） DPR=0.93 …
```

而同一份崩溃报告里写的是「像素预算: 460000 px（生效 460000，档位 3）」。
**同一次启动，两个数互相打脸。** 看日志的人（包括上一版的我）自然会以为降档又失效了。

现在这行改读 `window.__moleBudgetInfo()`，日志与报告同一个源。
这是纯诊断修复，`budgetNow()` 一行没动。

### 2. `MoleBridge.onPanic()` **根本不重载**（真实行为缺陷）

上一版注释里写的是「Java：空白页中转 2s → 重载」。这次把 smali 拆开看：

```
onPanic() → releaseTextures(true)   // 只释放纹理，且带 15s 冷却
```

`releaseTextures` 里**没有任何 `WebView.loadUrl` / `reload`**（整个库里唯一那处
`web.reload()` 属于 `onGpuExhausted` 的 `$3`，走的是 GPU 上下文那条路）。
真正让页面回来的是 `mole_boot.js` 里那个 6 秒兜底：

```js
setTimeout(function () { … if (hasPanic(p)) location.reload(); }, 6000);
```

**也就是说「崩了以后红屏挂 6 秒」从来不是设计，是没人接手的空档。**
这一版把这段空档换成了崩溃页。

---

## 三、新功能一：崩溃页（`shell.html` 第 10 段）

panic 被侦测到之后，不再自动重载，而是盖上一张全屏页：

- 顶部左：`摩尔庄园 · 微端 · 崩溃现场`；**右上：「↗ 分享日志」**
- 正文：`(｡•́︿•̀｡)` +「呜……好像卡住了」+ 一句人话解释
- 现场五行：原因 / 版本 / 引擎（后端+档位）/ 已运行 / 崩溃次数
- 三个按钮：`重新进入`（主）/ `复制报告` / `关于本作`
- 底部一句：本作是第三方移植，与官方无关

**分享按钮**走的是 1.2.4 已经打通的通道：`MoleBridge.reportCrash(name, txt)`
→ 落盘 `getExternalFilesDir("crash")/mole-crash-*.txt` → `ACTION_SEND` + `createChooser`。
分享面板里选 QQ 就能直接发到群里 —— 正文整段塞在 `EXTRA_TEXT` 里，
不需要 FileProvider，也不额外要任何权限。

同时**静默落一份底**：`__moleCrash.save()` → `MoleBridge.saveCrash()` →
`CrashReport.save()`（从 `share()` 里拆出来的纯写文件版本，不弹任何东西）。
用户看一眼就点「重新进入」甚至直接杀进程，现场也还在。

调试口：`__moleCrashPage.show('原因', {…})` / `.share()` / `.hide()` / `.state()`。

**边界**：只操作自己的浮层 DOM，绝不往 player 里写任何东西 ——
panic 之后 `player` 已经 `destroy()`，再碰它就是第二次 panic。

---

## 四、新功能二：「关于本作」交回系统原生弹窗（第 11 段）

要求是「调用原生安卓弹窗」，那就真的走原生，不用网页自己画框。

### Android

新增 `AboutDialog.smali` + `AboutDialog$1.smali`：

- `AlertDialog.Builder` + `Html.fromHtml()`，第二段用 `<font color='#E23A3A'>`
  包住 —— 渲染出来是 `ForegroundColorSpan`，**是真红字**，跟随系统深浅色与字体缩放；
- 按钮只有一个 `我知道啦 ♡`（`setPositiveButton` 传 null listener，点完即关）；
- 「只弹一次」记在 `SharedPreferences("mole_shell")` 的 `mole_about_v1`，
  用户清 WebView 缓存 / localStorage 之后照样不重复骚扰；
- 桥调用落在后台线程 → `showOnce` / `showForce` 都 post 到主线程再建框。

`MoleBridge.showAbout(force:boolean)`：`false` = 按标记只弹一次，`true` = 强制再弹
（崩溃页那个「关于本作」按钮用）。

### 鸿蒙（纯血鸿蒙原生弹窗）

网页侧按 UA 分派：`/ArkWeb|OpenHarmony|HarmonyOS/i` → 调
`NativeBridge.showAbout(json)`，`json` 是 `{title, lines:[{t,red}], ok}`。
ArkTS 侧参考实现见 **`harmony/AboutDialog.ets`**（`@CustomDialog` +
`preferences` 记标记 + `registerJavaScriptProxy` 注册片段）。

用 `CustomDialog` 而不是 `AlertDialog.show`，是因为后者的 `message` 只收
`string | Resource`，**没法只让一段变红**；`CustomDialog` 同样是系统原生弹窗容器
（独立窗口、系统返回键、字体缩放、无障碍朗读都归系统管），内部用 `Text` 就能逐段上色。

### 都没有（浏览器调试 / 旧壳层）

页内兜底弹窗，红字段落用 CSS 标红，行为一致。

### 文案（内容与原意一字未改，只把语气改软）

```
谢谢你选择了我这么一个小小的开源项目～能在这里遇见你，真的很开心！♡

小提醒一下：本作并非摩尔庄园官方项目，仅为第三方爱好者移植，
请不要和官方版本的《摩尔庄园》手游混淆哦！！！          ← 红字

本作目前还在开发阶段，遇到问题欢迎随时指出～另外郑重说一句：
严禁倒卖，也严禁在二次修改时加入收费弹窗；如果发现任何以此盈利的行为，
欢迎大家向我反馈！
```

---

## 五、鸿蒙为什么这一轮还是没出 HAP

四个硬条件一个都不满足：

1. **没有工具链**：开发机的 DevEco Studio 与 SDK 已删除，没有 `hvigor` / `ets-loader`，
   编不出新的 `modules.abc`；
2. **仓库里没有 ArkTS 工程**：`src/` 只有 `java` / `manifest` / `web`，`EntryAbility` /
   `NativeBridge` 的源码不在仓库里，无法编译；
3. **没有容器**：1.2.0 那次是拿 `entry-unsigned-111.hap` 当底、只换 `rawfile` 再重签，
   这份容器与 `signing/` 材料本机都找不到了；
4. **这次动的不只是网页资源**：新增了一个原生弹窗通道（`NativeBridge.showAbout`），
   只替换 `rawfile` 是带不进去的，必须重编 ArkTS。

**恢复条件**：DevEco + SDK 就位后，把 `harmony/AboutDialog.ets` 贴进工程、
在 `EntryAbility.onWindowStageCreate` 里 `registerJavaScriptProxy(…, 'NativeBridge', ['showAbout'])`
再 `refresh()`，然后照常 `hvigor assembleHap` 即可。ARKTS 侧只依赖
`@kit.AbilityKit` / `@kit.ArkData` / `@kit.BasicServicesKit`，都是系统 kit，无第三方依赖。

> 注：HarmonyOS 4.x 及以前可以直接装 APK，本轮的 APK 在那些机器上照常可用；
> 只有 HarmonyOS NEXT（纯血）必须走 HAP。

---

## 六、没有动的

| 项 | 状态 |
| --- | --- |
| 画幅 | 960×560 + letterbox，`#wrap` 与 `transform: scale(f)` 未动 |
| 帧率 | `frameRate 24`、rAF 泵未动 |
| 节流器 | 未动 |
| 画质 | `quality: 'low'`、`DENSITY` / `MAXPIX` / `FLOOR` / `budgetNow()` 计算式未动 |
| 像素预算档位 | `PIXEL_BUDGETS` 数组本体未改（只修了日志里那句读错的「生效」） |
| 输入法守卫 | 五层守卫未动 |
| 纹理回收 | `__molePurgeTex` / `__moleSetBudget` 策略未动 |
| OmniPad | 本体未动；崩溃页会临时 `display:none` 掉 `#pad`（player 已死，留着只会接走点击） |
| 服务器地址 / 端口池 | 未动 |
| Manifest | 未动（`saveCrash` 走 `getExternalFilesDir`，本来就不需要新权限） |

---

## 七、构建与签名

```bash
# 1) 网页资源同步进 dec
cp src/web/shell.html src/web/mole_boot.js <build-env>/dec/assets/ruffle/

# 2) 版本号
#    dec/apktool.yml → versionCode 27 / versionName 1.2.6-beta

# 3) 重打包
java -jar apktool.jar b dec -o unsigned-1.2.6-beta.apk

# 4) 对齐 + 签名（v1 + v2 + v3）
zipalign -p -f 4 unsigned-1.2.6-beta.apk aligned-1.2.6-beta.apk
apksigner sign --ks keystore/mole-release.jks --ks-key-alias mole \
  --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true \
  --min-sdk-version 21 --out mole-flash-1.2.6-beta.apk aligned-1.2.6-beta.apk
```

密钥：`build-env/keystore/mole-release.jks`（PKCS12，RSA 4096，alias `mole`，
口令 `MoleFlash2026#beta`）。**不进仓库。**

---

## 八、验证

| 项 | 结果 |
| --- | --- |
| `aapt2 dump badging` | `com.taomee.mole` / `versionCode 27` / `versionName 1.2.6-beta` / minSdk 21 |
| `apksigner verify --verbose` | v1 true、v2 true、v3 true |
| `zipalign -c 4` | 通过 |
| `dexdump` 类数 | 28（1.2.5 是 26，新增 `AboutDialog` 与 `AboutDialog$1`） |
| 新方法 | `CrashReport.save(...)Z`、`JsBridge.saveCrash(String,String)`、`AboutDialog.showOnce/showForce/show`、`JsBridge.showAbout(Z)` |
| dex 里的中文字面量 | 标题、三段文案、`font color='#E23A3A'`、`我知道啦 ♡` 全部逐字核对 |
| 包内 assets | `shell.html` `37f9843a…`、`mole_boot.js` `96600f71…`，与源码一致 |
| 离线断言 | text 24、clock 34、bg 54、panic 50、dpad 22、crashui 40 —— 全绿；`pad_test` 79/17，与既有基线一模一样 |

`panic_test` 41 → 50：新增 4d（崩溃页可用 → 停住、静默落盘、不重载、不自动分享）
与 4e（崩溃页建不起来 → 退回自动分享 + 重载）。
新增 `tests/crashui_test.js`（40 条）：崩溃页建页 / 分享桥文件名与正文 / 无桥退化成复制 /
`hide()`；关于弹窗的安卓原生分派、鸿蒙 `NativeBridge` 的 JSON 载荷（三段、第二段 red=true）/
页内兜底的红字与「只弹一次」/`force` 绕过。

---

## 九、已知限制

1. **panic 本身没被修掉**。栈溢出在 wasm 内部，第三方壳层碰不到 AS3 的递归；
   这一版把它从「红屏 + 无限重载」变成「一页说明 + 可分享 + 手动重进」。
   若后端降到 `canvas` 仍在同一处崩，就是内容侧递归，只能等 Ruffle 上游。
2. **崩溃页不是「游戏内页面」意义上的跳转**，是全屏覆盖层。真跳转到另一个 URL 会
   丢掉 WebView 里的一切（含还没落盘的报告），反而更糟。
3. **鸿蒙侧只有网页调用点 + ArkTS 参考实现**，未编译、未真机验证。
4. **`AboutDialog` 用的是 `Html.fromHtml(String)` 单参重载**（API 24 起标 deprecated，
   但仍可用）；未来若要支持 HTML 表格之类再改用 `FROM_HTML_MODE_LEGACY`。
5. 崩溃页里 `崩溃次数` 读的是 `sessionStorage.mole_panic_n`，随本次启动重置 ——
   与后端降档的 `localStorage.mole_renderer_tier` 刻意不共用一个计数。
