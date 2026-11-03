# 1.1.3-beta：把屏幕键盘还原成普通文本框

基线 1.1.2-beta（versionCode 16）→ 本版 `1.1.3-beta`（versionCode **17**）。
**只改一个文件：`assets/ruffle/shell.html`**，Java 壳层、画幅、帧率、节流器、
服务器地址一律未动。

---

## 1) 撤掉「暂时关闭英文字母」

1.1.2-beta 在输入层把 `a-zA-Z` 全部丢弃（`LATIN = false`）。当时的想法是
「拼音字母不该进游戏」，实际后果比收益大：

- **拼音本来就是以字母进来的**。屏蔽字母等于把中文输入法一起废掉；
- 不走 `composition` 事件、只靠 `input` 逐字上报的输入法（部分 ROM 自带输入法、
  第三方五笔/双拼），字母被丢之后既不进游戏也不进候选框，**打字完全没反应**；
- 用户侧的感受就是「输入框被锁成英文模式 / 中文打不出来」。

现在这条路彻底删掉：`sanitize()` 只过滤控制字符，`a-zA-Z`、数字、符号、汉字
全部放行。`__moleKb.latin()` 保留为空壳（恒返回 `true`），旧脚本调用不会报错。

## 2) 输入框保持最普通的文本类型

`#virtual-keyboard` 是 Ruffle 在 shadow DOM 里自建的隐藏输入框，原始属性是：

```html
<input aria-hidden="true" id="virtual-keyboard" type="text"
       autocomplete="off" autocorrect="off" autocapitalize="none">
```

`type="text"` 本来就是普通文本，问题在 `autocapitalize="none"` —— 某些输入法把
它当成「不要自动大写」的强提示，配合被屏蔽的字母，用户会以为进了英文直输模式。
本版在 `styleKb()` 里显式收敛成：

| 属性 | 处理 |
| --- | --- |
| `type` | 保持 `text` |
| `autocapitalize` | **移除**，不指定任何大小写/语言倾向 |
| `inputmode` | **移除**，不指定键盘形态，交给输入法自己判断 |
| `autocomplete` / `autocorrect` / `spellcheck` | 保持关闭（避免联想替换游戏文本） |

中文完全由系统输入法负责：组合期（`composing` 或 `inputType === "insertCompositionText"`）
一个字符都不派发、也**不清空** value；`compositionend` 之后才把汉字派发进播放器。

## 3) 键盘"闪退"：两个真实成因

### 3.1 隐藏输入框在视口外

Ruffle 的样式是：

```css
#virtual-keyboard { height:1px; width:1px; opacity:0; position:absolute; top:-100px }
```

`top:-100px` 让它落在**视口之外**。Android WebView 聚焦一个视口外的可编辑元素时，
会先尝试把它滚进可视区；而 `#wrap` 是 `overflow:hidden`、舞台又是
`transform: scale()`，根本滚不动 —— 于是键盘弹起后立刻被系统收回，表现就是
「点一下闪一下就没了」。

本版在 `styleKb()` 里用 inline `!important` 覆盖成视口内的 1px 元素：

```
position:fixed; left:0; top:0; width:1px; height:1px;
opacity:0.01;              /* 不能是 0：部分 ROM 用可见性判定能否弹键盘 */
pointer-events:none;       /* 不抢触摸 */
z-index:-1; font-size:16px;
caret-color:transparent; -webkit-text-fill-color:transparent;
```

### 3.2 `openVirtualKeyboard()` 的 `setTimeout(0)`

Ruffle 原实现：

```js
openVirtualKeyboard() {
  this.instance?.has_focus()
    ? this.virtualKeyboard.focus({preventScroll:true})
    : setTimeout(() => this.virtualKeyboard.focus({preventScroll:true}), 0);
}
```

点 Flash 输入框的那一瞬间焦点还在别处，`has_focus()` 为假，走的永远是
`setTimeout` 那条 —— 已经跳出用户手势的同步调用栈，Android WebView 放行弹键盘的
窗口很窄，结果就是「点了要等一下」「弹出来又缩回去」。

