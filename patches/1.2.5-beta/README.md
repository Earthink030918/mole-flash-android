# 1.2.5-beta — 修「按键按死」与「核心重入 panic 不降档」（Android 26）

## 基线 → 产物

| 项 | 基线 | 1.2.5-beta |
| --- | --- | --- |
| Android | `1.2.4-beta`（versionCode 25，10,368,388 B） | `mole-flash-1.2.5-beta.apk`（versionCode **26**，10,372,484 B） |

```
af041077e53fa4f536c38b6246f6352f0387212549f209708519733d01a12d89  mole-flash-1.2.5-beta.apk
```

签名**沿用 1.2.4-beta 那把新密钥**（证书 SHA-256 `b9197126…ae845bee`，v1+v2+v3），
所以装着 1.2.4-beta 的机器可以直接覆盖升级，`mole_shell` 里的服务器地址缓存、
游戏的本地存档都不用重来。只有 1.2.0 及更早的版本仍需先卸载（那把旧证书是 `974EA1B9…`）。

## 这一版面对的那份日志

群友（PHZ110 / Android 16 / Chromium 138 / Mali-G720-Immortalis MC12）打出来的报告，
关键几行原文：

```
屏幕: 795x362 | 视口: 754x361 | DPR: 1.5002479953724475
GPU: ARM | Mali-G720-Immortalis MC12
画布: 无画布
像素预算: 1210000 px（生效 1210000，档位 0）
影片: 960x560 | 缩放: 0.645
已运行: 89s
本次会话 panic 次数: 1
后端: wgpu-webgl（降级档位 0）

判定: 非渲染类
panic 正文: … panicked at core\src\player.rs:485:16: arena already borrowed …

JS 运行时错误（最近 2 条）
  16:31:25 Uncaught RangeError: Maximum call stack size exceeded @wasm://wasm/ruffle_web.wasm-03c96346:1:8606087
  16:31:25 Uncaught RuntimeError: unreachable @wasm://wasm/ruffle_web.wasm-03c96346:1:10581057
```

日志末尾是方向键的三行，紧接着就是 panic：

```
方向键已展开（OmniPad）
方向键已收起（OmniPad）
方向键已展开（OmniPad）
```

## 一、`arena already borrowed` 到底是什么

不是显卡，不是显存，也不是游戏内容出错 —— 是**重入**。

Ruffle 的 `Player` 用 `gc_arena` 存全部 GC 对象，每次进 wasm 调 Player 接口都要先拿借用：

```rust
// core/src/player.rs
fn enter_arena_mut<F, T>(&mut self, f: F) -> T { …
    let borrow = arena.try_borrow().ok();
    let result = borrow.and_then(|arena| { … });
    result.expect("arena already borrowed")     // 借不到 = 有人在借用，直接 panic
}
```

所以这条 panic 的唯一含义是：**arena 已经被借走的时候，又有人进来调了一次 Player**。
同一秒里先出现 `Maximum call stack size exceeded`（wasm 里的栈溢出），
再出现 `RuntimeError: unreachable`，然后才是 borrow panic —— 顺序也对得上：
JS 侧抛出的异常穿过 Rust 帧时不会跑析构，借用守卫来不及释放，紧接着的调用就撞上「已借用」。

能在这颗 wasm 内部回调 JS、从而制造重入的，只有后端自己：
`wgpu` 的 web 后端是 Promise / 回调式的 GL 胶水（submit、map、错误作用域都会回调进 wasm），
`webgl` / `canvas` 后端是纯同步调用，没有这一层往返。

## 二、改了什么

### 1. 降档阶梯认识「核心重入类」（`mole_boot.js`）

原来只有两类判定：命中 GPU 关键词 → 降档；否则 → 「非渲染类」，档位不动，只重载。
这份日志被判成后者，于是：后端不变 → 重载 → 还是 `wgpu-webgl` → 同样再撞一次。

现在多一类，判据只认**确凿的重入特征**：

```js
var looksReentry = /arena already borrowed|already mutably borrowed|Maximum call stack
                  |stack overflow|RuntimeError: unreachable/i.test(flat + ' ' + title + ' ' + recentErr);
var reentryOnWgpu = looksReentry && /wgpu/i.test(backend);
```

- `recentErr` 取第 8 段记下的最近一条 JS 错误，**只认 15 秒内的**——
  panic 正文里没有 `Maximum call stack` 这些字，它们只在 `window.onerror` 里；
  但 80 秒前路过的一个无关 RangeError 也不该拿来给这次 panic 定性；
- 只有当前后端是 `wgpu` 才降一档。`webgl` / `canvas` 上没有那层回调往返，
  重入不可能来自后端，降档就是白白降画质 —— 那种情况仍然只重载；
- 判定文案改成三档可读的：`渲染后端类（驱动/显存）` / `核心重入类（borrow 重入，wgpu 回调整疑）` /
  `内容/内存类（换后端无用）`。

代价说明：这是一次**渲染抽象层**的切换（`wgpu-webgl → webgl`），
分辨率、像素预算、`quality`、帧率、画幅一个都没动；而且只在本机真 panic 过之后才发生，
带 `localStorage` 记忆，不会每次启动都往下掉。

### 2. 方向键不再把按键「按死」（`shell.html` 第 9 段）

面板收起用的是 `opacity + visibility + pointer-events:none`（不能改成 `display:none`，
否则 OmniPad 量到的矩形变成 0，重新展开时方向全乱）。代价是：
**收起之后这个面板再也收不到 `pointerup` / `pointercancel`**。

于是「按住某个方向 → 点圆钮收起」这条路上，KEYUP 永远发不出去。而 OmniPad 的
按键 emitter 是这么写的：

