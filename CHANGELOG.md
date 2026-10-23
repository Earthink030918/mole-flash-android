# Changelog

格式参照 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [1.0.3] - 2026-10-23

修复自 `1.0.1` 以来的稳定性与适配问题，含未单独发布的 `1.0.2` 内部迭代。

### Fixed

- **长时间运行后画面冻死**：`1.0.2` 的降载路径是 `raiseLoadLevel(+1)`，升到 `MAX_LEVEL` 后整条路径 `return` 空转；显存真正分配到失败时会进入 `context lost` 循环，进程不崩但画面再也不动。改为**无损纹理回收**：新增 `__molePurgeTex(minGapMs)`，复用 `#wrap` 跨帧 `+1px → 复位` 抖动让 Ruffle 重建渲染目标，仅归还纹理、不降画质档位；默认 240 秒冷却，避免抖动过于频繁
- **安卓边缘手势失效**：`1.0.2` 在 `onPageFinished` 里下发的 `setSystemGestureExclusionRects` 把屏幕两侧边缘划为游戏独占，系统侧滑返回被吃掉。整段移除，恢复系统手势
- `JSBridge` 的 `lost` 分支同样改走 `__molePurgeTex()`；`dead` 分支不再连带 `raiseLoadLevel(MAX_LEVEL)`，只保留 `reload`
- 三个显存闸门（`PIXEL_BUDGETS` 逐级下调点）的调用点全部替换为 `__molePurgeTex()`，`raiseLoadLevel` 在整个 App 内已无调用点

### Fixed（1.0.2，本次一并发布）

- **APP 隔一段时间自动重启**：三个来源合流——① GPU 看护里的 `releaseTextures` 会先白页再重建，观感等同重启；② `MainActivity$7` 补录端口后直接 `web.reload()`；③ `SocketBridge` 上行结束时把两侧一起 `closeQuietly`、下行 `read<=0` 时不同步关闭，`join` 永久挂死且线程池无界增长（实测线程 92→89 不回落）。三者分别改为：升档而非强释放、只落盘不重载、上下行对称关闭 + `newFixedThreadPool(24)`
- **进入金豆商城卡死**：`HttpCache` 把 `xml/ini/js/css/txt/json/cfg` 也纳入 7 天磁盘缓存，一次空响应就被钉死。改为静态扩展名白名单，只缓存 `swf/png/jpg/jpeg/gif/webp/bmp/mp3/wav/ogg/dat/bin`
- **触控 / 鼠标逻辑混乱**：`user-scalable=no` 在 Chrome 32+ 已失效，WebView 的捏合缩放仍开着，系统手势也会在边缘抢事件。`configure()` 内 `setSupportZoom` / `setBuiltInZoomControls` / `setDisplayZoomControls` 全部置 `false`，壳层补「输入加固」段：多指锁、屏蔽 `contextmenu` / `selectstart` / `gesturestart`、`overscroll-behavior: none`、`visualViewport` 缩放复位
- **一加全系平板 / ColorOS 17、红米 K90 适配**：随上述触控与手势修复一并覆盖（两者崩溃日志均来自边缘手势冲突与缩放状态残留）

### Changed

- `src/web/shell.html` 新增 `__molePurgeTex(minGapMs)`；`__moleSetBudget(px, force)` 增加 `force` 参数，可跳过早退强制重算
- `versionName` `1.0.1` → `1.0.3`，`versionCode` `2` → `4`

### Unchanged

- 画幅（`960x560`、`letterbox`）、`frameRate 24`、`quality low`、节流器与画面参数一律未动
- 服务器地址与端口池未动（`123.206.131.236` / `123.206.131.63` / `123.150.163.118`，端口 `1863/1865/3200/6665`）
- Ruffle 二进制未动：`assets/ruffle/ruffle.js` 与两份 `*.wasm.gz` 字节级一致，改动仅在 `shell.html`、`classes.dex`（约 50 KB 壳）

## [1.0.1] - 2026-10-19

本次更新更新了 APP 图标，图标来自群友授权赞助，感谢。

### Changed

- 应用图标更换为群友授权的摩尔庄园主题图标（`res/mipmap-*` 五档密度，48/72/96/144/192 px）
- `versionName` `1.0` → `1.0.1`，`versionCode` `1` → `2`

### Unchanged

- 除图标与版本号外，安装包内容与 `1.0.0` 完全一致（`assets/`、`classes.dex`、`resources.arsc` 未改动）

## [0.1.0] - 2026-10-18

首次公开。内容为对一个已构建 APK（`com.taomee.mole` v1.0，versionCode 1）的反编译整理。

### Added

- `src/java/`：23 个类的 Java 源码（androguard 4.1.4 / DAD 反编译）
- `src/web/`：`shell.html`、`mole_boot.js` 原件
- `src/manifest/AndroidManifest.xml`：AXML 解码结果
- `docs/architecture.md`：启动时序、请求路由表、Socket 桥、三档降载机制
- `docs/decompile-report.md`：工具链、失真清单、未覆盖部分
- `docs/build.md`：从源码重建 APK 的步骤
- `docs/troubleshooting.md`：按 logcat 原文的症状对照表
- `tools/run_decompile.py`：可复现的反编译脚本

### Known issues

- `src/java/` 中局部变量的静态类型不可信（DAD 推断较弱），不能直接编译
- `resources.arsc` 未解析为明文，清单里保留 `@7F020000` 形式的原始资源 ID
- Ruffle 二进制未纳入仓库，需从官方 releases 自取
