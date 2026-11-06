/*
 * mole_boot.js —— 空壳页里把 /Client.swf 挂给 Ruffle
 * =====================================================
 *
 * 与上一版的根本差别：上一版寄生在官网首页上，要跟老 SWFObject、帮助页 iframe、
 * 重复注入三方抢 DOM，最后只能猜为什么黑屏。这一版由 App 自己发页（shell.html），
 * 页面里只有 #stage 一个容器，没有第三方脚本插手 —— 出问题就是 Ruffle 的问题，
 * 而且 console 已被全量转发，错误会直接出现在 logcat 和屏幕 HUD 上。
 *
 * 挂载走两条路：
 *   A. polyfill：往 #stage 插 <embed type="application/x-shockwave-flash">，
 *      ruffle.js 的 polyfill 会自动把它换成 <ruffle-player> 并搬运参数（官方推荐路径）
 *   B. 兜底：若 2.5 秒内 polyfill 没动静，直接用 RufflePlayer.newest().createPlayer()
 */
(function () {
    var TAG = '[MoleShell]';
    var SWF = '/Client.swf';
    var tries = 0;

    function log(m) {
        try { console.log(TAG + ' ' + m); } catch (e) { /* console 已被接管 */ }
    }

    function stage() { return document.getElementById('wrap'); }

    function findPlayer() {
        return document.querySelector('ruffle-player,ruffle-embed,ruffle-object');
    }

    function describe(p) {
        var s = [];
        try { s.push('readyState=' + p.readyState); } catch (e) {}
        try { s.push('meta=' + (p.metadata ? (p.metadata.width + 'x' + p.metadata.height) : 'null')); } catch (e) {}
        try { s.push('inst=' + (p.instance ? 'yes' : 'no')); } catch (e) {}
        try {
            var sh = p.shadowRoot;
            var c = sh ? sh.querySelector('canvas') : null;
            s.push('canvas=' + (c ? (c.width + 'x' + c.height + '/css' + c.clientWidth + 'x' + c.clientHeight) : 'none'));
        } catch (e) {}
        try { s.push('box=' + p.clientWidth + 'x' + p.clientHeight); } catch (e) {}
        return s.join(' ');
    }

    /**
     * WebGL 上下文监听 —— GPU 显存耗尽的最后预警
     * ==========================================
     *
     * 真机崩溃链路的完整形态（iQOO Neo9 / Android 16，logcat 实证）：
     *   W/Adreno-GSL: sharedmem_gpumem_alloc: mmap failed errno 12 Out of memory
     *   E/Adreno-GSL: kgsl_sharedmem_alloc() failed! Allocation size: (4 KB)
     *   F/libc: Fatal signal 5 (SIGTRAP) in tid (RenderThread), pid (com.taomee.mole)
     *   → ApplicationExitInfo: reason=5 (APP CRASH(NATIVE))，RSS 1.0GB
     *
     * 也就是说崩溃发生在本进程的 RenderThread 上（GPU 是 in-process 的），
     * 而 App 层没有任何 Java 回调能拦 —— 进程被内核直接打死。
     *
     * 但在这之前，驱动通常在显存吃紧时**先丢上下文**（webglcontextlost），
     * 这是唯一一个能提前拿到手的信号。所以：
     *   · lost          → 立刻上报，让 Java 侧就地降档（不掉线，接着玩）
     *   · 2.5s 未恢复   → 再上报一次 dead，由 Java 决定重载（此时画面本来也废了）
     *   · restored      → 取消定时器，Ruffle 自己救回来了，什么都不用做
     *
     * 刻意**不**调 preventDefault：Ruffle 有自己的上下文恢复逻辑，
     * 拦下默认行为反而可能让它拿不回画布。
     */
    function watchCanvas(p) {
        try {
            var sh = p.shadowRoot;
            if (!sh) return;
            var c = sh.querySelector('canvas');
            if (!c || c.__moleCtxWatched) return;      // canvas 被 Ruffle 重建时标记会丢，自动重挂
            c.__moleCtxWatched = 1;

            var lostTimer = null;
            c.addEventListener('webglcontextlost', function () {
                log('!! WebGL 上下文丢失（GPU 显存吃紧）canvas=' + c.width + 'x' + c.height);
                if (lostTimer) clearTimeout(lostTimer);
                lostTimer = setTimeout(function () {
                    lostTimer = null;
                    log('!! WebGL 上下文 2.5s 未恢复 → 上报 Java');
                    try { MoleBridge.onGpuExhausted('dead'); } catch (e) {}
                }, 2500);
                try { MoleBridge.onGpuExhausted('lost'); } catch (e) {}
            }, false);

            c.addEventListener('webglcontextrestored', function () {
                if (lostTimer) { clearTimeout(lostTimer); lostTimer = null; }
                log('WebGL 上下文已恢复（Ruffle 自行修复）');
            }, false);

            /* 第二个 canvas 才是 Ruffle 真正渲染的那个时不影响 —— 只挂当前找到的，
               并在 tick() 里周期性重扫，重建后的新 canvas 会被自动补挂。 */
            log('已挂 WebGL 上下文监听 canvas=' + c.width + 'x' + c.height);
        } catch (e) {}
    }

    function watch(p) {
        if (!p || p.__moleWatched) return;
        p.__moleWatched = 1;
        /* 'panic' 已从这里删掉 —— Ruffle 不派发该事件（见上面的 panic 侦测）。
           留着一个永远不会触发的监听，只会让人以为"兜底已经有了"。 */
        var types = ['loadedmetadata', 'loadeddata', 'progress', 'error',
                     'fscommand', 'onFSCommand', 'ready', 'loadstart'];
        for (var i = 0; i < types.length; i++) {
            (function (t) {
                try {
                    p.addEventListener(t, function (e) {
                        var extra = '';
                        try { if (e && e.detail !== undefined) extra = ' detail=' + JSON.stringify(e.detail); } catch (x) {}
                        try { if (e && e.error) extra += ' error=' + e.error; } catch (x) {}
                        log('事件 ' + t + extra);
                        // 影片真实分辨率到手 → 校正容器尺寸并重算缩放与渲染预算
                        if (t === 'loadedmetadata' && p.metadata && p.metadata.width) {
                            window.__moleMovieW = p.metadata.width;
                            window.__moleMovieH = p.metadata.height;
                            try {
                                var f = window.__moleFit();
                                log('影片分辨率 ' + p.metadata.width + 'x' + p.metadata.height
                                    + ' → 容器校正，缩放=' + f.toFixed(3));
                            } catch (x) {}
                            logRendererInfo(p);
                        }
                    });
                } catch (x) {}
            })(types[i]);
        }
        log('已挂事件监听：' + p.tagName.toLowerCase());
        watchCanvas(p);
        watchPanic(p);
        logRendererInfo(p);
    }

    /* 实际选中的后端 / 适配器 —— 华为设备排障全靠这一行。
       Ruffle 把 create_renderer 的最终结果写进 player.rendererDebugInfo，
       影片加载完之后才有内容，所以这里做一次性输出。 */
    function logRendererInfo(p) {
        if (!p || p.__moleInfoLogged) return;
        try {
            var info = String(p.rendererDebugInfo || '').replace(/\s*\n\s*/g, ' | ').slice(0, 300);
            if (!info) return;
            p.__moleInfoLogged = 1;
            log('渲染器实际情况: ' + info);
        } catch (e) {}
    }

    /* ------------------------------------------------------------------
     * panic 面板侦测（1.1.5-beta）
     * ------------------------------------------------------------
     * 以前这里是错的：`p.addEventListener('panic', ...)`。
     * Ruffle 根本不派发这个事件 —— 整个 ruffle.js 里 dispatchEvent 只发
     * loadedmetadata / loadeddata 两个 CustomEvent，"panic" 在那里只是
     * 一个 DOM id。于是 MoleBridge.onPanic() 一次都没被调用过：
     * 用户看到红屏之后就那么干挂着，既没有恢复也没有日志。
     *
     * 真正的信号是 DOM 本身。ruffle.js 的 panic() 会
     *   container.textContent = ''  →  append(<div id="panic">)
     * 而 container 是 `shadow.getElementById("container")` ——
     * 也就是说面板挂在 **shadowRoot 里**（light DOM 是查不到的，
     * 必须从 p.shadowRoot 找）。里面是 #panic-title / #panic-body /
     * #panic-details-*。
     * 所以这里盯 shadowRoot 的 childList+subtree —— 播放期间 shadow 里
     * 几乎不会有节点增删（菜单/视频是 class 切换，不触发 childList），
     * 开销可以忽略；再用 5s 巡视做兜底（观察器建不起来时仍能发现）。
     * ------------------------------------------------------------------ */

    function panicRoot(p) {
        try { return (p && p.shadowRoot) || null; } catch (e) { return null; }
    }

    function panicText(p) {
        var t = '', b = '', d = '';
        try {
            var sh = panicRoot(p);
            if (!sh) return { title: t, body: b, detail: d };
            var e1 = sh.getElementById('panic-title');
            if (e1) t = (e1.textContent || '').trim();
            var e2 = sh.getElementById('panic-body');
            if (e2) b = (e2.textContent || '').trim();
            var ta = sh.querySelector('#panic-details-content textarea');
            if (ta && ta.value) d = String(ta.value).trim();
        } catch (e) {}
        return { title: t, body: b, detail: d };
    }

    function hasPanic(p) {
        var sh = panicRoot(p);
        if (!sh) return false;
        try { return !!sh.getElementById('panic'); } catch (e) { return false; }
    }

    /* 会话内 panic 次数：放 sessionStorage，随「本次启动」重置。
       （放 localStorage 的话，一台常年 panic 的机器永远爬不出来；
        放内存变量的话，重载一次计数就归零，又变成死循环。） */
    function panicCount(inc) {
        var n = 0;
        try { n = parseInt(sessionStorage.getItem('mole_panic_n') || '0', 10) || 0; } catch (e) {}
        if (inc) {
            n++;
            try { sessionStorage.setItem('mole_panic_n', String(n)); } catch (e) {}
        }
        return n;
    }

    var PANIC_MAX = 4;   // 一台机器最多自动重载 4 次，再多就留红屏，别再闪

    function onPanicDom(p) {
        if (!p || p.__molePanicAt) return;
        p.__molePanicAt = Date.now();

        var x = panicText(p);
        var flat = (x.body + ' ' + x.detail).replace(/\s+/g, ' ').slice(0, 700);
        var up = Math.round((Date.now() - (window.__moleBootAt || Date.now())) / 1000);

        log('!! Ruffle panic 面板出现｜后端=' + (window.__moleRenderer || '?')
            + ' 档位=' + (window.__moleRendererTier || 0) + ' 已运行=' + up + 's');
        log('!! panic 文本: ' + (x.title || '(空)') + ' | ' + (flat || '(空)'));

        /* 是不是「这块 GPU/驱动跟 wgpu 不兼容」？
           wgpu 的 panic 一定带 wgpu / 管线 / 设备丢失 / 纹理 这类词；
           内容类 panic（AVM2 未实现、SWF 解析失败）不带 —— 那种换后端也没用，
           没必要为此把画面降级。 */
        var looksGpu = /wgpu|webgl|webgpu|render|adapter|swap ?chain|context|surface|device\s*lost|pipeline|shader|texture|out of memory|gpu/i
            .test(flat + ' ' + x.title);

        var n = panicCount(true);
        log('!! panic 累计 ' + n + ' 次（上限 ' + PANIC_MAX + '）');

        if (n > PANIC_MAX) {
            log('!! 连续 panic 到上限，停止自动恢复（红屏保留，请把上面这些 !! 行发出来）');
            return;
        }

        if (looksGpu) {
            var next = null;
            try { next = window.__moleRendererBump && window.__moleRendererBump(); } catch (e) {}
            log(next ? '!! 判定为渲染后端不兼容 → 下次改用 ' + next
                     : '!! 判定为渲染后端不兼容，但已没有更低档位可用');
        } else {
            log('!! 判定为非渲染类 panic（内容 / 内存），后端档位不变，只重载');
        }

        try {
            MoleBridge.onPanic();          // Java：空白页中转 2s → 重载
        } catch (e) {
            /* 桥不可用（浏览器里调试）→ 自己重载一次 */
            log('!! 桥不可用，页面自行重载');
            setTimeout(function () { try { location.reload(); } catch (x) {} }, 300);
            return;
        }

        /* Java 那条路有 15s 防抖，命中防抖时它什么都不做 —— 那就等于红屏还挂着。
           6s 后如果面板还在（说明没有开始重载），页面自己来。
           这时重载已经走了 Java 的两步（空白页 2s + 重载），不会打架。 */
        setTimeout(function () {
            if (!hasPanic(p)) return;                       // 已经好了 / 已换页
            if (document.visibilityState !== 'visible') return;
            log('!! 6s 内未开始重载，页面自行重载');
            try { location.reload(); } catch (e) {}
        }, 6000);
    }

    function watchPanic(p) {
        if (!p || p.__molePanicWatched) return;
        var sh = panicRoot(p);
        if (!sh) return;                       // shadow 还没建，等 5s 巡视再试
        p.__molePanicWatched = 1;
        try {
            var mo = new MutationObserver(function () {
                if (hasPanic(p)) {
                    try { mo.disconnect(); } catch (e) {}
                    onPanicDom(p);
                }
            });
            /* 面板被 append 到 shadow 里的 #container，所以要读 subtree */
            mo.observe(sh, { childList: true, subtree: true });
            p.__molePanicMO = mo;
        } catch (e) { /* 观察器不可用，靠 5s 巡视兜底 */ }
        /* 面板可能在我们挂上之前就已经出现（极快的启动期 panic） */
        if (hasPanic(p)) onPanicDom(p);
    }

    /** 路径 A：插 <embed> 让 polyfill 自己接管 */
    function viaPolyfill() {
        var st = stage();
        if (!st) { log('致命：#stage 不存在'); return; }
        st.innerHTML = '';
        var em = document.createElement('embed');
        em.setAttribute('src', SWF);
        em.setAttribute('type', 'application/x-shockwave-flash');
        em.setAttribute('width', '960');
        em.setAttribute('height', '560');
        em.setAttribute('quality', 'low');
        em.setAttribute('wmode', 'opaque');
        em.setAttribute('bgcolor', '#000000');
        em.setAttribute('allowscriptaccess', 'always');
        em.setAttribute('allowfullscreen', 'true');
        em.setAttribute('menu', 'false');
        st.appendChild(em);
        log('已插入 <embed src="' + SWF + '">，等 polyfill 接管');

        var n = 0;
        var t = setInterval(function () {
            n++;
            var p = findPlayer();
            if (p) {
                clearInterval(t);
                log('polyfill 已接管为 ' + p.tagName.toLowerCase());
                watch(p);
            } else if (n > 25) {
                clearInterval(t);
                log('polyfill 25 次(5s)未接管');
            }
        }, 200);
    }

    /** 路径 B：直接 new 一个播放器 */
    function viaApi() {
        var R = window.RufflePlayer;
        if (!R || typeof R.newest !== 'function') { log('致命：RufflePlayer.newest 不可用'); return null; }
        var plugin = R.newest();
        if (!plugin || typeof plugin.createPlayer !== 'function') { log('致命：createPlayer 不可用'); return null; }
        var rp = plugin.createPlayer();
        rp.setAttribute('src', SWF);
        rp.setAttribute('width', '960');
        rp.setAttribute('height', '560');
        rp.setAttribute('quality', 'low');
        rp.setAttribute('bgcolor', '#000000');
        rp.setAttribute('allowscriptaccess', 'always');
        var st = stage();
        st.innerHTML = '';
        st.appendChild(rp);
        watch(rp);
        log('createPlayer 已挂载 ' + SWF);
        return rp;
    }

    function tick() {
        tries++;
        var p = findPlayer();
        log('状态#' + tries + ' 播放器=' + (p ? 1 : 0) + (p ? ' ' + describe(p) : ' 无'));
        if (p) {
            watchCanvas(p);   // Ruffle 会在缩放/上下文重建时换掉 canvas，这里补挂
            watchPanic(p);
        }
        if (tries < 14) setTimeout(tick, 2500);
    }

    /* ------------------------------------------------------------------
     * 主线程冻结看门狗（只写日志，不动任何设置）
     * ------------------------------------------------------------
     * 「登录进去之后卡死」目前一个信号都拿不到：主线程卡住时 rAF 停、
     * 定时器停、console 也不会再有输出，事后看日志完全空白。
     * 唯一能抓到的是「时间跳变」这件事本身：
     * 每秒打一次点，如果两次之间隔了 8s 以上，且页面是可见的，
     * 就说明主线程真的停过 —— 记一笔，不做任何恢复动作
     * （偶发长帧也会被记，但次数极少，不影响判读）。
     * ------------------------------------------------------------------ */
    function freezeWatch() {
        var last = Date.now(), hits = 0;
        setInterval(function () {
            var now = Date.now(), d = now - last;
            last = now;
            if (d < 8000 || hits >= 3) return;
            if (document.visibilityState !== 'visible') return;   // 后台/息屏不算
            hits++;
            var box = '?';
            try {
                var p = findPlayer();
                var c = p && p.shadowRoot ? p.shadowRoot.querySelector('canvas') : null;
                if (c) box = c.width + 'x' + c.height;
            } catch (e) {}
            log('!! 主线程疑似冻结 ' + Math.round(d / 1000) + 's（定时器断流，画布 ' + box
                + '，后端 ' + (window.__moleRenderer || '?') + '）');
        }, 1000);
    }

    function boot() {
        if (window.__moleBooted) return;
        window.__moleBooted = 1;

        if (!window.RufflePlayer) {
            log('致命：window.RufflePlayer 未定义 —— __mole_ruffle__.js 没下发成功');
            return;
        }
        var port = '无桥';
        try { port = window.MoleBridge ? MoleBridge.bridgePort() : '无桥'; } catch (e) {}
        log('Ruffle 就绪。桥端口=' + port + ' readyState=' + document.readyState
            + ' 后端=' + (window.__moleRenderer || '?')
            + ' 降级档位=' + (window.__moleRendererTier || 0));
        freezeWatch();

        viaPolyfill();

        setTimeout(function () {
            if (!findPlayer()) {
                log('→ polyfill 未接管，改走 createPlayer');
                viaApi();
            }
            tick();
        }, 2500);

        /* 长期巡视：Ruffle 在上下文重建 / 分辨率变化时会换掉 canvas 元素，
           换掉后旧的监听随之作废，所以周期性重扫并补挂。
           5 秒一次的开销只是一次 shadowRoot.querySelector，可以忽略。
           panic 面板同时在这里兜一遍 —— 观察器万一建不起来还有它。 */
        setInterval(function () {
            var p = findPlayer();
            if (!p) return;
            watchCanvas(p);
            watchPanic(p);
            try {
                if (!p.__molePanicAt && hasPanic(p)) onPanicDom(p);
            } catch (e) {}
        }, 5000);
    }

    if (document.readyState === 'complete' || document.readyState === 'interactive') boot();
    else document.addEventListener('DOMContentLoaded', boot);
})();
