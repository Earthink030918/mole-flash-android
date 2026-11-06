# 1.1.5-beta —— 华为 MatePad / 鸿蒙 4.2 红屏与卡死

基线 1.1.4-beta（versionCode 18）→ 本版 **1.1.5-beta**（versionCode 19）。
只改 `assets/ruffle/shell.html` 与 `assets/ruffle/mole_boot.js`。
Java 壳层、画幅、画质、帧率、节流器、像素预算、输入法配置**一律未动**。

产物：`mole-1.1.5-beta.apk`，10,331,524 B，
SHA-256 `3b859f78ac35649630d4781cb637e53c5358f81826ef64f7c9b7ed9f1cc9bee9`，
证书 `974ea1b9…0093`（同 v1.1.0，可覆盖安装）。

---

## 现象

群友（华为 MatePad 11 / 鸿蒙 4.2）反馈：运行中整屏变成红橙渐变，
上面一句 "Something went wrong :("，随后 Ruffle 完全停摆；
有时已经登录进游戏了才出现卡死。

## 定位（四处，都能指到具体代码行）

### 1. 那块红屏是 Ruffle 自己的 panic 面板，不是我们的页面

`ruffle.js` 里有一条样式：

```css
#panic{background:linear-gradient(180deg,#fd3a40,#fda138);color:#fff;...}
```

`#fd3a40 → #fda138` 就是用户说的"红屏"。它由 `player.panic(err)` 渲染，
渲染完立刻 `this.destroy()` —— **wasm 已经 panic，播放器对象被销毁**，
所以"整个 ruffle 崩溃"是准确的描述，不是卡帧。

`panic()` 的调用点在 ruffle.js 里只有 6 处：核心 js/wasm 下载失败、
`instance.build()` 失败（渲染后端创建）、SWF 下载失败、SWF 解析失败、
配置非法、以及 reload 时的重入保护。

### 2. 我们原本的 panic 兜底是**死代码**（本版主修）

`mole_boot.js` 里原来这么写：

```js
var types = ['loadedmetadata', 'loadeddata', 'progress', 'error', 'panic', ...];
p.addEventListener('panic', function () { MoleBridge.onPanic(); });
```

`p` 是 `<ruffle-player>` 元素。但 Ruffle 的 web 播放器从头到尾**只派发两个
CustomEvent**：

```
$ grep '"panic"' ruffle.js     → 1 处，而且是 rt() 里的 DOM id
$ grep 'new CustomEvent('      → loadedmetadata / loadeddata
```

也就是说 `'panic'` 事件根本不存在，`MoleBridge.onPanic()` **一次都没被调用过**。
Java 侧那套"空白页中转 2s → 重载"的恢复逻辑写得挺完整，但入口是空的 ——
这就是"红屏之后就一直挂着、日志里什么都没有"的直接原因。

### 3. 面板在 shadowRoot 里，不在 light DOM

`panic()` 把面板 append 到 `this.container`，而

```js
this.container = this.shadow.getElementById("container");   // attachShadow 出来的
```

所以 `player.querySelector('#panic')` 永远查不到 —— 侦测必须走 `player.shadowRoot`，
并且要 `childList + subtree`（面板挂在 `#container` 这个后代节点下）。

### 4. 就算兜底触发了，也修不好：后端是写死的，引擎自己的退路走不到

Ruffle 的 `web/src/builder.rs`：

```rust
let mut renderer_list = vec!["wgpu-webgl", "webgpu", "webgl", "canvas"];
if let Some(preferred_renderer) = &self.preferred_renderer { 移到最前 }
// Try to create a backend, falling through to the next backend on failure.
for renderer in renderer_list { ... }
```

退路只在**创建失败**时生效。而 wgpu 在华为 / Adreno 驱动上是在**绘制阶段**
才炸的（`create_render_pipeline` 的着色器校验、device lost），
`create_renderer()` 那一刻是成功的 —— 于是 webgl / canvas 这两级永远试不到，
重载多少次都还是同一个后端，**必然复现**。

而壳层这边 `MainActivity.preferredRenderer()` 是：

```java
const-string v0, "wgpu-webgl"
return-object v0
```

常量。shell.html 注释里写的"由 Java 侧按崩溃历史注入 —— 崩过一次就自动降一档"
**从来没有实现过**。这是"华为这台机器每次都红屏"的结构性原因。

---

## 改动

### A. panic 侦测（`mole_boot.js`，新增 `watchPanic` / `onPanicDom` / `panicText` / `hasPanic`）

- 盯 `player.shadowRoot` 的 `childList + subtree`；播放期间 shadow 里几乎没有
  节点增删（菜单是 class 切换，不触发 childList），开销可忽略；
- 另加 5s 巡视兜底（观察器建不起来、或面板早在挂载前就出现）；
- 命中后一次性读取 `#panic-title` / `#panic-body` / 详情 `textarea`，
  压成一行写进 logcat（走既有的 console 管道，标签 `!!`）；
