# 1.0.2 修复补丁（安卓端）

基线：`mole-flash-android-1.0.1.apk`（smali 反编译后打补丁，未改动任何游戏资源、画质参数、帧率节流器、画幅算法、服务器地址）。

版本：`versionCode 3` / `versionName 1.0.2`（同 `mole-release.keystore` 签名，可覆盖升级 1.0.1）。

---

## 群友反馈 → 触发点 → 修法

### 1. 隔一段时间整个 APP 自动重启

有**三条**独立来源，全部修掉：

| # | 触发点 | 根因 | 修法 |
|---|---|---|---|
| G1 | `MainActivity$1`（GPU 看护线程） | 显存 ≥410MB 时调 `releaseTextures(false)` → 主线程 `loadUrl("about:blank")`，2 秒后回壳页。整个 SWF 从头加载，**体感就是 APP 自己重启**；重载后纹理重新堆积，很快再次越闸，形成「越闸→重载→再堆积」死循环 | 改为 `raiseLoadLevel(loadLevel+1)`：只把渲染预算降一档（`__moleSetBudget` 就地生效），不重载页面。真正异常（页面 panic / GPU 上下文丢失）仍走 `releaseTextures` 强制重载，不受影响 |
| G2 | `MainActivity$7`（补录端口后的 Runnable） | 每发现一个「缺失代理」端口就 `web.reload()`，上限 8 次。而 `onMissingProxy` 在换场景、进商城、开小游戏时都会触发 → 用户正玩着被静默重启 | 不再 reload，只落盘 + 留在内存 `targets`，下次正常启动生效。SEED 端口池已覆盖 1860-1880 / 3195-3215 / 6650-6700 及常用端口，补录属极少数兜底 |
| S1/S2 | `SocketBridge.handle()` | `pumpClientToTcp` 发完 close 帧后只 `return`，**不关闭任何 socket**；随后 `handle` 无条件 `join()` 另一方向线程，对端不出数据时 `read()` 永久阻塞 → handle 线程 + `mole-ws-down` 线程双双挂死，两个 socket 也不释放。`pool` 又是 `newCachedThreadPool`（无上限），每次泄漏 2 线程 + 2 fd，累积后进程崩溃/被杀 | 上行结束即 `closeQuietly` 关闭 TCP 与 WS 两侧（S1）；下行 `read<=0` 时对称关闭 WS 侧（S2）；线程池改为 `newFixedThreadPool(24)` 兜底（S3） |

**真机验证（vivo V2338A / Android 16）**：
```
已接入 -> 123.***.***.***:1863
下行结束：Socket closed          ← 同一毫秒
断开 123.206.131.236:1863        ← join 立即返回
```
修复前这条「断开」永远打不出来（join 已挂死）。进程线程数 92 → 89 稳定，无增长。

### 2. 进入金豆商城页面卡死

截图特征：商城框架、左侧角色、金豆/积分数字、底部分页 1~10 全部正常，**唯独商品列表整片空白** —— 典型的「接口数据被错误缓存」。

触发点：`HttpCache.<clinit>` 的 `STATIC_EXT` 白名单把 `ini / xml / js / css / txt / json / cfg` 也算作可缓存静态资源。`upstream()` 命中缓存后以 `Cache-Control: public, max-age=604800`（**7 天**）返回。而商城商品列表这类动态数据恰好用 xml/ini 下发，于是：

- 只要某一次进商城时后端返回空列表（角色数据未就绪 / 登录态刚建立 / 服务端瞬时限流），**空响应就被钉在磁盘上 7 天**，之后重进多少次都是空白；
- 商城数据永不刷新（买完数量不变、活动还显示上一期）。

修法（C1）：白名单只保留「大且内容不变」的二进制资源 —— `swf / png / jpg / jpeg / gif / webp / bmp / mp3 / wav / ogg / dat / bin`；文本类一律不进磁盘缓存，由 WebView 自身的 HTTP 缓存（服务端有 ETag/Last-Modified）兜底。这些文件体积小，直连开销可忽略。

