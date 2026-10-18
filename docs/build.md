# 构建

## 前提

- JDK 17+（编译 `targetSdk 35` 建议 21）
- Android SDK Platform 35 + Build-Tools 35
- Ruffle 二进制：`ruffle.js`、`ruffle_web_bg.*.wasm.gz`、`ruffle_web-wasm_mvp_bg.*.wasm.gz`

## 1. 补 Ruffle 二进制

仓库里没有（各 ~5 MB，且属第三方构建产物）。从 [ruffle-rs/ruffle releases](https://github.com/ruffle-rs/ruffle/releases)
下载 `ruffle-nightly-*-web-selfhosted.zip`，解压后放进：

```
app/src/main/assets/ruffle/
├── ruffle.js
├── mole_boot.js                              ← 用本仓库 src/web/mole_boot.js
├── shell.html                                ← 用本仓库 src/web/shell.html
├── ruffle_web_bg.<HASH>.wasm.gz
├── ruffle_web-wasm_mvp_bg.<HASH>.wasm.gz
├── LICENSE_APACHE
└── LICENSE_MIT
```

> 两个 wasm 的文件名里带 hash，**必须与 `ruffle.js` 内部引用一致**，否则 `wasmResponse()` 会 404、
> 页面停在 `Ruffle 加载失败`。换版本时三个文件一起换。

## 2. 清理反编译代码

`src/java` 不能直接 `javac`。按 [`decompile-report.md`](decompile-report.md) 的失真清单处理，最低限度要做：

1. 删掉所有 `access$NNN` 合成方法，把调用点改回直接字段/方法访问。
2. 修局部变量类型（`String x = new String[]{…}` → `String[] x = {…}`）。
3. 把 `0` 在引用位置改成 `null`，`boolean` 位置的 `0/1` 改成 `false/true`。
4. 补回 `final`、`@Override`、泛型（`LinkedHashSet<String>`、`HashMap<String,String>`）。
5. `MainActivity$6.shouldInterceptRequest` 里那段嵌套 if —— 原文是 `if/else if` 链，按路由表重排。

内部类建议直接提成命名类（`GpuWatchRunnable`、`ShellWebViewClient`、`ShellChromeClient`、`MoleJsBridge`），
比保留 `MainActivity$1..$7` 好维护得多。

## 3. 工程骨架

`app/build.gradle.kts`：

```kotlin
android {
    namespace = "com.taomee.mole"
    compileSdk = 35
    defaultConfig {
        applicationId = "com.taomee.mole"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
    // 不能开 minify：JS 桥靠方法名反射调用，混淆后 MoleBridge.xxx 全失效
}
```

清单直接抄 `src/manifest/AndroidManifest.xml`，但要把 `@7F020000` 这类资源 ID 换回
`@string/app_name` / `@mipmap/ic_launcher` / `@xml/network_security_config`。

### network_security_config

清单里 `usesCleartextTraffic="true"` 且引用了 `@xml/network_security_config`，两个都要留：

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

## 4. 编译与安装

```bash
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

签名：调试包用 `~/.android/debug.keystore` 即可；要覆盖安装旧版本，签名必须一致，
否则先 `adb uninstall com.taomee.mole`（会清掉 `SharedPreferences` 里的学习到的服务器列表）。

## 5. 打包前的自检

- [ ] `assets/ruffle/` 下 7 个文件齐全，wasm 文件名与 `ruffle.js` 引用一致
- [ ] `mole_boot.js` 里 `SWF = '/Client.swf'` 与上游实际路径一致
- [ ] `AndroidManifest.xml` 的 `networkSecurityConfig` 指向真实存在的 xml
- [ ] `minSdk 21` 下 `ApplicationExitInfo` 走 `SDK_INT < 30` 分支（已用 `-1` 兜底）
- [ ] `setTextZoom`、`setAllowUniversalAccessFromFileURLs` 都包在 try 里（部分 ROM 抛异常）

## 6. 抓日志

```bash
adb logcat -s MoleShell:V MoleSocketBridge:V
```

页面侧 console 已被 `shell.html` 接管并转发成 `MoleShell` 的 `[js]` 行，不用再开 Chrome inspect。
需要 WebView 远程调试时 `chrome://inspect` 可直接连（`setWebContentsDebuggingEnabled(true)` 已开）。
