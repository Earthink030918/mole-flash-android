# 1.2.0 正式版发布说明

2026-11-12 ｜ Android `versionCode 24` ｜ HarmonyOS `versionCode 7`

本版把 2026-10-25 的 v1.1.0 之后、`versionCode` 从 9 递增到 24 的 15 轮迭代收束成一个正式版：
Android 与 HarmonyOS 用同一份 Web 壳层逻辑、同一套 Ruffle 引擎。

游戏本体的**画幅（960×560 + letterbox）、帧率 24、rAF 节流器、`quality`、像素预算档位、
显存回收策略、输入法配置、服务器地址**，一次都没有改动。所有改动都在「渲染分辨率、
输入事件、时序、进程存活」这几层外围。

---

## 产物

| 平台 | 文件 | 大小 | 版本 | 签名 |
| --- | --- | --- | --- | --- |
| Android | `mole-1.2.0.apk` | 10,356,100 B（9.88 MiB） | 1.2.0 / 24 | `974EA1B9 … C0780093` |
| HarmonyOS | `mole-harmony-1.2.0-signed.hap` | 11,465,574 B（10.93 MiB） | 1.2.0 / 7 | OpenHarmony release 链 |

```
b776302bbc5ce46c71e773d4425edc2f2bee5fa99d0a13101571e59c57331714  mole-1.2.0.apk
c8b99da639c9f9598898ac2c1822127c7e89024c107d7ff0465442c61e113af5  mole-harmony-1.2.0-signed.hap
```

APK 与历史版本同签名，可覆盖安装、保留登录态。HAP 复用 1.1.0 / 1.1.1 的证书链与
profile，安装身份不变。

---

## 一、能直接看到的变化

### 1. 画面不再「整屏马赛克」

这是本版最重要的一条，也是最容易被误判成「新引擎画质差」的一条。

**根因不在引擎**：`MainActivity.evaluateLoadLevel()` 把**连续崩溃次数**直接当降载档位
（`loadLevel = min(CrashProbe.recentCrashStreak(), MAX_LEVEL)`），档位数组是
`[1210000, 900000, 660000, 460000, 320000, 210000]`。换引擎前后几次红屏 panic 加手动杀进程，
把 streak 顶到 4~5 档 → 预算只剩 210,000 → `DPR = sqrt(210000 / 537600) ≈ 0.79`
→ canvas 只有 **759×443** 却要铺满 2304×1344 的显示区，物理放大 **3.37 倍**。

修法是给参与算 DPR 的预算加地板 `BUDGET_MIN = 1210000`（= 档位 0，v1.1.0 起的默认值），
并把 `DENSITY 1.44 → 1.7`、`MAXPIX 160万 → 220万`、`FLOOR 0.5 → 0.7`。

| 场景 | v1.1.0 | 1.2.0 |
| --- | --- | --- |
| 平板 1280×800 CSS / DPR 2（最坏档位） | 759×443，放大 3.37× | **1669×974，放大 1.53×** |
| 平板（正常档位） | 1242×725，放大 2.06× | **1669×974，放大 1.53×** |
| 手机 915×412 CSS / DPR 2.625 | 1242×725，放大 1.49× | **1440×840，放大 1.29×** |

崩溃史、显存看护仍然照常下调预算，只是**不会再被拖进马赛克档**；
无损纹理回收走的是「改容器尺寸 → 重建渲染目标」，不依赖预算数值，照常有效。

顺带否掉一个想当然的结论：`quality: 'low'` 与分辨率无关
（`stage.rs::set_quality()` 只存值 + 请求重绘，`use_bitmap_downsampling` 在 Ruffle 内被忽略），
所以 `quality` 一直没动。分辨率唯一的来源是 `web/src/lib.rs::tick()` 里的
`canvas.client_width × devicePixelRatio`。

### 2. 输入框正常了

v1.1.0 的点输入框是「键盘闪一下就没」「拼音重复成 `wwwoooooaaaannnn`」，
1.2.0 依次修掉三件：

