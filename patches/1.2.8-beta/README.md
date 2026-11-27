# 1.2.8-beta —— 荣耀 V30 Pro 进不去服务器

> 群友反馈原话：**「荣耀 V30 Pro 系列手机无法进入服务器」**。
> 同版本在别的机器上正常，所以先假设是机型相关，从链路最外层往下查。

---

## 一、这条链路长什么样

```
MainActivity.loadUrl("http://mole.61.com/__mole_shell__")
        │
        │  shouldInterceptRequest 命中，返回 assets/ruffle/shell.html
        ▼
   壳页（origin = http://mole.61.com，公网源）
        │  Ruffle 起 SWF，SWF 里的 XMLSocket 要连 123.206.131.236:1863
        ▼
   socketProxy:  ws://127.0.0.1:<随机端口>/?host=...&port=1863   （本地回环）
        │
        ▼
   SocketBridge（ServerSocket(0, 24, 127.0.0.1)）
        │  读 HTTP 头 → 回 101 → connect 真实服务器 → 双向泵
        ▼
   游戏服
```

关键点：**壳页必须是 `mole.61.com` 这个公网源**（SWF 认域名），
而桥只能监听在 loopback。于是每一帧 WebSocket 都是「公网源 → 本地回环」。

## 二、根因

Chromium 从 94 起对「公网源访问私有/本地网络」引入 **PNA（Private Network Access）**：
先发一个 `OPTIONS` 预检，只有响应带 `Access-Control-Allow-Private-Network: true` 才放行。
Chrome 138 起升级成 **LNA（Local Network Access）**，头名变成 `-Allow-Local-Network`，
而且**默认拦截**，`Access-Control-Allow-Origin` 也不再接受 `*`。

旧 `SocketBridge.handle()` 的判定只有一条：

```
sec-websocket-key 为空 → 400 Bad Request
```

预检请求里当然没有这个头，于是：

```
OPTIONS /?host=...&port=1863 HTTP/1.1     ← 内核的预检
HTTP/1.1 400 Bad Request                   ← 桥的回答
→ net::ERR_FAILED，WebSocket 根本没建立
→ Ruffle 上层只看到「连不上服务器」
```

为什么只有荣耀 / 华为先炸：这几家的 WebView（尤其跟着 HarmonyOS 走的版本）
对上游 Chromium 的跟进最快。同一个版本号，别的机型内核还停在 PNA 未强制的阶段。

## 三、改了哪三处

### 3.1 预检：回 204 + CORS + PNA/LNA 头

`SocketBridge.handle()` 在取不到 `sec-websocket-key` 时，先看首行是不是 `OPTIONS`：

```
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: <回显请求的 Origin，缺失时 *>
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: *
Access-Control-Allow-Private-Network: true
Access-Control-Allow-Local-Network: true
Access-Control-Max-Age: 600
Connection: close
Content-Length: 0
```

- **两个头都发**：老内核读 `Private`，新内核读 `Local`，一次覆盖。
- **Origin 回显**：LNA 不接受 `*`，所以从请求头里取 `origin` 原样回；取不到才用 `*`。
- **非 OPTIONS 的无 key 请求仍回 400**：垃圾连接不能被放行成 204。
- 命中时 logcat 有一行 `bridge: CORS preflight allowed (PNA)`，方便确认修复是否起作用。

### 3.2 accept 循环不再「一异常就死」

旧代码：

```java
while (!srv.isClosed()) {
    try { ex.execute(new Handler(srv.accept())); }
    catch (IOException e) { log(e); break; }   // ← 一次异常，桥判死刑
}
```

accept 线程一退出，之后**所有** WebSocket 连接都没人接收，症状和预检被拒一模一样。
现在：`ServerSocket` 没关就退避 300ms 继续收（`SystemClock.sleep`，不额外抛受检异常）。

### 3.3 主文档路由放宽

`MainActivity$6.shouldInterceptRequest` 原来是：

```java
if (url.endsWith("/__mole_shell__")) return shellResponse();
```

华为 / 荣耀的定制内核可能给导航 URL 补尾斜杠或带 query，`endsWith` 一漏，
主文档就真的去请求 `mole.61.com` —— 白屏或进不去。改用 `contains("/__mole_shell__")`。
排障手册里本来就写着「带 query 就会漏」，这次一起补上。

### 3.4 附带：日志页多一行桥状态

日志页正文第一行固定为：

```
[桥] 127.0.0.1:45123 · 目标 228 条 · wgpu-webgl（档 0）
```

- `127.0.0.1:0` → 桥没起来（绑定失败）
- `目标 0 条` → socketProxy 没注入
- 两个都正常却仍连不上 → 内核层拦截（就是本轮修的东西）

这一行同时写进分享报告（`extra['桥']`），群友截图/发 txt 都能带上。

## 四、为什么没把壳页搬到 127.0.0.1

那样 origin 变成 loopback，PNA 完全不触发，看似最干净。但：

- `root.loaderInfo.url` 会变成 `http://127.0.0.1:PORT/...`，SWF 里对官方域名的判断
  可能直接拒绝加载；
- `upstream()` 里给资源带 `Referer` 的逻辑也要跟着改；
- 影响面从「补一条响应」扩大到「换加载方式」，与「不碰游戏本体」的要求冲突。

所以选择在协议层把预检答对，而不是换房子。

## 五、验收

| 项 | 结果 |
| --- | --- |
| `aapt2 dump badging` | `versionCode 29` / `versionName 1.2.8-beta` |
| 签名 | v1 + v2 + v3 全 `true`，证书 `B9197126…AE845BEE`（与 1.2.4 起同一把） |
| `zipalign -c 4` | 通过 |
| 包内 `assets/ruffle/shell.html` | md5 与源文件一致（`fda47c11…`） |
| dex 关键常量 | `Access-Control-Allow-Private-Network` / `-Local-Network` / `HTTP/1.1 204` / `bridge: CORS preflight allowed (PNA)` 均在 |
| `class_defs_size` | **28**（没有新增类） |
| 单测 | `logpage_test` 59 → **62**；text 24 / clock 34 / bg 54 / crashui 51 / dpad 22 / panic 50 全绿；`pad_test` 79/17 为 1.1.x 既有基线 |

| 产物 | 值 |
| --- | --- |
| 文件名 | `mole-flash-1.2.8-beta.apk` |
| 大小 | 10,388,868 B（9.91 MiB） |
| SHA-256 | `edb390bcff3f558bd9e8bc8e07537fe1ec394fab959a545090aa4e84942527bc` |

**没有动的**：帧率 24、画幅与 `quality:'low'`、节流器、`DENSITY` / `MAXPIX` / `FLOOR`、
`budgetNow()`、五层输入法守卫、纹理回收、OmniPad 本体、服务器地址与端口表、
`AndroidManifest.xml`、`mole_boot.js`。

## 六、如果还有人进不去

让他打开游戏内「日志」浮钮，把**第一行**和后面 20 行一起发过来：

- `[桥] 127.0.0.1:0` → 桥没监听，看 logcat 的 `桥启动失败`
- `目标 0 条` → 种子解码或端口表为空
- 桥正常、仍连不上 → 把 `adb logcat -s MoleSocketBridge:V` 拿来，
  看有没有 `CORS preflight allowed`；没有就是内核压根没发预检（LNA 无提示硬拦），
  那要换方案（壳页 origin 迁移），不在本版范围。
