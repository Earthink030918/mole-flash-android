# 摩尔庄园 Flash 微端 · Android

> 把官方网页版的 Flash 客户端装进 Android WebView，用 [Ruffle](https://ruffle.rs) 跑起来，
> 再用一条本地 WebSocket 隧道把 Flash 的 raw Socket 接到游戏服务器上。

不是官方产品，与淘米网络无关，不含任何游戏资源文件。个人在自己的手机上跑老 Flash 游戏用的兼容层。

| 项 | 值 |
| --- | --- |
| 包名 | `com.taomee.mole` |
| versionCode / versionName | 1 / 1.0 |
| minSdk / targetSdk / compileSdk | 21 / 35 / 35 |
| 引擎 | Ruffle（WebAssembly，`wgpu-webgl` 后端） |
| 入口 | 单 Activity，`MainActivity`（横屏锁定） |
| 代码量 | 23 个类，约 2.6k 行（含匿名内部类） |

---

## 它到底在干什么

网页版摩尔庄园是一个 AS3 的 `Client.swf`，靠 `flash.net.Socket` 直连大厅服务器（TCP 1863 一类端口）。
Ruffle 在浏览器里能跑画面，但**跑不了 raw TCP**，所以这里补了两件事：

1. **本地 WebSocket → TCP 中继**（`SocketBridge`）
   在 `127.0.0.1` 上起一个 WebSocket 服务，页面侧用一小段 polyfill 把 Flash 的 `Socket` 调用改写成
   `ws://127.0.0.1:<port>/?host=…&port=…`，Java 侧收到后开真 TCP、双向泵字节。
2. **本地壳页下发**（`shell.html` + `MainActivity.shellResponse()`）
   `loadUrl("http://mole.61.com/__mole_shell__")` 被 `shouldInterceptRequest` 拦下，直接返回 assets 里的空壳页，
   并把字体清单、socket 目标列表、渲染预算、后端名替换进去。

其余都是围绕这两件事的补丁：老 SWF 24fps 的帧率还原、CJK 字体注入、磁盘缓存、GPU 显存看护、崩溃后自动降档。

```
┌──────────────────────────── Android App ────────────────────────────┐
│                                                                     │
│  MainActivity                                                       │
│   ├── WebView ──── shell.html (assets) ── mole_boot.js              │
│   │                 └── Ruffle (ruffle.js + wasm)                   │
│   │                       └── /Client.swf ← upstream 代理取官网 SWF  │
│   ├── SocketBridge  ← 127.0.0.1 WebSocket 服务 → TCP → 游戏服务器    │
│   ├── HttpCache     ← /cache 静态资源落盘（SWF/图片/js/css）         │
│   └── CrashProbe    ← ApplicationExitInfo 判定连续崩溃，自动降档     │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 目录

```
.
├── docs/
│   ├── architecture.md        逐层拆解：启动时序、请求路由表、状态机
│   ├── decompile-report.md    反编译方法与结果说明（工具、版本、坑）
│   ├── build.md               从这份源码重建 APK 的步骤
│   ├── troubleshooting.md     logcat 关键字对照表 / 常见黑屏排查
│   ├── classes_inventory.txt  dex 中的全部类
│   └── strings_urls.txt       dex 中出现的域名与 URL 字面量
├── src/
│   ├── java/com/taomee/mole/  反编译得到的 Java 源码（23 个文件）
│   ├── web/shell.html         WebView 端空壳页（含帧率节流、缩放、HUD）
│   ├── web/mole_boot.js       把 /Client.swf 挂给 Ruffle 的引导脚本
│   └── manifest/AndroidManifest.xml  解码后的清单
├── third_party/ruffle/        Ruffle 的 MIT / Apache-2.0 许可证原文
├── tools/run_decompile.py    本次反编译所用脚本（可复现）
└── README.md
```

## 构建

见 [`docs/build.md`](docs/build.md)。简要说：这份 `src/java` 是**反编译产物**，不能直接 `javac` 通过，
需要人工合并 `access$NNN` 合成方法后才能编译；`src/web` 与 `src/manifest` 是 1:1 可用的原件。

Ruffle 的二进制（`ruffle.js`、两个 `*.wasm.gz`）体积约 10 MB，未纳入本仓库，从
[Ruffle releases](https://github.com/ruffle-rs/ruffle/releases) 取对应版本放进 `assets/ruffle/`。

## 已知限制

- 只处理了 `Client.swf` 这一条主链路，`WordMapMainPanel` 之类子 SWF 靠上游代理直通。
- 服务器地址是「种子 + 学习」两段式：三个种子主机 × 端口区间（1860–1880 / 3195–3215 / 6650–6700），
  运行中 Ruffle 报缺代理时会补录并落盘，不保证长期有效。
- 依赖 WebView 的 WebGL；Adreno 上 wgpu 过不了某些着色器校验会 panic，靠 `onPanic` 清空重载兜底。
- 帧率节流固定 24fps，遇到高帧率小游戏会显得「卡」，这是刻意的。

## 许可

本仓库中由本人编写的部分（`src/java`、`src/web`、`tools`）以 [MIT](LICENSE) 发布。
`third_party/ruffle` 下的 Ruffle 为 MIT / Apache-2.0 双许可，遵循其原始条款，见
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)。

游戏本体（`Client.swf` 等）版权归上海淘米网络所有，**不在本仓库内，也不随本仓库分发**。