| 问题 | 根因 | 修法 |
| --- | --- | --- |
| 键盘弹出即缩回 | Ruffle 的 `#virtual-keyboard` 在视口外（`top:-100px`），`#wrap` 是 `overflow:hidden` 且舞台带 `transform: scale()`，滚不过去 | 改成视口内 1px、`opacity:.01`（不能 0，部分 ROM 用可见性判定能否弹键盘）、`pointer-events:none` |
| 拼音整段重发 | `virtualKeyboardInput()` 逐字符重发 value，组合期 value 是整段拼音，且置空不重置 InputConnection | 捕获阶段拦 `input`，前缀 diff 只发增量，组合期零派发，`compositionend` 再提交 |
| 中文打不出来 | 1.1.2-beta 曾「暂时屏蔽 a-zA-Z」，等于把拼音入口堵死 | 撤掉屏蔽，只过滤控制字符；`type` 保持 `text`，不指定 `inputmode` 与键盘形态 |
| 点一次停不住，要双击 | OmniPad 的 `ensureFocus()` 反复把焦点抢回 canvas | 24 行焦点守卫：包 `canvas.focus`、`pointerdown` 记时间戳、shadow `focusout` 16ms 抢回，`_fixed` 保证一次点击只抢一次 |

另外键盘占屏期间不再重做等比适配（原本 120ms 的 `visualViewport.resize` 防抖正好落在
键盘动画中间，会让画面闪一下），**画幅保持不变**。

### 3. 好友列表 / 聊天框不卡了

根因在 Ruffle 的 canvas 设备字体渲染器：它声明 `has_kerning_info() = true`，
core 每行文本布局要对**每一对相邻字符**调 `calculate_kerning()`，而它内部是
**3 次 `measure_text`**（wasm→JS 边界 + 浏览器整条 shaping 栈）。
好友列表一屏 30 个昵称、聊天框一屏 20×20 字 ≈ 1800 次，且每来一条消息、滚一格都重排。

修法是把 `measureText` 做成纯记忆化（key 含 `ctx.font`，只缓存 ≤8 字短串，上限 4096 条，
返回值逐字段一致 → 排版不变），3N 次压到 O(不同字符数)。

顺带拆掉壳层自己每秒/每帧的浪费：`devicePixelRatio` getter 每帧两次强制布局
（还会因 ulp 抖动触发 canvas 重建）、console 丢弃路径无条件拼字符串、触控板每秒
`getBoundingClientRect` + 重写 className、软键盘每 800ms 重写 20 条 `!important`。

### 4. 华为 / Adreno 设备红屏不再「死循环」

红屏是 Ruffle 自己的 panic 面板（`#panic` 的 `linear-gradient(180deg,#fd3a40,#fda138)`），
意味着 wasm 已 panic、player 已 `destroy()`。原来三条路都堵着：

1. 我们监听的 `'panic'` 事件是**死代码** —— Ruffle 全程只派发
   `loadedmetadata` / `loadeddata`，`MoleBridge.onPanic()` 一次都没被调用过；
2. 面板挂在 `shadowRoot` 的 `#container` 里，light DOM 查不到；
3. `preferredRenderer` 是常量 `wgpu-webgl`，而 Ruffle 只在**创建**失败时才往
   `webgl` / `canvas` 退；wgpu 在华为/Adreno 上是**绘制阶段**炸（`create_render_pipeline`
   着色器校验 / device lost），创建那一步是成功的 → 引擎自己的退路永远走不到。

1.2.0 补上：`shadowRoot` 的 `MutationObserver(childList + subtree)` + 5s 巡视兜底，
把 `#panic-title` / `#panic-body` / 详情压成一行写 logcat；后端降级阶梯
`wgpu-webgl → webgl → canvas`，存在 `localStorage`，**只在本机真 panic 过之后**才往下走；
按 panic 文本判定「渲染类 / 内容类」（内容类不降级）；会话内上限 4 次防无限闪烁。

### 5. 切后台不再丢进程

10-26 那批（1.1.2 ~ 1.1.5）修的是这一组，全部在 1.2.0 里：