```js
press(){ if (!this.mapping || this.isPressed) return; this.isPressed = true; … KEYDOWN … }
release(){ if (!this.mapping || !this.isPressed) return; this.isPressed = false; … KEYUP … }
reset(){ this._cachedTarget = null; this.isPressed && this.release(false); }
```

`isPressed` 一旦卡在 true：KEYUP 再也不发，下一次 `press()` 也会被开头的 `isPressed` 挡掉 ——
**这个方向在游戏里就是永久按下状态，而且这个键从此失灵**。

修法两层：

```js
function releaseAll(why) {
  dpad.core.reset();                 // OmniPad 侧：四个 emitter 全 release + state 打回初值
  for (每个方向) { downSet[d]=0; 高亮去掉; fireKey(d, false); }   // 兜底模式 / 双保险
}
```

调用点：`toggle(false)`（收起）、`off()`（拆浮钮）、`document.visibilitychange → hidden`（切后台）、
`window.blur`（失焦）。对没按下的方向多发一次 KEYUP 在 Flash 里是空操作，
所以不区分「有没有真按过」，全发，简单不漏。

新增 `tests/dpad_test.js`（22 条断言）把这条路径钉住：按下 → 收起 → 必须补发 4 个 KEYUP、
必须调 `core.reset()`、重新展开后同一方向仍能发 KEYDOWN。

需要诚实地说：**不能断言这就是那份日志里 panic 的唯一触发点**。
栈溢出发生在 wasm 内部，我们只能从「日志末尾正好是方向键展开/收起」和
「按住状态泄漏是我们自己确凿的缺陷」这两点出发把它关掉；
另一半（重入是后端回调造成的可能）用心跳里的降档阶梯兜。两条都不碰画质。

### 3. 报告不再丢「画布」这一栏（`shell.html` 第 8 段）

panic 之后 Ruffle 会把 canvas 从 shadow 里摘掉，于是报告里那一栏只剩 `无画布`——
恰恰是最该看的一项。现在每 5 秒采一次（一次 `shadowRoot.querySelector`，不进主循环），
panic 时改用最后一次实测值，并标明来源：

```
画布: 1440x840（CSS 960x560）（panic 后 canvas 已被移除，此为最后一次实测）
```

## 三、没有动的

画质（`quality` / 像素预算 / `MAXPIX` / `DENSITY` / `FLOOR` / 软地板）、帧率 24 与节流器、
画幅（`960×560` + letterbox / `#wrap` 变换）、五层输入法守卫（含焦点守卫那 24 行）、
无损纹理回收、`PIXEL_BUDGETS` 数组、OmniPad 本体逻辑、`AndroidManifest.xml`、引擎三件套。

**一处试过又撤掉的改动**：日志里「触控板重新定位」在两个解之间来回跳
（`width 51px ↔ 30px`、`top 133 ↔ 132`，5 次/20 秒），本想加「同一新解连续两次才采纳」
的粘滞去抖来消灭它。改完 `tests/pad_test.js` 立刻红了两条几何用例（转屏、画幅变化要求
一秒内重新贴边），说明这会破坏既有契约，而抖动本身只是浮层重排、不压画面也不碰画布。
**撤掉**，留给下一轮单独处理。

## 四、构建与签名

```bash
java -jar apktool.jar b dec -o unsigned-1.2.5-beta.apk
zipalign -p -f 4 unsigned-1.2.5-beta.apk aligned.apk
apksigner sign --ks keystore/mole-release.jks --ks-key-alias mole \
  --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true \
  --min-sdk-version 21 --out mole-flash-1.2.5-beta.apk aligned.apk
```

`apktool.yml` 只改了 `versionCode 25 → 26`、`versionName 1.2.4-beta → 1.2.5-beta`；
`shell.html` 里的 `APPV` 同步成 `1.2.5-beta`（报告里那一行用它）。

## 五、验证

| 项 | 结果 |
| --- | --- |
| `aapt2 dump badging` | `com.taomee.mole` / `versionCode='26'` / `versionName='1.2.5-beta'` / minSdk 21 / targetSdk 31 |
| `apksigner verify --print-certs` | Verifies；v1 ✔ v2 ✔ v3 ✔；证书 SHA-256 `b9197126…ae845bee`（与 1.2.4-beta 同） |
| `zipalign -c 4` | 通过 |
| APK 内 assets | `shell.html` md5 `59c36155…`、`mole_boot.js` md5 `cdf74a2e…`，与 `src/web/` 同源一致 |
| `dexdump` | `CrashReport;`、`CrashReport$1;`、`MainActivity$JsBridge;` 都在（smali 本轮未改） |
| 离线断言 | text 24、clock 34、bg 54、**panic 41**（新增 7 条：重入分类 ± wgpu / 15s 时效）、**dpad 22** 全绿；`pad_test` 79/17 —— 与 1.2.0 起既有基线完全一致，零新增失败 |

## 六、已知限制

1. 如果 15 秒内既有 GPU 类 panic 又有一条无关的栈溢出，判定会偏「重入」，
   降档方向一致（都是往下走），不会更糟。
2. `webgl` / `canvas` 后端上的重入 panic 只重载、不降档 —— 那已经没有更低档位可降
   （`canvas` 是 CPU 软渲染），降到那儿等于换引擎。
3. 切后台时补发 KEYUP 依赖 `visibilityState` 变化；ColorOS 上「划掉任务卡」不一定触发，
   但那种场景进程本来就要被杀，重进游戏按键状态是新的。
4. 触控板几何抖动（见「没有动的」）仍在，只是浮层重排，不影响画面与输入命中。
