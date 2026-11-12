# 1.2.0 — 正式版（Android 24 / HarmonyOS 7）

## 基线 → 产物

| 项 | 基线 | 1.2.0 |
| --- | --- | --- |
| Android | `1.1.9-beta`（versionCode 23，10,343,812 B） | `mole-1.2.0.apk`（versionCode 24，10,356,100 B） |
| HarmonyOS | `1.1.1`（versionCode 6，10-26 构建） | `mole-harmony-1.2.0-signed.hap`（versionCode 7，11,465,574 B） |

```
b776302bbc5ce46c71e773d4425edc2f2bee5fa99d0a13101571e59c57331714  mole-1.2.0.apk
c8b99da639c9f9598898ac2c1822127c7e89024c107d7ff0465442c61e113af5  mole-harmony-1.2.0-signed.hap
```

## Android 改了什么

**只有 `versionName`**：`1.1.9-beta` → `1.2.0`（`apktool.yml`）。
`assets/ruffle/` 三件套、`shell.html`、`mole_boot.js`、全部 smali 与 1.1.9-beta 逐字节相同。

本目录的 `shell.html` 与 `patches/1.1.9-beta/shell.html`、`src/web/shell.html` 三者 md5 均为
`89ec72195b6666d9da5e0a803487dc29`（194,969 B / 2226 行），存档在此仅为保持
「每版一份、可与相邻版直接 diff」的惯例。

## HarmonyOS 改了什么

只动 `rawfile/ruffle/` 与包版本，ArkTS 侧（`EntryAbility` / `LocalServer` / `NativeBridge`）一行未动。

- 引擎：`K7CA3GNA` / `JBAFOQXG` → `EFKRKUVC` / `I56A2W5M`（与 Android 同一套）；
- 壳层：153,067 B（1.1.1 分叉）→ 157,127 B，合入 1.1.9 的画质补丁：
  `BUDGET_MIN = 1210000` 地板、`DENSITY 1.7`、`MAXPIX 2200000`、`FLOOR 0.7`、
  DPR 记忆化、3 秒一行 `[MoleShell] 渲染实况`；
- `mole_boot.js` **未动**（仍是 10-21 的 10,697 B），所以 panic 侦测没进去。

MatePad 1280×800 / DPR 2：canvas `1242×724 → 1669×974`，物理放大 `2.06× → 1.53×`。

## HAP 重建方式（无 DevEco）

开发机的 DevEco Studio 与 `D:\DevEco Studio\sdk`（ets-loader 26.0.0.105）已删除，
`~/.hvigor` 只剩 pnpm 与项目依赖缓存 → **无法重编 ArkTS**。

以 10-26 的 `signing/entry-unsigned-111.hap` 为容器：

1. 替换 `resources/rawfile/ruffle/` 三件套 + 壳层，删掉两个旧 wasm；
2. `module.json` / `pack.info`：`versionCode 6 → 7`、`versionName 1.1.1 → 1.2.0`；
3. zip 按原条目顺序重写，全部 Stored；
4. `hap-sign-tool sign-app -mode localSign` 重签，`verify-app` → Verify success。

签名用的私钥来自 `openharmony/developtools_hapsigner` 的 `dist/OpenHarmony.p12`
（别名 `openharmony application release`），其公钥与 `signing/app-cert.pem` 一致，
CA / Root 与 `c1.pem` / `c2.pem` 指纹相同；profile 沿用 `mole-profile-111.p7b`。
安装身份与 1.1.0 / 1.1.1 保持一致。

`minAPIVersion` 与 `targetAPIVersion` 仍是 `50000012`（API 12）。抬到 6.0 / 7.0
必须重编 ArkTS，现阶段做不到，新系统上以兼容模式运行。

## 未动

画幅（960×560 + letterbox）、帧率 24、rAF 节流器、`quality low`、`PIXEL_BUDGETS`、
无损纹理回收、输入法配置、服务器地址、OmniPad 逻辑、鸿蒙独有的 `pendingAlign` 后台合成轴。

## 回归

`node tests/<name>_test.js`：text 24 / clock 34 / bg 54 / panic 34 = **146 项全过**。
`pad_test` 的 79/17 是 1.1.1-beta 改几何后的既有红，与 1.2.0 无关。

## 回滚

- Android：`adb install -r mole-1.1.9-beta.apk` 的同壳层版本，或按
  `patches/1.1.9-beta/` 重打；
- HarmonyOS：`hdc install mole-harmony-1.1.0.hap`（`signing/` 下留有已签包）。
