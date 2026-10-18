# Changelog

格式参照 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

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