本版包装 `openVirtualKeyboard`（挂在 custom element 的原型上，只包一次）：
在手势栈里先同步 `focus()`，成功（`shadow.activeElement === input`）就直接返回，
不再走它的延时分支；同步失败才回落到原实现。

## 4) 防抖：去重而不是"延迟"

1.1.2-beta 用「读到内容后 80ms 再清空 value」来避开输入法组合。这个延迟本身是
新的问题源：输入法通过 `InputConnection` 同步这个 value，延迟窗口里它会把旧内容
再写回来（于是重复），又会和下一次按键抢同一块缓冲。

本版改为**同步清空 + 状态去重**：

| 机制 | 规则 |
| --- | --- |
| 回声 | 60ms 内同一段文本原样再来一次 → 丢弃（输入法把刚提交的内容同步回来） |
| 前缀 diff | 新 value 以上一次为前缀 → 只派发新增的部分 |
| 退格 | `inputType` 以 `delete` 开头 → 只清空，**绝不**重发剩余字符 |
| 抖动 | 同一字符 35ms 内重复（`text.length === 1` 时）→ 丢弃 |
| 洪水 | 100ms 内超过 12 个字符的突发 → 丢弃超出部分 |

`prevText`（上一次处理过的完整 value）在清空输入框后**保留**，退格判断和前缀 diff
都靠它；`onCompStart` / `onCompEnd` 时清零，避免拼音参与 diff。

## 5) 键盘弹出时不再重做等比适配

4.4 段原来监听 `visualViewport.resize`，120ms 防抖后重算 `#wrap` 尺寸、改
`transform`、写 `--f`。软键盘弹出的时间点正好落在这个窗口里 —— 等于在键盘刚出现
时把画面重排一次：观感是闪一下，WebView 侧还会因为布局变化重新判定焦点，部分 ROM
直接把软键盘收回去。

本版加 `kbOpen()` 判定（覆盖式 `adjustPan/nothing` 与挤压式 `adjustResize` 两种系统
行为），键盘占屏期间**直接跳过 refit**，舞台尺寸保持「画幅不变」。键盘收起后
`noteBase()` 自动恢复基线。

---

## 未改动

- 画幅：`#wrap` 尺寸、`transform: scale(f)`、`--f` 计算方式
- 帧率 24、rAF 节流器、服务器地址
- `quality`（1.1.2-beta 已按 Ruffle 源码结论保持不动）
- 渲染分辨率预算（1.1.2-beta 的 `min(nativePx, max(shownArea×1.44, BUDGET), …)`）
- OmniPad 触控层与布局
- Java 壳层全部（`startForegroundService` / `MoleKeepAlive` / `onRenderProcessGone` /
  `setRendererPriorityPolicy`）

## 验证

- 3 个内联 script 块 `node --check` 通过。
- 从 `shell.html` 切出 4.5 段真实代码 + DOM 桩，跑 7 组用例：

```
1 英文字母 → 全部派发（w/o/a/n 各 keydown+keyup），value 已清空
2 组合期 0 派发、value 保留 "woni"；compositionend 后提交「蜗牛」
3 回声去重 → 「你好」只派发一次
4 连打 "11"（间隔 80ms）→ 两次都派发，未被抖动窗误杀
5 退格(inputType=deleteContentBackward) → 新增派发 0，value 已清空
6 输入法带回旧内容 "蜗牛快" → 只派发「快」
7 openVirtualKeyboard 同步 focus 成功，setTimeout 分支调用 0 次
```

包内核验（`v1.1.3-beta`）：

```
versionCode=17  versionName=1.1.3-beta
sdkVersion=21   targetSdkVersion=31   compileSdkVersion=35
assets/ruffle/shell.html 171,281 B，与源文件逐字节一致
dex：startForegroundService / onUserLeaveHint / onRenderProcessGone /
     setRendererPriorityPolicy / MoleKeepAlive 全部仍在
签名：974EA1B9…（与 v1.1.0 同源，可直接覆盖安装）
```