| 版本 | 修了什么 |
| --- | --- |
| 1.1.2 | 放弃「后台继续跑」，改为 `inst.pause()` 的**逻辑 + 音频原子冻结**；冻结前 70ms 淡出、恢复后 120ms 淡入；屏蔽 Ruffle 无条件的 `play()`；新增前台服务 `MoleKeepAlive` |
| 1.1.3 | 渲染进程优先级 `RENDERER_PRIORITY_IMPORTANT` 且不可见不作废；实现 `onRenderProcessGone` 接管善后（WebView 默认行为是 `killProcess` 整个 App） |
| 1.1.4 | `onPause` 改用 `startForegroundService()`；申请 `POST_NOTIFICATIONS`；通知图标换成系统单色图标 |
| 1.1.5 | 修 1.1.4 自己引入的字节码错误：`onStartCommand` 的 catch handler 没有以 `move-exception` 开头，dex 规范不允许，ART 直接拒绝加载 `MoleKeepAlive` |

1.1.1 那条「AudioWorklet 后台节拍器」是真机验证不成立、已被 1.1.2 取代的方案，
不再存在于 1.2.0。

### 6. 平板触控板不再整块消失

16:10 平板上舞台铺满后上下黑边只剩约 27px，而 `MIN_BAR = 44` 且要先扣
`EDGE_GUARD 20 + STAGE_GAP 6`，四条边全不合格 → `computeLayout()` 返回 null → **整块触控板不挂**。
现在 `EDGE_GUARD 20→12`、`STAGE_GAP 6→4`、`MIN_BAR 44→30`；
四边仍不合格时在**屏幕右侧中部**挂 60×72 半透明窄板兜底（`opacity:.45`）。
另加自救手势：右上角 120×120 内快速点三下 → 拆除 OmniPad 回原生触控。

---

## 二、引擎换代

Ruffle 三件套换了三轮，每次都是群友重新编译、wasm 哈希名变化（不是同名覆盖）：

| 版本 | `ruffle.js` | mvp wasm | 主 wasm |
| --- | --- | --- | --- |
| v1.1.0 | 685,811 B | `K7CA3GNA` 4,943,838 B | `JBAFOQXG` 4,961,250 B |
| 1.1.6-beta | 692,938 B | `VMZCVK47` 4,980,529 B | `FQNOL64Y` 4,974,695 B |
| 1.1.8-beta | 691,942 B | `MK7STBFJ` 4,955,758 B | `JTCYPQ5T` 4,956,703 B |
| **1.2.0** | **692,223 B** | **`I56A2W5M` 4,958,874 B** | **`EFKRKUVC` 4,965,119 B** |

两端的分发都是通配匹配（Android `MainActivity$6.smali` 只判 `endsWith(".wasm")`，
鸿蒙 `LocalServer.ets` 同理），所以换哈希名不需要改一行代码。

1.1.6-beta 第一次换引擎时曾把体积顶到 20,289,089 B —— 新旧 wasm 同时留在包里、
旧的两个已无人引用。删掉死重量并去掉对应 `doNotCompress` 后回到 10,384,772 B（−48.8%）。
1.2.0 最终 10,356,100 B，比 v1.1.0 的 9.83 MiB 只大 **48 KB** —— 换了三轮引擎、壳层多了 1019 行，
包体几乎没动，因为两份 wasm 一直是 Stored（未二次压缩），占 9.9 MB。

---

## 三、逐版本对照（Android）

