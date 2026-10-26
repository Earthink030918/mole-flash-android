# 1.1.4 — 前台服务没真正成为前台服务

## 现象

切到后台后 App 依然被系统回收；回前台从头上启动。系统设置 → 权限里
「允许通知」是**关闭**状态，挂机时看不到任何「运行中」通知。

## 根因（两处，同一个后果）

### ① `startService()` 拉起的只是「普通后台服务」

`MainActivity.onPause()` 里用的是：

```java
startService(new Intent(this, MoleKeepAlive.class));
```

`startService()` 得到的服务**不是前台服务**，只是普通后台服务：

1. 应用一旦不可见，系统只给约 1 分钟宽限，随后
   `ActivityManager: Stopping service due to app idle` 直接把服务收掉；
2. 没有「5 秒内必须 startForeground」的豁免窗口。服务里那句
   `startForeground()` 在 Android 12+ 会抛
   `ForegroundServiceStartNotAllowedException`（`mAllowStartForeground=false`），
   而 1.1.2 的实现是：

   ```java
   try {
       ensureChannel();
       buildNotification();
       startForeground(NOTIF_ID, n);
   } catch (Throwable t) {
       // 静默吞掉
   }
   ```

   异常被吞，`startForeground` 等于没执行，服务始终是普通后台服务，
   进程 `oom_adj` 停在 cached 档，切后台就被 LMK 回收。

**这就是「切后台以后软件自动死了 / 切回来自动重启」的真正根因。**
1.1.3 的 `setRendererPriorityPolicy` + `onRenderProcessGone` 只是让
「渲染进程被回收」不再直接 `killProcess`，没有解决「进程本身是 cached
优先级」这件事。

### ② `POST_NOTIFICATIONS` 从未申请

`targetSdk = 35`。Android 13 起通知是**运行时权限**，清单里写了
`<uses-permission>` 只是「允许申请」，不主动 `requestPermissions()` 就
永远是「已关闭」。所以用户看到的那条「允许通知」一直是关的，前台服务
即使起来了也不会有可见通知。

## 改动

| 位置 | 改动 |
| --- | --- |
| `MainActivity.onPause` | `startService` → `startForegroundService`（API 26+），< 26 保留 `startService` |
| `MainActivity.onCreate` | 末尾新增 `requestNotifyPermission()` 调用 |
| `MainActivity`（新方法） | `requestNotifyPermission()`：API 33+ 用 `checkSelfPermission` 判断后 `requestPermissions(POST_NOTIFICATIONS, 0x4d50)` |
| `MoleKeepAlive.onStartCommand` | `ensureChannel` / `buildNotification` / `startForeground` 三步各自兜底，**保证 `startForeground` 一定执行**；失败时 `Log.e(tag, msg, throwable)` 打全堆栈 |
| `MoleKeepAlive.ensureChannel` | 方法内部自吞异常，不让渠道异常连累 `startForeground` |
| `MoleKeepAlive.buildNotification` | 小图标 `@mipmap/ic_launcher` → `android.R.drawable.stat_notify_sync`（单色、无资源解析风险） |

## 没动的东西

- `shell.html` 一行未改
- 画幅 / 画质预算 / 帧率 / 节流器 / 服务器地址：全部未动
- `MoleKeepAlive` 的 `START_NOT_STICKY` 保活策略：未动
- GPU 看门狗、`OmniPad` 触控层：未动

## 验证要点（真机）

1. 首次启动应弹出通知权限框 → 允许 → 系统设置里「允许通知」变为开。
2. 切后台，通知栏应出现「摩尔庄园 · 挂机运行中 · 点击回到游戏」。
3. `adb shell dumpsys activity services com.taomee.mole` 应看到
   `isForeground=true`。
4. logcat 搜 `MoleShell`：
   - 出现 `前台服务已启动，挂机通知已挂出` = `startForeground` 成功；
   - 出现 `前台服务启动失败` + 堆栈 = 仍在失败，堆栈直接指出原因。

## 产物

`bugfix/mole-1.1.4.apk` · versionCode 13 · 10,315,140 B
SHA-256 `3a623bea176da852c4baf246cce1c038d4d2a725fe4b34a7a3bc7262aec422cf`
签名同源 `974EA1B9…`，可直接覆盖 1.1.2 / 1.1.3。
