# 1.1.5 — 1.1.4 的服务类根本加载不起来

## 现象

1.1.4 装上去，手动在系统设置里把「允许通知」打开，切后台**仍然没有任何通知**，
App 照样被回收。

## 根因：catch handler 不是以 `move-exception` 开头

1.1.4 的 `MoleKeepAlive.onStartCommand` 长这样：

```smali
:try_start_ch
invoke-direct {p0}, Lcom/taomee/mole/MoleKeepAlive;->ensureChannel()V
:try_end_ch
.catch Ljava/lang/Throwable; {:try_start_ch .. :try_end_ch} :catch_ch

:catch_ch                       ← handler 入口，下一条直接是下一段代码
:try_start_bn
...
```

handler 里不需要异常对象，我就没写 `move-exception`。**dex 格式明确规定
catch handler 的入口必须是 `move-exception` 指令**，ART 的类验证会因此拒绝
整个 `MoleKeepAlive` 类：

- `Class.forName` / 服务实例化失败
- Activity 侧 `startForegroundService()` 抛出的异常又被 `catch (Throwable) {}`
  吞掉
- 外部表现：**通知永远不出现，进程却依然是 cached，切后台照杀**

也就是说，1.1.4 修的方向是对的，但被这个字节码形式错误整个废掉了 ——
服务压根没被创建过，`startForeground` 一次也没执行。

## 改动

| 位置 | 改动 |
| --- | --- |
| `MoleKeepAlive.onStartCommand` | 删掉多余的**外层** `try/catch`（`ensureChannel` 内部已自行兜底），只保留 `startForeground` 这一段，handler 以 `move-exception` 开头 |
| `MoleKeepAlive.onStartCommand` | `startForeground` 在 API 29+ 改用三参版本，显式传 `FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK(2)`；两参版本依赖清单声明，个别 ROM 会抛 `MissingForegroundServiceTypeException` |
| `MoleKeepAlive.ensureChannel` | 渠道 ID `mole_bg` → **`mole_bg_v2`**，重要性 `IMPORTANCE_LOW(2)` → `IMPORTANCE_DEFAULT(3)` |
| `MoleKeepAlive.onCreate` | 新增日志「保活服务已创建」 |
| `MainActivity` | 服务启动抽成 `startKeepAlive()`；新增 `onUserLeaveHint()`，与 `onPause()` 各调一次 |
| `MainActivity.startKeepAlive` | 失败时 `Log.e(tag, msg, throwable)` 打全堆栈 |

### 为什么换渠道 ID

Android 的渠道创建后，**代码再改 `importance` 不生效**，只有用户能改。
1.1.2 建的是 `mole_bg` + `IMPORTANCE_LOW`，部分 ROM 会把 LOW 渠道折叠进
「静默通知 / 其他通知」，用户即使开了总开关也看不见。用新 ID 建新渠道，
才能确保 `IMPORTANCE_DEFAULT` 生效。

### 为什么加 `onUserLeaveHint`

Android 12+ 规定 `startForegroundService()` 必须在应用处于前台时调用。
`onPause` 的时机已经贴着这条边界；`onUserLeaveHint()` 严格早于 `onPause`
（用户按 Home / 切到别的 App 时触发），在那里再调一次做双保险。重复调用
只会再走一遍 `onStartCommand`，幂等。

## 静态校验

用脚本按方法粒度扫了反编译后的成品：

- `MoleKeepAlive.smali`：3 个 catch handler，**全部以 `move-exception` 开头**
- `MainActivity.smali`：9 个 catch handler，**全部以 `move-exception` 开头**

## 没动的东西

`shell.html`、画幅 / 画质预算 / 帧率 / 节流器 / 服务器地址、`START_NOT_STICKY`
保活策略、GPU 看门狗、OmniPad 触控层 —— 全部未动。

## 验证要点

1. 覆盖安装 1.1.5（versionCode 14）。
2. 切后台，通知栏出现「摩尔庄园 · 挂机运行中 · 点击回到游戏」。
3. `adb shell dumpsys activity services com.taomee.mole` → `isForeground=true`。
4. logcat 搜 `MoleShell`，正常应依次出现：

   ```
   保活服务已创建
   前台服务已启动，挂机通知已挂出
   ```

   若只有「保活服务启动失败」，后面会跟完整堆栈，直接指向原因。

## 产物

`bugfix/mole-1.1.5.apk` · versionCode 14 · 10,315,140 B
SHA-256 `6fbffd42abbec15e60f97bcedf56fd06183aaab3cd271264bdf1eedec9e651db`
签名同源 `974EA1B9…`，可直接覆盖安装。
