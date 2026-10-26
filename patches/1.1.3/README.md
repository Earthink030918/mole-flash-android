# 1.1.3 补丁：修「切后台后 App 静默死亡、回前台自动重启」

> 基线：**v1.1.2 的 smali**（`dec-105` 工程）。
> **本版不碰 `shell.html`、不碰 Ruffle、不碰画幅/画质/帧率/节流器/服务器地址。**
> 改动全部在 Android 壳层（两处 `smali`），只影响「进程与渲染进程的存活」。

## 症状

1. 切到后台，过一会儿再切回来 —— 应用是从头启动的（登录/加载画面重走一遍）。
2. 更早的版本也有，但表现为「挂机时间长了直接崩」；1.1.2 之后变成「切后台没多久就没了」。

## 根因

### 一、渲染进程的优先级默认是「不可见就别管了」

`WebView` 有一个进程级策略 `setRendererPriorityPolicy(priority, waivedWhenNotVisible)`。
默认值是 `RENDERER_PRIORITY_WAIVED` + `waivedWhenNotVisible = true`，意思是：
**WebView 一不可见，渲染进程就退回普通后台进程的优先级**，成为内存回收的首选目标。

1.1.2 把后台做成了「逻辑 + 音频原子冻结」：不出帧、不出声、没有定时器工作。
在系统眼里，这就是一个**占着上百 MB（wasm 堆 + 画布）却什么都不干**的进程。
1.1.0 / 1.1.1 之所以是「挂久了才崩」，是因为那时候后台还在出声出帧，渲染进程
在 Chromium 眼里还算活跃，能多扛一阵。

### 二、渲染进程一死，整个 App 被按默认策略杀掉

`MainActivity$6`（`WebViewClient`）**没有实现 `onRenderProcessGone`**。
这种情况下 WebView 的默认行为是：

```java
// AwContents 内部
if (!client.onRenderProcessGone(this, detail)) {
    Process.killProcess(Process.myPid());   // 整个 App 无声消失，没有崩溃弹窗
}
```

所以现象不是「闪退弹窗」，而是「软件自己没了」；任务残留在最近任务里，
再点回来时系统重建 Activity —— 看起来就是「自动重启」。

一句话：**1.1.2 让渲染进程变得可回收，而壳层没接管渲染进程死亡的善后，
于是后台一回收就整包陪葬。**

## 修复（两处，都在壳层）

### 1. `MainActivity.onCreate()`：锁住渲染进程优先级

在 `new WebView()` **之前**（`WebViewChromium` 只在实例初始化时读一次这个静态策略）：

```smali
invoke-static {v0, v1}, Landroid/webkit/WebView;->setRendererPriorityPolicy(IZ)V
# v0 = 0x1  RENDERER_PRIORITY_IMPORTANT
# v1 = 0x0  waivedWhenNotVisible = false  ← 不可见时也不作废
```

API 26 以下没有这个方法，用 `SDK_INT >= 26` 兜住。

### 2. `MainActivity$6`：实现 `onRenderProcessGone`，不再让 WebView 杀进程

```smali
.method public onRenderProcessGone(Landroid/webkit/WebView;Landroid/webkit/RenderProcessGoneDetail;)Z
    # 记 didCrash / rendererPriorityAtExit 到 logcat（MoleShell）
    # 交给 MainActivity.onRendererGone()
    return 0x1        # 接管，别杀进程
```

`MainActivity.onRendererGone()` 只做两件事：

- 置 `rendererGone` 标志，Toast 提示「画面进程已被系统回收，正在自动重载…」
- 在前台就立刻 `recreate()`；在后台就等下一次 `onResume` 再 `recreate()`
  （后台重建看不见，还会在不可见状态下再申请一次渲染进程，不划算）

`onResume` / `onPause` 相应加了 `rendererGone` 判断：渲染进程已经没了就不再往
那具死掉的 WebView 上下发 JS（`evaluateJavascript` 会让情况更糟）。

`recreate()` 等于「同一个进程内换一个新 Activity + 新 WebView + 新渲染进程」，
游戏会重新加载，但**进程没死、任务没丢、不用重新点图标**。这是渲染进程
真的死掉之后的兜底；正常情况下第 1 条改动让它根本不会死。

## 不做什么

- 不改 `shell.html` 的任何一行（冻结逻辑原样保留）
- 不改帧率 / 画幅 / 画质预算 / 节流器 / 服务器地址
- 不改前台服务 `MoleKeepAlive` 的保活逻辑

## 验证要点

| 场景 | 期望 |
| --- | --- |
| 切后台 30 秒后返回 | 画面直接继续，不重载 |
| 切后台 10 分钟返回 | 同上 |
| 通知栏 | 后台期间有「摩尔庄园 挂机运行中」 |
| logcat `MoleShell` | 正常不该出现 `渲染进程已消失` |

真出现 `渲染进程已消失（didCrash=...，退出时优先级=...）`，说明渲染进程还是被
回收了，日志里的 `退出时优先级` 就是本次修复是否生效的直接证据
（`0` = WAIVED，`1` = IMPORTANT）。
