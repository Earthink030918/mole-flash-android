# 第三方组件

## Ruffle

- 项目：https://github.com/ruffle-rs/ruffle
- 用途：Flash (SWF) 运行时，以 WebAssembly 形式嵌入 WebView
- 许可：MIT OR Apache-2.0（双许可，任选其一遵循）
- 许可证原文：`third_party/ruffle/LICENSE_MIT`、`third_party/ruffle/LICENSE_APACHE`

随 APK 分发的 `ruffle.js` 与两个 `*.wasm.gz` 均为 Ruffle 官方构建产物，**未作修改**。
若需替换版本，从官方 releases 取同版本的三件套一起替换（见 `docs/build.md`）。

## 截图

`docs/screenshots/` 下的 5 张实机截图由项目作者在自用设备上截取，用于展示兼容层的运行效果。
截图中的游戏画面、"摩尔庄园"名称及相关美术资源版权归上海淘米网络所有，此处仅作说明性使用，
不构成对游戏内容的授权、分发或再许可。

## 未包含的第三方内容

游戏本体（`Client.swf`、地图/角色/道具等资源）版权归上海淘米网络所有，仅由客户端在运行时
从官方服务器按需加载，**不存储于本仓库，也不随 APK 分发**。

Android WebView、Gradle、AndroidX 等为各自权利人所有，按各自许可使用。