- 每个播放器只处理一次（`__molePanicAt`）。

### B. 渲染后端降级阶梯（`shell.html` 新增第 0.3 段）

```
档位 0  wgpu-webgl   默认，功能最全
档位 1  webgl        原生 WebGL1 后端，完全绕开 wgpu 管线，观感基本一致
档位 2  canvas       纯软件，最后兜底；慢，但一定出画面
```

- 档位存 `localStorage['mole_renderer_tier']`，**只在本机真的 panic 过之后**
  才会往下走，正常设备一个字节都不变；
- 判定是否要降级看 panic 文本：命中
  `wgpu|webgl|webgpu|render|adapter|swap chain|context|surface|device lost|pipeline|shader|texture|out of memory|gpu`
  才降级；内容类 panic（`AVM2 instruction not supported`、SWF 解析失败）不降级
  —— 那种换后端也没用，没必要白降画质；
- 降级之后靠"重载"生效（档位在页面最前面读，早于 ruffle.js）。

### C. 恢复策略（防无限闪烁）

- 会话内 panic 计数放 `sessionStorage`（随本次启动重置；放 localStorage 会让
  一台常年 panic 的机器永远爬不出来，放内存变量则重载一次就归零、变死循环）；
- 上限 4 次，到顶就**停手**：红屏保留，日志写"停止自动恢复"；
- 第一次通知走 `MoleBridge.onPanic()`（Java：空白页 2s → 重载，给 GPU 一个
  释放显存的窗口）；若 Java 那条路被它自己的 15s 防抖挡住（等于什么都没做），
  6s 后面板还在、页面可见 → 页面自己 `location.reload()`。此时 Java 的两步
  早已走完，不会打架。

### D. 诊断用（都只写日志，不改任何行为）

- 启动与每次挂载都打一次**实际选中的渲染器**：`player.rendererDebugInfo`
  （Ruffle 把 `create_renderer` 的最终结果写在这里，含 Adapter / Backend）。
  华为设备排障全靠这一行 —— 它能直接回答"到底是 wgpu 还是退到了 webgl"。
- **主线程冻结看门狗**：每秒打点，两次间隔 > 8s 且页面可见就记一行
  `!! 主线程疑似冻结 Ns`。卡死时 rAF/定时器/console 全停，日志必然空白，
  这是唯一能留下的信号。只记，不重载（避免把偶发长帧误判成崩溃）。

### E. 拆掉死代码

`'panic'` 从事件类型表里删掉，注释写明原因 —— 留着一个永远不会触发的监听，
只会让人以为"兜底已经有了"。

---

## 没动的东西

画幅（`#wrap` 尺寸与 transform）、画质（`quality` / DPR 预算 / MAXPIX）、
帧率（`frameRate: 24` 与 rAF 泵）、节流器、输入法（`deviceFontRenderer:'canvas'`、
软键盘那一段）、Java 壳层（一个 smali 字节都没改）、服务器地址。

新增的常驻开销：1 个 1s 定时器（读 `Date.now()`）、5s 巡视里多两次
`getElementById`、一个 shadow `childList+subtree` 观察器（无节点增删时零回调）。

---

## 验证

- `node tests/panic_test.js` → **ALL PASS 34/34**（新增，钉死：面板在
  shadowRoot、文本抽取、GPU/内容两类判定、单次去重、次数上限、
  `sessionStorage` 计数、桥不可用时自救、档位表读取/钳制/到底 bump 返回 null）
- `clock_test` 34/34、`bg_test` 54/54、`text_test` 24/24 全绿；
  `pad_test` 79/17 是 1.1.1-beta 改几何后就没更新的既有红，与本次无关
- 包内 `assets/ruffle/shell.html`（189,886 B）与 `mole_boot.js`（19,614 B）
  均与工作副本 `cmp` 一致，纯 LF
- `aapt dump badging`：`versionCode='19' versionName='1.1.5-beta'`、
  `targetSdkVersion:'31'`、`minSdkVersion:'21'`
- `apksigner verify`：证书 `974ea1b9…0093`

## 真机上要看的那一行

```
adb logcat -s MoleShell | grep -E "!!|渲染器实际情况|降级档位"
```

关键是把这一行发回来：

```
!! panic 文本: Something went wrong :( | Error creating player: ...
```

有了它就能判断是渲染后端、还是内容/内存，再决定要不要继续往下压。
如果自动恢复生效，会看到 `!! 判定为渲染后端不兼容 → 下次改用 webgl`，
之后启动日志里的 `降级档位=1`。

想把这台机器手动放回最高档（比如换了系统版本、驱动更新了）：
清除应用数据，或在控制台执行
`localStorage.removeItem('mole_renderer_tier')` 后重启。
