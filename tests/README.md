# 离线断言测试

这三个脚本**不 mock 逻辑**，而是从 `src/web/shell.html` 里按标记切出真实代码块，
塞进 `vm` 沙箱里跑。所以测的就是打进安装包的那一份，不是另外抄的一份。

```bash
node tests/clock_test.js    # 27 项：虚拟时间轴钳制
node tests/bg_test.js       # 34 项：后台保活状态机
node tests/pad_test.js      # 96 项：触控板落点与生命周期
```

全部通过时输出 `ALL PASS`，退出码 0；有失败项退出码 1。

也可以指定别的文件：

```bash
node tests/pad_test.js patches/1.0.6/shell.html   # 跑历史版本，会红
```

## clock_test.js —— 时间轴钳制

切第 0 段的帧率节流 IIFE（`var TARGET_FPS = 24;` → `window.__moleFps = TARGET_FPS;`）。

覆盖：

- 平时 1:1：60Hz 真实帧喂进去，产出 24fps，虚拟时间跨度 = 真实跨度
- 挂起 300 秒后只推进 1 帧，时间戳不跳变，`__moleClock()` 记 1 次恢复
- 阈值边界：800ms 截断到 250ms、801ms 判定后台恢复、200ms 原样通过
- 时间戳回退不产生负推进，虚拟时钟保持单调
- `__moleSetFps()` 未被破坏（0 与 999 被拒）
- 后台真跑过时 `__moleAlignClock()` 直接对齐真实时间，不把后台时长算成「被切断」

## bg_test.js —— 后台保活

切第 6 段（`__moleEnterBackground` / `__moleLeaveBackground`）。

覆盖：

- `document.hidden` 时把活留给 Ruffle，不抢（避免两套机制同时 tick）
- `startBackgroundTick` 幂等：重复调用不会起第二个 Worker（否则双倍速）
- 游戏本身是暂停态时后台不维持时间轴
- 回前台时 Worker 还在 → 我们接管恢复；Ruffle 已经跑了 visible 分支 → 不重复 restart
- 后台压根没跑 → 绝不对齐时间轴（否则补帧风暴）
- 没有播放器时不抛异常

## pad_test.js —— 触控板落点

切第 5 段（5.1 / 5.2 / 5.3）。

覆盖：

- 挂载门禁：必须「`<ruffle-player>` + 其 shadow root 里的 `canvas`」都在才挂
- 真机 CSS 视口 800×360（黑边仅 91px）必须落右侧黑边——1.0.6 的阈值就卡在这里
- 20:9 / 18:9 / 平板 4:3 的落点、宽度封顶 220、离屏缘 ≥20px
- 满幅（四边无黑边）不建板子，只留靶区，图层整体不可见
- `__molePad.corner(true)` 的显式兜底尺寸 168×112
- 转屏：右黑边 ↔ 满幅，板子跟着建 / 拆
- `trackpad('off')` 只改外观：靶区在、板子在、落点不变（走的是 `opacity`）
- `off()` 拆图层、OmniPad 缺席时安全降级

## 局限

这三个脚本验证的是**壳层逻辑**，不覆盖：

- Ruffle WASM 内部行为（只按已知源码路径做了替身）
- 真实 GPU / 驱动、真实 WebView 内核版本差异
- 真实服务器时序校验（需要真机挂机验证）
- 鸿蒙 ArkWeb 与 Android WebView 的行为差异

所以 `ALL PASS` 只说明「逻辑没写错」，不代表「真机没问题」。
发布前仍需要真机跑一遍，清单见 [../CHANGELOG.md](../CHANGELOG.md) 的 Known Issues。