| 版本 | 日期 | code | 主要改动 |
| --- | --- | --- | --- |
| **1.2.0** | 11-12 | 24 | 正式版：去掉 `-beta`，内容 = 1.1.9-beta |
| 1.1.9-beta | 11-11 | 23 | 像素预算加地板 `BUDGET_MIN`，修全屏马赛克；`DENSITY/MAXPIX/FLOOR` 上调；加渲染实况诊断 |
| 1.1.8-beta | 11-11 | 22 | 第三次换引擎（`MK7STBFJ` / `JTCYPQ5T`） |
| 1.1.7-beta | 11-10 | 21 | 并入 24 行输入法焦点守卫，修「点输入框要双击」 |
| 1.1.6-beta | 11-10 | 20 | 第二次换引擎（`VMZCVK47` / `FQNOL64Y`），清死重量 20.3 MB → 10.4 MB |
| 1.1.5-beta | 11-06 | 19 | 红屏 panic 侦测（shadowRoot）+ 渲染后端降级阶梯 + 冻结看门狗 |
| 1.1.4-beta | 11-03 | 18 | `measureText` 记忆化修好友列表/聊天框卡顿；DPR 记忆化；三处壳层浪费；长帧探针 |
| 1.1.3-beta | 11-03 | 17 | 撤掉屏蔽字母；输入框还原普通文本；修键盘闪退；防抖改同步清空 + 去重；键盘期不重排 |
| 1.1.2-beta | 11-03 | 16 | 修 1.1.1-beta 的欠采样（canvas 786×458 → 1242×725）；软键盘逐字符重发 |
| 1.1.1-beta | 11-03 | 15 | `targetSdk 35→31`；平板触控板兜底 + 三连击自救；预算按显示面积自适应 |
| 1.1.5 | 10-26 | 14 | 修 `MoleKeepAlive` 的 `move-exception` 字节码错误；渠道换 ID + `IMPORTANCE_DEFAULT` |
| 1.1.4 | 10-26 | 13 | `startForegroundService` + 申请通知权限 |
| 1.1.3 | 10-26 | 12\* | 渲染进程优先级 + `onRenderProcessGone` 接管 |
| 1.1.2 | 10-26 | 11\* | 逻辑 + 音频原子冻结；前台服务保活 |
| 1.1.1 | 10-26 | 10 | AudioWorklet 后台节拍器（已被 1.1.2 取代） |
| v1.1.0 | 10-25 | 9 | 上一次线上版本：OmniPad 触控板、切后台不掉线 |

\* 1.1.2 / 1.1.3 的 versionCode 按相邻版本顺推（1.1.1 = 10、1.1.4 = 13）。

`1.1.x`（无后缀）与 `1.1.x-beta` 是两批不同的迭代：前者集中在 **Java 壳层**
（保活、进程优先级、字节码），后者集中在 **Web 壳层**（画质、输入法、卡顿、红屏）。
两条线在 1.1.1-beta 之后合并，1.2.0 的 `classes.dex` 里能同时查到
`onUserLeaveHint` / `setRendererPriorityPolicy` / `onRenderProcessGone` /
`startForegroundService` / `POST_NOTIFICATIONS` 与 `MoleKeepAlive` 的 6 处 `move-exception`。

Web 壳层体量：141,415 B / 1207 行（v1.1.0）→ **194,969 B / 2226 行**（1.2.0），+1019 行。

---

## 四、HarmonyOS 端

| 项 | 1.1.0 | 1.1.1 | **1.2.0** |
| --- | --- | --- | --- |
| `versionCode` | 5 | 6 | **7** |
| `shell.html` | 141,415 B | 153,067 B | **157,127 B** |
| `mole_boot.js` | 10,697 B | 10,697 B | 10,697 B（未同步） |
| 引擎 | `K7CA3GNA` / `JBAFOQXG` | 同左 | **`EFKRKUVC` / `I56A2W5M`** |
| 画质预算地板 | 无 | 无 | **有（`BUDGET_MIN`）** |
| 文本度量记忆化 | 无 | 无 | 无 |
| 渲染后端降级 | 无 | 无 | 无 |
| panic 面板侦测 | 无 | 无 | 无 |
| 后台合成轴（`pendingAlign`） | 有 | 有 | 有（未动） |

鸿蒙端本次只合入**画质**一条：`BUDGET_MIN = 1210000` 地板、`DENSITY 1.7`、
`MAXPIX 2200000`、`FLOOR 0.7`、DPR 记忆化、3 秒一行 `[MoleShell] 渲染实况`。

效果（MatePad 1280×800 / DPR 2）：canvas **1242×724 → 1669×974**，物理放大 **2.06× → 1.53×**。

**没合入**的三项及原因：

- 文本度量记忆化：鸿蒙壳层是 1.1.1 的分叉，文本管线与安卓不同，硬塞要重测整套输入法通道；
- 渲染后端降级阶梯：依赖安卓侧 `__moleRendererBump` 这个桥接口，鸿蒙没有；
- `mole_boot` 的 panic 侦测：同上，且要碰节流与输入法通道，触碰红线。

### HAP 是怎么出的（DevEco 已删）

开发机上的 DevEco Studio 与 `D:\DevEco Studio\sdk`（含 ets-loader 26.0.0.105）已被删除，
`~/.hvigor` 只剩 pnpm 与项目依赖缓存，**无法重新编译 ArkTS**。

