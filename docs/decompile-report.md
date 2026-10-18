# 反编译说明

记录这次把 APK 拆开、还原成可读源码的全过程，方便下次复现或换工具重做。

## 输入

```
C:\Users\Huawei\Downloads\base(4)\
├── AndroidManifest.xml   二进制 AXML
├── classes.dex           单 dex，无加固、无分包
├── resources.arsc
├── res/
├── assets/ruffle/        ruffle.js / mole_boot.js / shell.html / 两个 wasm.gz / 两份 Ruffle 许可证
└── META-INF/             v1 签名（ANDROIDD.RSA / .SF / MANIFEST.MF）
```

`classes.dex` **没有加固**（无 `libjiagu` / `libDexHelper` / `StubApp`），所以直接反编译即可，
不需要脱壳机或 Frida。这一点值得记下来：一旦后续版本上了加固，本流程会立刻失效。

## 工具链

| 用途 | 工具 | 版本 | 备注 |
| --- | --- | --- | --- |
| AXML 解码 | androguard | 4.1.4 | `AXMLPrinter` |
| dex → Java | androguard (DAD) | 4.1.4 | `AnalyzeDex` + `DecompilerDAD(d, dx)` |
| 运行环境 | CPython | 3.13.12 | venv 隔离，未污染系统环境 |

**为什么不用 jadx / apktool**：两者都依赖 JRE，而这台机器没有 Java，`winget` 拉 JRE 时
`InternetOpenUrl() failed 0x80072efd`，直连 GitHub 下载 releases 也被代理挡回 `CONNECT tunnel failed 502`。
PyPI 是通的，所以改走 androguard 路线。代价是输出质量不如 jadx —— 见下面的失真清单。

复现：`tools/run_decompile.py`，改顶部两个常量（`BASE` 输入目录、`OUT` 输出目录）后直接跑。

## 结果

- 解码清单 → `src/manifest/AndroidManifest.xml`
- 23 个类 → `src/java/com/taomee/mole/`
- 类清单 → `docs/classes_inventory.txt`
- 字符串/域名 → `docs/strings_urls.txt`

### 类结构

| 类 | 行数 | 职责 |
| --- | --- | --- |
| `MainActivity` | 1226 | 宿主、请求路由、资源注入、显存看护、降载状态机 |
| `SocketBridge` | 533 | 本地 WebSocket 服务 + RFC6455 帧处理 + TCP 中继 |
| `HttpCache` | 252 | 静态资源磁盘缓存（SHA-1 key、扩容 trim） |
| `CrashProbe` | 44 | `ApplicationExitInfo` 连续崩溃计数 |
| `MainActivity$JsBridge` | 74 | `@JavascriptInterface` 暴露面 |
| `MainActivity$1..$7` | 27–80 | 匿名内部类：GPU 看护、重载、降档、ChromeClient、WebViewClient、HUD |
| `SocketBridge$1..$3` | 29–44 | 接入线程、双向泵线程、DiscoveryListener 回调 |
| `HttpCache$1/$2` | — | trim 定时器、统计 |

## 失真清单（阅读时必须打折的地方）

DAD 的类型推断比 jadx 弱，以下几类地方是**反编译器的锅，不是代码的锅**：

1. **局部变量类型错乱**
   ```java
   String v0_1 = new String[] {"/system/fonts/..."};   // 应为 String[]
   android.webkit.WebView v5_24 = getConfiguration().smallestScreenWidthDp;  // 应为 int
   ```
   判断依据：看右值，`new T[]{}` 说明左值应为 `T[]`；`getInt()` / 返回 `int` 的方法同理。

2. **`try/catch` 被拆成 `try { try { try {`**
   原文是单个 `try` 的多层嵌套或 try-with-resources，DAD 会渲染成锯齿状嵌套，
   且 `catch` 的类型经常张冠李戴（`catch (String v2_3)`）。按语义还原即可。

3. **synthetic 访问器**
   所有 `access$NNN(Activity p0, …)` 都是 javac 为内部类生成的桥，原文不存在。
   数量与内部类访问的私有成员一一对应，可整段删除后用直接字段访问替换。

4. **`while` 循环体丢失条件**
   形如 `do { … } while(byte[] v5_2.length <= 0);` 是解析失败的产物，
   原文接近 `while (true) { byte[] h = readFully(in, 2); if (h == null) return; … }`。

5. **switch/数组初始化被写成赋值序列**
   ```java
   int v0_10 = new int[6];
   v0_10 = {1210000, 900000, …};   // 应为 int[] v0_10 = {…};
   ```

6. **`0` / `null` 混用**
   引用类型位置出现 `0` 是 `null`；`boolean` 位置的 `0/1` 是 `false/true`；
   比较 `if (v6_1 < null)` 实为 `if (x < 0)`。

结论：**字段名、常量值、调用顺序、路由判定条件都是可信的**（这些直接来自 dex 常量池和字节码），
局部变量的静态类型和语法细节不可信。写文档、理解逻辑够用；要重新编译必须人工过一遍。

## 没做/做不了的部分

- `resources.arsc` 未解析成明文（`@7F020000` 这类 ID 保留为原始值）。需要明文的话用 `aapt2 dump resources`，
  但需要 Android SDK build-tools。
- `META-INF` 的 v1 签名未验证，v2/v3 签名块（APK Signing Block）在拆包时已丢失，
  所以这份目录**不能直接重打包签名覆盖原包**，只能作为源码参考。
- Ruffle 的两个 `*.wasm.gz` 未反编译（Rust → wasm，反编译成本极高且无必要，直接用官方 release）。