叠加 S1/S2：商城这种「一次性开大量连接又大量断开」的页面最先把线程泄漏放大成卡死，同一条修复也覆盖它。

已核实新 dex 里 `xml` / `ini` 等字符串**已从常量池消失**，不可能再命中。

### 3. 部分触控逻辑和鼠标逻辑完全混乱

两个独立原因：

- **T1｜WebView 捏合缩放**（`MainActivity.configure()`）
  页面 viewport 里写了 `user-scalable=no`，但自 Chrome 32 起该声明对**捏合缩放**不再强制生效，Android WebView 仍会做 visual viewport zoom。一旦被缩放，`getBoundingClientRect()` 返回布局坐标、触点却落在被放大的视觉层上 → Ruffle 换算出的舞台坐标整体错位 → 「点哪儿都不对」，且**不会自己恢复**。
  修法：`setSupportZoom(false)` + `setBuiltInZoomControls(false)` + `setDisplayZoomControls(false)`。这是唯一能真正禁掉捏合缩放的地方。
- **A1｜系统手势区拦截**（`MainActivity$6.onPageFinished`）
  Android 10 起手势导航会优先拦截屏幕左右约 20dp 的边缘，用于「返回」。这部分事件根本到不了 WebView → 贴边按钮（背包、地图、商城侧栏、贴边 NPC）点不动。
  修法：API 29+ 调 `setSystemGestureExclusionRects`，把左右各 3% 宽度报为手势排除区（远低于系统每边 200dp 上限，不影响滑动返回）。
- **壳层兜底**（`src/web/shell.html` 第 4 段）
  多指一旦出现即锁死（游戏是单指操作，多指唯一作用是触发捏合）；屏蔽 `contextmenu / selectstart / dragstart / gesturestart`（长按气泡会吞掉一次点击）；`overscroll-behavior:none` 阻断下拉刷新与边缘回弹抢 `touchmove`；`visualViewport` 被意外缩放时复位到 1:1；视口变化后重做 `__moleFit`，避免 scale 停在旧值造成命中偏差。
  **没有做「双击 300ms 去抖」** —— 那会丢快速连点，只把缩放关掉即可。

### 4 & 5. 一加全系平板 / ColorOS 17 / 红米 K90 适配

- A1 手势排除对三者同时生效（一加 OxygenOS、ColorOS 17、HyperOS 的手势导航都是同一套 EdgeBackGesture 机制）。
- K90 额外收益：`graphicsMb()` 在部分天玑机型上取不到 `summary.graphics` 会返回 -1（不误杀）；但若返回异常大值，原逻辑会直接整页重载 → 现在只降一档，**即使误判也不会重启**。
- 平板的 `smallestScreenWidthDp>=600` 走 `orientation=10`（fullSensor）保持原样，未改动方向策略。

---

## 未改动的部分（按要求）

- 画质：`quality:'low'`、`preferredRenderer:'wgpu-webgl'`、`PIXEL_BUDGETS` 数值与分档逻辑
- 画幅：`960x560` 容器 + `contain` 等比缩放算法、`scale:'showAll'`、`letterbox:'on'`
- 帧率：shell.html 第 0 段的 rAF 累积时间节流器（24fps）完全未动
- 服务器：`SEED_HOSTS_ENC` / `SEED_PORTS` / `SocketBridge` 默认 host:port 一字未改
- 游戏本体：未改任何 swf / 资源 / 服务端协议

## 复现构建

```bash
apktool d mole-flash-android-1.0.1.apk -o dec
# 用本目录 smali/*.smali 覆盖 dec/smali/com/taomee/mole/ 下同名文件
cp ../../src/web/shell.html dec/assets/ruffle/shell.html
apktool b dec -o unsigned.apk
zipalign -p -f 4 unsigned.apk aligned.apk
apksigner sign --ks mole-release.keystore --ks-key-alias mole --out mole-1.0.2.apk aligned.apk
```
