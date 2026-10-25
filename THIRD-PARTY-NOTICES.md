# 第三方组件

## Ruffle

- 项目：https://github.com/ruffle-rs/ruffle
- 用途：Flash (SWF) 运行时，以 WebAssembly 形式嵌入 WebView
- 版本：`0.8.0-nightly.2026.10.16`（commit `ff5321cd`）
- 许可：MIT OR Apache-2.0（双许可，任选其一遵循）
- 许可证原文：`third_party/ruffle/LICENSE_MIT`、`third_party/ruffle/LICENSE_APACHE`

随 APK 分发的 `ruffle.js` 与两个 `*.wasm.gz` 均为 Ruffle 官方构建产物，**未作修改**。
若需替换版本，从官方 releases 取同版本的三件套一起替换（见 `docs/build.md`）。

## OmniPad

- 项目：https://github.com/omnipad-js/omnipad
- 包：`@omnipad/vanilla@0.7.3`（commit `c91b3828`，2026-09-05）
- 用途：虚拟触控板与靶区（`VirtualTrackpad` / `TargetZone`），把触摸翻译成带悬停语义的鼠标事件
- 许可：MIT
- 许可证原文：`patches/1.0.5/vendor/LICENSE-omnipad.txt`
- 归档文件：`patches/1.0.5/vendor/omnipad-0.7.3.global.js`（69,902 B）、`omnipad-0.7.3.css`（9,937 B）

按该项目 README 的 UMD 引入方式接入，仅把 unpkg CDN 的 JS / CSS 改为**本地内联**
（应用内无外网 CDN，且需离线可用），**未修改任何逻辑**。
分发时保留了原始版权声明与许可证文本。

上游改动记录：

| 修改 | 说明 |
| --- | --- |
| CDN → 内联 | `<script src="https://unpkg.com/...">` 改为把 UMD 文本内联进 `shell.html`，等价于同一份代码 |
| 挂载位置 | 由页面默认位置改为挂进 `#pad` 容器，并按黑边几何动态定位（见 `shell.html` 第 5 段） |
| 可见性 | 增加 `#pad.pad-invisible .omnipad-trackpad { opacity: 0 }` 一条 CSS，只影响外观不影响命中测试 |

## 截图

`docs/screenshots/` 下的 5 张实机截图由项目作者在自用设备上截取，用于展示兼容层的运行效果。
截图中的游戏画面、"摩尔庄园"名称及相关美术资源版权归上海淘米网络所有，此处仅作说明性使用，
不构成对游戏内容的授权、分发或再许可。

应用图标由群友授权提供，非官方美术资源。

## 未包含的第三方内容

游戏本体（`Client.swf`、地图/角色/道具等资源）版权归上海淘米网络所有，仅由客户端在运行时
从官方服务器按需加载，**不存储于本仓库，也不随 APK / HAP 分发**。

Android WebView、AndroidX、OpenHarmony SDK 等为各自权利人所有，按各自许可使用。
