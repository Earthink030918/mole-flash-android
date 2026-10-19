# Changelog

格式参照 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.1.0] - 2026-10-19

这一版把「点一下就消失」「进不去场景」「挂机闪退」「画面发虚」四类问题都追到了可复现的日志证据上，
修复全部落在 `src/web/shell.html`（APK 重打包，Java 层未改动 —— 见 `docs/decompile-report.md`）。

### Fixed

- **工具按钮 / 侧边菜单「点一下就消失」、银行小游戏「点了没反应」** —— 同一个根因，
  已用录像逐帧确认：手指在 ATM 上停留约 1 秒，Ruffle 自带的右键菜单
  （音量控制 / 打开存档管理器 / 关于 Ruffle / 隐藏此菜单）弹出来盖住画面，
  松手时它靠 `{once:true}` 的 `pointerup` 把自己收掉，同时 `stopPropagation`，
  于是 SWF 只收到 `mouseDown`、收不到 `mouseUp`，点击永远不成立。
  修复：`RufflePlayer.config.contextMenu = 'off'`，Ruffle 不再生成覆盖层，
  所有 pointer 事件原样交给 SWF。
- **进度条卡在 100% 进不去场景** —— 两处原因分别处理：
  1. 渲染后端能力：日志实证 `webgl` 与 `canvas` 都不支持离屏渲染，
     进场景必经的 `BitmapData.draw` 在影片剪辑构造期就抛
     `RustError("Render backend does not support BitmapData.draw")`，
     加载链直接断掉。因此默认后端固定为 `wgpu-webgl`（唯一支持离屏渲染的一档）。
  2. 套接字半包：`Error dispatching event "8755": Error #2030: End of file was encountered`
     —— 服务端一个逻辑包被 TCP 拆成两段，本地桥按 `read()` 各发一个 WebSocket 帧，
     SWF 读到半个包就抛 EOF。修复：在 `ruffle.js` 之前替换 `window.WebSocket`，
     对本地桥连接做 8ms **合帧**（把几乎同时到达的多个二进制帧合并成一次投递），
     实测连续进服 `#2030` 出现次数降为 0。
- **挂机闪退** —— 显存/系统内存长期累积耗尽（`mmap failed errno 12` → SIGTRAP 打死进程）。
  新增 `IdleGuard`：连续 5 分钟无触摸即把 rAF 节流到 12fps（只降帧、不降分辨率），
  触摸瞬间立即恢复；同时把渲染上限从 3.0 收到 2.5 倍，像素量减少约 30%。
- **画面发虚（分辨率过低）** —— 旧实现把 Java 注入的预算当绝对上限，
  960×560 算出来 DPR 只有 0.84~1.29，而这块屏真正需要 2.25×1.185 ≈ 2.67 倍。
  改为按 `raw × fit` 反推预算，且计算过程**不读** `offsetWidth` / `getBoundingClientRect`
  （Ruffle 的 wasm 会高频读 `devicePixelRatio`，每次读都强制同步重排，
  初始化阶段成百上千次重排叠起来就是「UI 初始化卡顿」）。

### Added

- 应用图标换成新图标（`res/mipmap-*` 五档全换），预览见 `docs/icons/app-icon-512.png`
- `StuckGuard`：钩住全部 `console` 方法捕获卡死签名，满 10 秒无进展就锁定后端并重载一次；
  带 90 秒 / 3 次限频，并只允许在**启动后 4 分钟内**生效 ——
  避免游戏内偶发 `#2030` 把正在玩的玩家踢下线。
- 分辨率、长任务、后备缓冲变化的取证日志（`[MoleShell]` 前缀），便于后续回归对比。

### Changed

- 默认渲染后端改为 `wgpu-webgl`。此前一版曾因「挂机显存恒定」把 `webgl` 定为默认，
  后来发现那个结论是假象：`webgl` 根本进不了场景，一直停在选服界面，所以没有纹理累积。
- 弱 GPU（Adreno 606–620 / Mali-G5x）不再靠砍分辨率保命，改为只压低超采样上限（1.6 倍），
  清晰度仍按 1:1 给足。

### 已知问题

- 进入服务器阶段 `#2030` 已大幅减少（合帧后实测为 0），但它源于服务端拆包 + 本地桥逐帧转发，
  仍属概率事件；若复现，`StuckGuard` 会在 10 秒后自动重载重试，**重载后会回到「开始」页**，
  需要再点一次「开始」。
- 步步高 S6（骁龙 730 / Adreno 618）无实机，只按 GPU 型号做了防御性降档（上限压到 1.6 倍），未验证。
- 餐厅「雇人」按钮未能单独复现到现场；它与上述菜单问题同属 pointer 事件被覆盖层截走，
  已随 `contextMenu: 'off'` 一并处理，但缺一次针对性回归。
- 需要键盘辅助的小游戏仍不支持。

## [1.0.0] - 2026-10-18

首个可安装的 Release。源码与文档在 0.1.0 已公开，本次补上分发包。

### Added

- GitHub Release [`v1.0.0`](https://github.com/Earthink030918/mole-flash-android/releases/tag/v1.0.0)，附件：
  - `mole-flash-android-1.0.0.apk` —— 10,134,939 字节，`com.taomee.mole` 1.0（versionCode 1），
    minSdk 21 / targetSdk 35，APK Signature Scheme v1 + v2 自签名（`CN=Mole Shell, O=Mole, C=CN`）
  - `SHA256SUMS.txt`
- README 增加「下载」小节与校验方法

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