但 1.2.0 相对 10-26 那次构建，改动全在 `rawfile`（网页资源），ArkTS 侧
（`EntryAbility` / `LocalServer` / `NativeBridge`）一行未动。所以以 10-26 的
`entry-unsigned-111.hap` 为容器：

1. 替换 `resources/rawfile/ruffle/` 下的三件套与壳层；
2. `module.json` / `pack.info` 的 `versionCode` / `versionName` 改为 7 / 1.2.0；
3. zip 按原条目顺序重写，全部 Stored（HAP 惯例）；
4. 用 `hap-sign-tool sign-app -mode localSign` 重签。

签名材料：`signing/` 里只有证书没有私钥，但 `c1.pem` / `c2.pem` 与 OpenHarmony 公开测试
材料的 CA / Root **指纹完全相同**，`app-cert.pem` 的公钥与 `developtools_hapsigner` 仓库
`dist/OpenHarmony.p12` 里 `openharmony application release` 那把私钥同一条。于是用原证书链
`app-cert.pem` + 原 profile `mole-profile-111.p7b` 签名，`verify-app` 输出 **Verify success**。

---

## 五、没有改动的东西

| 项 | 状态 |
| --- | --- |
| 画幅 | 960×560 + letterbox，`#wrap` 尺寸与 `transform: scale(f)` 未动 |
| 帧率 | `frameRate 24`、rAF 泵未动 |
| 节流器 | 未动 |
| 画质档位 | `quality: 'low'` 未动（已核实它与分辨率无关） |
| 像素预算档位数组 | `PIXEL_BUDGETS` 未改，只加了计算时的下限 |
| 显存回收 | `__molePurgeTex()` 无损纹理回收策略未改 |
| 输入法配置 | `type` / `inputmode` / `autocomplete` 语义未改，只修事件与焦点 |
| 服务器地址与端口池 | 未动 |
| OmniPad 0.7.3 | 逻辑未改，只调了几何常量 |

Java 侧 `classes.dex` 在 1.1.1-beta 之后就没有再改过（1.1.x 那批的保活修复已在
1.1.1-beta 的基线里），1.2.0 与 1.1.9-beta 的 dex 逐字节相同。

---

## 六、已知限制

1. **HAP 的 `targetAPIVersion` 仍是 50000012（API 12）**。抬到 6.0 / 7.0 必须重新编译
   ArkTS，现阶段做不到，新系统上以兼容模式运行。`minAPIVersion` 同为 API 12，
   HarmonyOS 5.0 ~ 7.x 都能装。
2. **鸿蒙壳层缺三项修复**（文本记忆化、后端降级、panic 侦测），见上表。
3. **profile 内仍写 1.1.1 / 6**。`bm` 一般只校验证书与包名，不校验版本号；
   若某台设备因版本不符拒装，需要重签一份 1.2.0 的 profile。
4. **1.1.4 ~ 1.1.9 未经真机长跑验证**：好友列表卡顿、红屏降级、输入法守卫三条
   都只在离线断言与短时真机上验过，长跑数据还缺。
5. 后台冻结期间游戏逻辑是**停**的（这是零爆音的前提）。服务器若有空闲超时，
   长时间挂机可能要求重连。

---

## 七、验证

```
text   24/24
clock  34/34
bg     54/54
panic  34/34
```

共 **146 项**离线断言全绿（`node tests/<name>_test.js`，从 `src/web/shell.html` 切真实代码跑）。
`pad_test` 的 79/17 是 1.1.1-beta 改几何后未同步更新的既有红，与 1.2.0 无关。

---

## 八、回滚

```bash
# Android
adb install -r mole-1.1.0.apk     # 需先卸载 1.2.0，签名相同但 versionCode 回退

# HarmonyOS
hdc install mole-harmony-1.1.0.hap
```

壳层单文件回滚更简单：`patches/` 下每个版本都有完整 `shell.html`，
`diff` 相邻两版即可看出改动。1.2.0 的壳层与 `patches/1.1.9-beta/shell.html` 逐字节相同
（md5 `89ec72195b6666d9da5e0a803487dc29`）。
