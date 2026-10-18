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
        var types = ['loadedmetadata', 'loadeddata', 'progress', 'error', 'panic',
                     'fscommand', 'onFSCommand', 'ready', 'loadstart'];
        for (var i = 0; i < types.length; i++) {
            (function (t) {
                try {
                    p.addEventListener(t, function (e) {
                        var extra = '';
                        try { if (e && e.detail !== undefined) extra = ' detail=' + JSON.stringify(e.detail); } catch (x) {}
                        try { if (e && e.error) extra += ' error=' + e.error; } catch (x) {}
                        log('事件 ' + t + extra);
                        /* panic = Ruffle 自我放弃，画面停在错误面板上。
                           实测触发点：wgpu 后端在 Adreno Vulkan 驱动上过不了
                           create_render_pipeline 的 VERTEX shader 校验
                           （panicked at wgpu-30.0.1/src/backend/wgpu_core.rs:1414）。
                           此时唯一出路是清空重载，把信号交给 Java。 */
                        if (t === 'panic') {
                            /* 把「本机 wgpu 后端不可用」记下来：shell.html 读这个键，
                               下次加载直接换 canvas，避免 panic → 重载 → 再 panic 的死循环。
                               这是唯一能覆盖「第一次启动就崩、Java 来不及降档」场景的落点。 */
                            try { localStorage.setItem('mole_force_renderer', 'canvas'); } catch (x) {}
                            try { MoleBridge.onPanic(); } catch (x) {}
                        }
                        // 影片真实分辨率到手 → 校正容器尺寸并重算缩放与渲染预算
                        if (t === 'loadedmetadata' && p.metadata && p.metadata.width) {
                            window.__moleMovieW = p.metadata.width;
                            window.__moleMovieH = p.metadata.height;
                            try {
                                var f = window.__moleFit();
                                log('影片分辨率 ' + p.metadata.width + 'x' + p.metadata.height
                                    + ' → 容器校正，缩放=' + f.toFixed(3));
                            } catch (x) {}
                        }
                    });
                } catch (x) {}
            })(types[i]);
        }
        log('已挂事件监听：' + p.tagName.toLowerCase());
        watchCanvas(p);
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
        if (p) watchCanvas(p);          // Ruffle 会在缩放/上下文重建时换掉 canvas，这里补挂
        if (tries < 14) setTimeout(tick, 2500);
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
        log('Ruffle 就绪。桥端口=' + port + ' readyState=' + document.readyState);

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
           5 秒一次的开销只是一次 shadowRoot.querySelector，可以忽略。 */
        setInterval(function () {
            var p = findPlayer();
            if (p) watchCanvas(p);
        }, 5000);
    }

    if (document.readyState === 'complete' || document.readyState === 'interactive') boot();
    else document.addEventListener('DOMContentLoaded', boot);
})();
