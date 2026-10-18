package com.taomee.mole;
public class MainActivity extends android.app.Activity {
    private static final String BLUR_JS = "(function(){try{var n=document.querySelectorAll('ruffle-player,ruffle-object,ruffle-embed');for(var i=0;i<n.length;i++){try{n[i].pause&&n[i].pause();}catch(e){}}window.dispatchEvent(new Event('blur'));}catch(e){}})();";
    private static final String CACHE_HEADER = "public, max-age=604800";
    private static final String[] CJK_FONT_CANDIDATES = None;
    private static final String CORE_PREFIX = "core.ruffle.";
    private static final boolean DIAG_HUD = False;
    private static final String[] FONT_SOURCES = None;
    private static final long GPU_POLL_MAX_MS = 60000;
    private static final long GPU_POLL_MIN_MS = 8000;
    private static final int GPU_RELEASE_MB = 410;
    private static final int GPU_SOFT_MB = 400;
    private static final String KEY_CRASHES = "boot_crashes_v4";
    private static final String KEY_GOOD_RUNS = "boot_good_runs_v4";
    private static final String KEY_RUNNING = "boot_running_v1";
    private static final String KEY_TARGETS = "socket_targets_v2";
    private static final String[] LATIN_FONT_CANDIDATES = None;
    private static final String[] LATIN_NAMES = None;
    private static final int MAX_AUTO_RELOADS = 8;
    private static final int MAX_LEVEL = 0;
    private static final int MAX_RELEASES = 10;
    private static final int[] PIXEL_BUDGETS = None;
    private static final String PREF = "mole_shell";
    private static final String P_BOOT = "__mole_boot__.js";
    private static final String P_RUFFLE = "__mole_ruffle__.js";
    private static final long RELEASE_COOLDOWN_MS = 120000;
    private static final String[] SEED_HOSTS_ENC = None;
    private static final int[] SEED_PORTS = None;
    private static final String SHELL_PATH = "/__mole_shell__";
    private static final int SOFT_LEVEL_CAP = 2;
    private static final long STABLE_AFTER_MS = 300000;
    private static final String START_URL = "http://mole.61.com/__mole_shell__";
    private static final String TAG = "MoleShell";
    private int autoReloads;
    private com.taomee.mole.SocketBridge bridge;
    private com.taomee.mole.HttpCache cache;
    private volatile String cjkFontPath;
    private volatile boolean fontsResolved;
    private android.os.Handler gpuHandler;
    private volatile long gpuPollMs;
    private android.os.HandlerThread gpuThread;
    private int gpuTicks;
    private final Runnable gpuWatch;
    private volatile boolean gpuWatchOn;
    private long lastReleaseAt;
    private volatile String latinFontPath;
    private volatile int loadLevel;
    private int releaseCount;
    private volatile boolean releasing;
    private final java.util.LinkedHashSet targets;
    private String ua;
    private android.webkit.WebView web;

    static MainActivity()
    {
        String v2 = "/system/fonts/DroidSansFallbackMonster.ttf";
        String v4 = "/system/fonts/DroidSansFallback.ttf";
        com.taomee.mole.MainActivity.CJK_FONT_CANDIDATES = new String[] {"/system/fonts/NotoSansCJK-Regular.ttc", "/system/fonts/NotoSansCJKsc-Regular.otf"});
        com.taomee.mole.MainActivity.LATIN_FONT_CANDIDATES = new String[] {"/system/fonts/Roboto-Regular.ttf", "/system/fonts/NotoSans-Regular.ttf", "/system/fonts/DroidSans.ttf"});
        String v3 = "verdana";
        String v5 = "calibri";
        String v7 = "times";
        String v9 = "georgia";
        com.taomee.mole.MainActivity.LATIN_NAMES = new String[] {"arial", "consolas"});
        int v0_5 = new String[0];
        com.taomee.mole.MainActivity.FONT_SOURCES = v0_5;
        com.taomee.mole.MainActivity.SEED_HOSTS_ENC = new String[] {"a2hpdGhqbHRraWt0aGls", "a2hpdGhqbHRraWt0bGk=", "a2hpdGtvanRrbGl0a2ti"});
        com.taomee.mole.MainActivity.SEED_PORTS = com.taomee.mole.MainActivity.buildSeedPorts();
        int v0_10 = new int[6];
        v0_10 = {1210000, 900000, 660000, 460000, 320000, 210000};
        com.taomee.mole.MainActivity.PIXEL_BUDGETS = v0_10;
        com.taomee.mole.MainActivity.MAX_LEVEL = (com.taomee.mole.MainActivity.PIXEL_BUDGETS.length - 1);
        return;
    }

    public MainActivity()
    {
        this.targets = new java.util.LinkedHashSet();
        this.autoReloads = 0;
        this.ua = "Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36";
        this.loadLevel = 0;
        this.gpuPollMs = 8000;
        this.gpuTicks = 0;
        this.gpuWatch = new com.taomee.mole.MainActivity$1(this);
        this.lastReleaseAt = 0;
        this.releaseCount = 0;
        return;
    }

    static synthetic boolean access$000(com.taomee.mole.MainActivity p0)
    {
        return p0.gpuWatchOn;
    }

    static synthetic int access$100(com.taomee.mole.MainActivity p0)
    {
        return p0.graphicsMb();
    }

    static synthetic boolean access$1002(com.taomee.mole.MainActivity p0, boolean p1)
    {
        p0.releasing = p1;
        return p1;
    }

    static synthetic void access$1200(com.taomee.mole.MainActivity p0)
    {
        p0.goImmersive();
        return;
    }

    static synthetic String access$1300(String p0)
    {
        return com.taomee.mole.MainActivity.basename(p0);
    }

    static synthetic android.webkit.WebResourceResponse access$1400(com.taomee.mole.MainActivity p0)
    {
        return p0.shellResponse();
    }

    static synthetic android.webkit.WebResourceResponse access$1500(com.taomee.mole.MainActivity p0, String p1)
    {
        return p0.fontResponse(p1);
    }

    static synthetic android.webkit.WebResourceResponse access$1600(com.taomee.mole.MainActivity p0, String p1, String p2)
    {
        return p0.assetStream(p1, p2);
    }

    static synthetic android.webkit.WebResourceResponse access$1700(com.taomee.mole.MainActivity p0, String p1)
    {
        return p0.wasmResponse(p1);
    }

    static synthetic boolean access$1800(String p0)
    {
        return com.taomee.mole.MainActivity.isTaomeeHost(p0);
    }

    static synthetic android.webkit.WebResourceResponse access$1900(com.taomee.mole.MainActivity p0, android.webkit.WebResourceRequest p1)
    {
        return p0.upstream(p1);
    }

    static synthetic void access$200(com.taomee.mole.MainActivity p0, boolean p1)
    {
        p0.releaseTextures(p1);
        return;
    }

    static synthetic int access$2000(com.taomee.mole.MainActivity p0)
    {
        return p0.autoReloads;
    }

    static synthetic int access$2008(com.taomee.mole.MainActivity p2)
    {
        int v0 = p2.autoReloads;
        p2.autoReloads = (v0 + 1);
        return v0;
    }

    static synthetic com.taomee.mole.SocketBridge access$2100(com.taomee.mole.MainActivity p0)
    {
        return p0.bridge;
    }

    static synthetic void access$2200(com.taomee.mole.MainActivity p0, String p1, int p2)
    {
        p0.learnMissingProxy(p1, p2);
        return;
    }

    static synthetic int access$2300()
    {
        return com.taomee.mole.MainActivity.MAX_LEVEL;
    }

    static synthetic int access$300(com.taomee.mole.MainActivity p0)
    {
        return p0.loadLevel;
    }

    static synthetic void access$400(com.taomee.mole.MainActivity p0, int p1)
    {
        p0.raiseLoadLevel(p1);
        return;
    }

    static synthetic int access$508(com.taomee.mole.MainActivity p2)
    {
        int v0 = p2.gpuTicks;
        p2.gpuTicks = (v0 + 1);
        return v0;
    }

    static synthetic int access$600(com.taomee.mole.MainActivity p0)
    {
        return p0.pixelBudget();
    }

    static synthetic long access$700(com.taomee.mole.MainActivity p2)
    {
        return p2.gpuPollMs;
    }

    static synthetic long access$702(com.taomee.mole.MainActivity p0, long p1)
    {
        p0.gpuPollMs = p1;
        return p1;
    }

    static synthetic android.os.Handler access$800(com.taomee.mole.MainActivity p0)
    {
        return p0.gpuHandler;
    }

    static synthetic android.webkit.WebView access$900(com.taomee.mole.MainActivity p0)
    {
        return p0.web;
    }

    private android.webkit.WebResourceResponse assetStream(String p9, String p10)
    {
        try {
            java.io.InputStream v7 = this.getAssets().open(p9);
            java.util.HashMap v6_1 = new java.util.HashMap();
            v6_1.put("Access-Control-Allow-Origin", "*");
            v6_1.put("Cache-Control", "no-store");
            String v0_1 = new android.webkit.WebResourceResponse;
            v0_1(p10, "UTF-8", 200, "OK", v6_1, v7);
            return v0_1;
        } catch (java.io.IOException v10_1) {
            android.util.Log.e("MoleShell", new StringBuilder().append("assets \u7f3a\u5931\uff1a").append(p9).toString(), v10_1);
            return 0;
        }
    }

    private static String basename(String p2)
    {
        int v0_2 = p2.indexOf(63);
        if (v0_2 >= 0) {
            p2 = p2.substring(0, v0_2);
        }
        int v0_4 = p2.lastIndexOf(47);
        if (v0_4 >= 0) {
            p2 = p2.substring((v0_4 + 1));
        }
        return p2;
    }

    private static int[] buildSeedPorts()
    {
        java.util.Iterator v0_1 = new java.util.TreeSet();
        v0_1.add(Integer.valueOf(1863));
        v0_1.add(Integer.valueOf(1865));
        v0_1.add(Integer.valueOf(3200));
        v0_1.add(Integer.valueOf(6665));
        int[] v1_4 = 1860;
        while (v1_4 <= 1880) {
            v0_1.add(Integer.valueOf(v1_4));
            v1_4++;
        }
        int[] v1_6 = 3195;
        while (v1_6 <= 3215) {
            v0_1.add(Integer.valueOf(v1_6));
            v1_6++;
        }
        int[] v1_7 = 6650;
        while (v1_7 <= 6700) {
            v0_1.add(Integer.valueOf(v1_7));
            v1_7++;
        }
        int[] v1_9 = new int[v0_1.size()];
        java.util.Iterator v0_2 = v0_1.iterator();
        int v2_3 = 0;
        while (v0_2.hasNext()) {
            int v4 = (v2_3 + 1);
            v1_9[v2_3] = ((Integer) v0_2.next()).intValue();
            v2_3 = v4;
        }
        return v1_9;
    }

    private void configure()
    {
        this.web.setBackgroundColor(-16777216);
        this.web.setOverScrollMode(2);
        this.web.addJavascriptInterface(new com.taomee.mole.MainActivity$JsBridge(this, 0), "MoleBridge");
        android.webkit.WebView v0_2 = this.web.getSettings();
        v0_2.setJavaScriptEnabled(1);
        v0_2.setDomStorageEnabled(1);
        v0_2.setDatabaseEnabled(1);
        v0_2.setMediaPlaybackRequiresUserGesture(0);
        v0_2.setUseWideViewPort(1);
        v0_2.setLoadWithOverviewMode(1);
        v0_2.setSupportZoom(0);
        v0_2.setBuiltInZoomControls(0);
        v0_2.setDisplayZoomControls(0);
        v0_2.setCacheMode(-1);
        v0_2.setAllowFileAccess(1);
        v0_2.setJavaScriptCanOpenWindowsAutomatically(1);
        v0_2.setMixedContentMode(0);
        try {
            v0_2.setAllowUniversalAccessFromFileURLs(1);
            try {
                v0_2.setUserAgentString(v0_2.getUserAgentString().replace("; wv", ""));
                try {
                    v0_2.setTextZoom(100);
                } catch (com.taomee.mole.MainActivity$6 v1) {
                }
                this.ua = v0_2.getUserAgentString();
                android.util.Log.i("MoleShell", new StringBuilder().append("UA = ").append(this.ua).toString());
                this.web.setWebChromeClient(new com.taomee.mole.MainActivity$5(this));
                this.web.setWebViewClient(new com.taomee.mole.MainActivity$6(this));
                return;
            } catch (com.taomee.mole.MainActivity$6 v1) {
            }
        } catch (com.taomee.mole.MainActivity$6 v1) {
        }
    }

    private static java.util.Map corsHeaders()
    {
        java.util.HashMap v0_1 = new java.util.HashMap();
        v0_1.put("Access-Control-Allow-Origin", "*");
        v0_1.put("Access-Control-Allow-Headers", "*");
        v0_1.put("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
        return v0_1;
    }

    private void evaluateLoadLevel()
    {
        String v6_1;
        String v1_0 = 0;
        android.os.Handler v0_10 = this.getSharedPreferences("mole_shell", 0);
        String v3_5 = v0_10.getInt("boot_crashes_v4", 0);
        String v5_8 = v0_10.getInt("boot_good_runs_v4", 0);
        if (android.os.Build$VERSION.SDK_INT < 30) {
            v6_1 = -1;
        } else {
            v6_1 = com.taomee.mole.CrashProbe.recentCrashStreak(this);
        }
        int v10_0;
        if (v6_1 < null) {
            String v1_10;
            String v6_2 = v0_10.getBoolean("boot_running_v1", 0);
            if (v6_2 == null) {
                v1_10 = Math.max((v3_5 - 1), 0);
            } else {
                v1_10 = Math.min((v3_5 + 1), com.taomee.mole.MainActivity.MAX_LEVEL);
            }
            String v3_3;
            v10_0 = v1_10;
            StringBuilder vtmp19 = new StringBuilder().append("\u4e0a\u6b21 ");
            if (v6_2 == null) {
                v3_3 = "\u6b63\u5e38\u7ed3\u675f \u2192 \u8870\u51cf";
            } else {
                v3_3 = "\u5f02\u5e38\u7ed3\u675f \u2192 \u52a0\u91cd";
            }
            android.util.Log.i("MoleShell", vtmp19.append(v3_3).append("\uff08\u6807\u8bb0\u6cd5\uff09").toString());
        } else {
            v10_0 = Math.max(Math.min(v6_1, com.taomee.mole.MainActivity.MAX_LEVEL), Math.min(v3_5, com.taomee.mole.MainActivity.MAX_LEVEL));
            if (v6_1 != null) {
            } else {
                String v5_0 = (v5_8 + 1);
                if ((v5_0 < 2) || (v10_0 <= 0)) {
                    v1_0 = v5_0;
                } else {
                    v10_0--;
                    android.util.Log.i("MoleShell", "\u8fde\u7eed 2 \u6b21\u5e73\u7a33\u542f\u52a8 \u2192 \u753b\u8d28\u56de\u5347\u4e00\u6863");
                }
            }
            android.util.Log.i("MoleShell", new StringBuilder().append("\u4e0a\u6b21\u9000\u51fa\u8fde\u7eed\u5d29\u6e83 ").append(v6_1).append(" \u6b21\uff0c\u4e0a\u6b21\u6863 ").append(v3_5).append(" \u2192 \u672c\u6b21\u6863 ").append(v10_0).toString());
            v5_8 = v1_0;
        }
        this.loadLevel = v10_0;
        v0_10.edit().putInt("boot_crashes_v4", v10_0).putInt("boot_good_runs_v4", v5_8).putBoolean("boot_running_v1", 1).apply();
        android.util.Log.i("MoleShell", new StringBuilder().append("\u8d1f\u8f7d\u6863\u4f4d=").append(this.loadLevel).append(" \u2192 \u9884\u7b97 ").append(this.pixelBudget()).append(" px\uff0c\u540e\u7aef ").append(this.preferredRenderer()).toString());
        new android.os.Handler(this.getMainLooper()).postDelayed(new com.taomee.mole.MainActivity$4(this), 300000);
        return;
    }

    private static String firstExisting(String[] p8)
    {
        int v0 = p8.length;
        int v1 = 0;
        while (v1 < v0) {
            Throwable v2 = p8[v1];
            try {
                long v3_2 = new java.io.File(v2);
            } catch (Throwable v2) {
                v1++;
            }
            if ((!v3_2.isFile()) || ((!v3_2.canRead()) || (v3_2.length() <= 0))) {
            } else {
                return v2;
            }
        }
        return 0;
    }

    private android.webkit.WebResourceResponse fontResponse(String p13)
    {
        String v1_0;
        this.resolveFonts();
        String v0_1 = this.isLatinName(p13);
        if (v0_1 == null) {
            v1_0 = this.cjkFontPath;
        } else {
            v1_0 = this.latinFontPath;
        }
        if (v1_0 == null) {
            String v0_2;
            if (v0_1 == null) {
                v0_2 = this.latinFontPath;
            } else {
                v0_2 = this.cjkFontPath;
            }
            v1_0 = v0_2;
        }
        if (v1_0 != null) {
            try {
                android.webkit.WebResourceResponse v3_5;
                java.io.FileInputStream v9_1 = new java.io.FileInputStream(v1_0);
                java.util.HashMap v8_1 = new java.util.HashMap();
                v8_1.put("Access-Control-Allow-Origin", "*");
                v8_1.put("Cache-Control", "public, max-age=31536000");
            } catch (android.webkit.WebResourceResponse v13_1) {
                android.util.Log.e("MoleShell", new StringBuilder().append("\u5b57\u4f53\u8bfb\u53d6\u5931\u8d25\uff1a").append(v1_0).toString(), v13_1);
                return 0;
            }
            if (!p13.toLowerCase(java.util.Locale.ROOT).endsWith(".ttc")) {
                v3_5 = "font/ttf";
            } else {
                v3_5 = "font/collection";
            }
            String v4_4 = v3_5;
            android.util.Log.i("MoleShell", new StringBuilder().append("\u4e0b\u53d1\u5b57\u4f53 ").append(p13).append(" \u2190 ").append(v1_0).append("\uff08").append((new java.io.File(v1_0).length() / 1024)).append(" KB\uff09").toString());
            android.webkit.WebResourceResponse v13_9 = new android.webkit.WebResourceResponse;
            v13_9(v4_4, 0, 200, "OK", v8_1, v9_1);
            return v13_9;
        } else {
            android.util.Log.e("MoleShell", new StringBuilder().append("\u5b57\u4f53\u4e0b\u53d1\u5931\u8d25\uff1a").append(p13).append(" \u2014\u2014 \u65e0\u53ef\u7528\u7684\u7cfb\u7edf\u5b57\u4f53").toString());
            return 0;
        }
    }

    private void goImmersive()
    {
        try {
            if (android.os.Build$VERSION.SDK_INT < 30) {
                this.getWindow().getDecorView().setSystemUiVisibility(5894);
            } else {
                android.view.View v0_2 = this.getWindow().getInsetsController();
                if (v0_2 != null) {
                    v0_2.hide(android.view.WindowInsets$Type.systemBars());
                    v0_2.setSystemBarsBehavior(2);
                }
            }
        } catch (android.view.View v0_3) {
            android.util.Log.w("MoleShell", new StringBuilder().append("\u6c89\u6d78\u5f0f\u5931\u8d25\uff1a").append(v0_3).toString());
        }
        return;
    }

    private int graphicsMb()
    {
        try {
            if (android.os.Build$VERSION.SDK_INT >= 23) {
                int v1_9 = ((android.app.ActivityManager) this.getSystemService("activity"));
                if (v1_9 != 0) {
                    int v1_1 = v1_9.getProcessMemoryInfo(new int[] {android.os.Process.myPid()}));
                    if (v1_1 != 0) {
                        if (v1_1.length != 0) {
                            int v1_3 = v1_1[0].getMemoryStat("summary.graphics");
                            if (v1_3 != 0) {
                                return (Integer.parseInt(v1_3.trim()) / 1024);
                            } else {
                                return -1;
                            }
                        } else {
                        }
                    }
                    return -1;
                } else {
                    return -1;
                }
            } else {
                return -1;
            }
        } catch (int v1) {
            return -1;
        }
    }

    private static String guessMime(String p2)
    {
        String v2_1 = p2.toLowerCase(java.util.Locale.ROOT);
        String v0_22 = v2_1.indexOf(63);
        if (v0_22 >= null) {
            v2_1 = v2_1.substring(0, v0_22);
        }
        if (!v2_1.endsWith(".swf")) {
            if (!v2_1.endsWith(".js")) {
                if (!v2_1.endsWith(".json")) {
                    if (!v2_1.endsWith(".xml")) {
                        if (!v2_1.endsWith(".css")) {
                            if ((!v2_1.endsWith(".html")) && ((!v2_1.endsWith(".shtml")) && (!v2_1.endsWith(".htm")))) {
                                if (!v2_1.endsWith(".png")) {
                                    if ((!v2_1.endsWith(".jpg")) && (!v2_1.endsWith(".jpeg"))) {
                                        if (!v2_1.endsWith(".gif")) {
                                            if (!v2_1.endsWith(".mp3")) {
                                                return "application/octet-stream";
                                            } else {
                                                return "audio/mpeg";
                                            }
                                        } else {
                                            return "image/gif";
                                        }
                                    } else {
                                        return "image/jpeg";
                                    }
                                } else {
                                    return "image/png";
                                }
                            } else {
                                return "text/html";
                            }
                        } else {
                            return "text/css";
                        }
                    } else {
                        return "text/xml";
                    }
                } else {
                    return "application/json";
                }
            } else {
                return "application/javascript";
            }
        } else {
            return "application/x-shockwave-flash";
        }
    }

    private static boolean isBinary(String p1)
    {
        if ((!p1.startsWith("image/")) && (!p1.contains("octet-stream"))) {
            int v1_2 = 0;
        } else {
            v1_2 = 1;
        }
        return v1_2;
    }

    private boolean isLatinName(String p6)
    {
        int v6_4 = p6.toLowerCase(java.util.Locale.ROOT);
        String[] v0_6 = v6_4.lastIndexOf(46);
        if (v0_6 > null) {
            v6_4 = v6_4.substring(0, v0_6);
        }
        String vtmp6 = v6_4.replace("_", "").replace("-", "").replace(" ", "");
        String[] v0_4 = com.taomee.mole.MainActivity.LATIN_NAMES;
        int v3 = 0;
        while (v3 < v0_4.length) {
            if (!vtmp6.equals(v0_4[v3])) {
                v3++;
            } else {
                return 1;
            }
        }
        return 0;
    }

    private static boolean isTaomeeHost(String p1)
    {
        int v1_3;
        int v1_1 = p1.toLowerCase(java.util.Locale.ROOT);
        if ((!v1_1.equals("61.com")) && ((!v1_1.endsWith(".61.com")) && ((!v1_1.equals("taomee.com")) && ((!v1_1.endsWith(".taomee.com")) && (!v1_1.endsWith(".51mole.com")))))) {
            v1_3 = 0;
        } else {
            v1_3 = 1;
        }
        return v1_3;
    }

    private void learnMissingProxy(String p5, int p6)
    {
        String v0_2 = new StringBuilder().append(p5).append(":").append(p6).toString();
        String v2_2 = (this.targets.contains(v0_2) ^ 1);
        if (v2_2 != null) {
            this.targets.add(v0_2);
        }
        if (v2_2 != null) {
            android.util.Log.i("MoleShell", new StringBuilder().append("\u8865\u5f55\u670d\u52a1\u5668\u7aef\u53e3\uff1a").append(com.taomee.mole.MainActivity.mask(p5)).append(":").append(p6).append("\uff08\u6e90\u81ea Ruffle \u7684\u7f3a\u5931\u4ee3\u7406\u544a\u8b66\uff09").toString());
            try {
                android.content.SharedPreferences$Editor v5_9 = new StringBuilder();
                android.content.SharedPreferences$Editor v6_3 = this.targets.iterator();
            } catch (android.content.SharedPreferences$Editor v5_12) {
                android.util.Log.w("MoleShell", new StringBuilder().append("\u4fdd\u5b58\u670d\u52a1\u5668\u5217\u8868\u5931\u8d25\uff1a").append(v5_12).toString());
                this.runOnUiThread(new com.taomee.mole.MainActivity$7(this));
                return;
            }
            while (v6_3.hasNext()) {
                String v0_10 = ((String) v6_3.next());
                if (v5_9.length() > 0) {
                    v5_9.append(44);
                }
                v5_9.append(v0_10);
            }
            this.getSharedPreferences("mole_shell", 0).edit().putString("socket_targets_v2", v5_9.toString()).apply();
            this.runOnUiThread(new com.taomee.mole.MainActivity$7(this));
            return;
        } else {
            return;
        }
    }

    private void loadTargets()
    {
        this.targets.clear();
        String[] v0_2 = com.taomee.mole.MainActivity.SEED_HOSTS_ENC;
        int v1_4 = v0_2.length;
        int v2_1 = 0;
        String v3_3 = 0;
        while (v3_3 < v1_4) {
            java.util.LinkedHashSet v4_5 = com.taomee.mole.MainActivity.unmaskStr(v0_2[v3_3]);
            int[] v5 = com.taomee.mole.MainActivity.SEED_PORTS;
            int v6 = v5.length;
            int v7 = 0;
            while (v7 < v6) {
                this.targets.add(new StringBuilder().append(v4_5).append(":").append(v5[v7]).toString());
                v7++;
            }
            v3_3++;
        }
        try {
            String[] v0_1 = this.getSharedPreferences("mole_shell", 0).getString("socket_targets_v2", "");
        } catch (String[] v0_4) {
            android.util.Log.w("MoleShell", new StringBuilder().append("\u8bfb\u53d6\u5df2\u5b58\u670d\u52a1\u5668\u5217\u8868\u5931\u8d25\uff1a").append(v0_4).toString());
            return;
        }
        if ((v0_1 == null) || (v0_1.isEmpty())) {
            return;
        } else {
            String[] v0_3 = v0_1.split(",");
            int v1_3 = v0_3.length;
            while (v2_1 < v1_3) {
                String v3_2 = v0_3[v2_1].trim();
                if ((!v3_2.isEmpty()) && (v3_2.indexOf(58) > 0)) {
                    this.targets.add(v3_2);
                }
                v2_1++;
            }
            return;
        }
    }

    private void markCleanExit()
    {
        try {
            this.getSharedPreferences("mole_shell", 0).edit().putBoolean("boot_running_v1", 0).apply();
        } catch (Throwable v0) {
        }
        return;
    }

    static String mask(String p3)
    {
        if (p3 != null) {
            String v3_4;
            String v0_2 = p3.indexOf(46);
            if (v0_2 <= null) {
                v3_4 = "***";
            } else {
                v3_4 = new StringBuilder().append(p3.substring(0, v0_2)).append(".***.***.***").toString();
            }
            return v3_4;
        } else {
            return "?";
        }
    }

    private int pixelBudget()
    {
        return com.taomee.mole.MainActivity.PIXEL_BUDGETS[Math.min(Math.max(this.loadLevel, 0), com.taomee.mole.MainActivity.MAX_LEVEL)];
    }

    private String preferredRenderer()
    {
        return "wgpu-webgl";
    }

    private void raiseLoadLevel(int p4)
    {
        int v4_3 = Math.min(Math.max(p4, 0), com.taomee.mole.MainActivity.MAX_LEVEL);
        if (v4_3 > this.loadLevel) {
            this.loadLevel = v4_3;
            int v4_1 = this.pixelBudget();
            try {
                this.getSharedPreferences("mole_shell", 0).edit().putInt("boot_crashes_v4", this.loadLevel).apply();
            } catch (com.taomee.mole.MainActivity$3 v0) {
            }
            android.util.Log.w("MoleShell", new StringBuilder().append("\u8d1f\u8f7d\u6863\u4f4d \u2192 ").append(this.loadLevel).append("\uff08\u9884\u7b97 ").append(v4_1).append(" px\uff09").toString());
            this.runOnUiThread(new com.taomee.mole.MainActivity$3(this, v4_1));
            return;
        } else {
            return;
        }
    }

    private static byte[] readAll(java.io.InputStream p4)
    {
        java.io.ByteArrayOutputStream v0_1 = new java.io.ByteArrayOutputStream(65536);
        byte[] v1_2 = new byte[16384];
        while(true) {
            int v2 = p4.read(v1_2);
            if (v2 <= 0) {
                break;
            }
            v0_1.write(v1_2, 0, v2);
        }
        return v0_1.toByteArray();
    }

    private static byte[] readCap(java.io.InputStream p5, int p6)
    {
        java.io.ByteArrayOutputStream v0_1 = new java.io.ByteArrayOutputStream(Math.min(p6, 65536));
        byte[] v2 = new byte[16384];
        while (v0_1.size() < p6) {
            int v3_3 = p5.read(v2, 0, Math.min(16384, (p6 - v0_1.size())));
            if (v3_3 <= 0) {
                break;
            }
            v0_1.write(v2, 0, v3_3);
        }
        return v0_1.toByteArray();
    }

    private void releaseTextures(boolean p10)
    {
        String v0_0 = android.os.SystemClock.elapsedRealtime();
        if (!this.releasing) {
            int v2_4;
            if (p10 == null) {
                v2_4 = 120000;
            } else {
                v2_4 = 15000;
            }
            String v6 = "";
            if ((v0_0 - this.lastReleaseAt) >= v2_4) {
                if ((p10 != null) || (this.releaseCount < 10)) {
                    if (p10 != null) {
                        this.releaseCount = 0;
                    }
                    this.releasing = 1;
                    this.releaseCount = (this.releaseCount + 1);
                    this.lastReleaseAt = v0_0;
                    StringBuilder vtmp12 = new StringBuilder().append("\u7b2c ").append(this.releaseCount).append(" \u6b21\u4e3b\u52a8\u91ca\u653e");
                    if (p10 != null) {
                        v6 = "\uff08panic \u5f3a\u5236\uff09";
                    }
                    android.util.Log.w("MoleShell", vtmp12.append(v6).append("\uff1a\u7a7a\u767d\u9875\u4e2d\u8f6c").toString());
                    this.runOnUiThread(new com.taomee.mole.MainActivity$2(this));
                    return;
                } else {
                    android.util.Log.w("MoleShell", "\u4e3b\u52a8\u91ca\u653e\u5df2\u8fbe 10 \u6b21\u4e0a\u9650");
                    return;
                }
            } else {
                StringBuilder vtmp4 = new StringBuilder().append("\u91ca\u653e\u51b7\u5374\u4e2d\uff08\u8ddd\u4e0a\u6b21 ").append(((v0_0 - this.lastReleaseAt) / 1000)).append("s");
                if (p10 != null) {
                    v6 = "\uff0cpanic \u9632\u6296";
                }
                android.util.Log.i("MoleShell", vtmp4.append(v6).append("\uff09\uff0c\u8df3\u8fc7").toString());
                return;
            }
        } else {
            return;
        }
    }

    private void resolveFonts()
    {
        if (!this.fontsResolved) {
            this.fontsResolved = 1;
            this.cjkFontPath = com.taomee.mole.MainActivity.firstExisting(com.taomee.mole.MainActivity.CJK_FONT_CANDIDATES);
            this.latinFontPath = com.taomee.mole.MainActivity.firstExisting(com.taomee.mole.MainActivity.LATIN_FONT_CANDIDATES);
            android.util.Log.i("MoleShell", new StringBuilder().append("CJK \u5b57\u4f53 = ").append(this.cjkFontPath).append(" / \u62c9\u4e01\u5b57\u4f53 = ").append(this.latinFontPath).toString());
            if (this.cjkFontPath == null) {
                android.util.Log.e("MoleShell", "\u8bbe\u5907\u4e0a\u6ca1\u627e\u5230\u4efb\u4f55 CJK \u5b57\u4f53 \u2014\u2014 \u4e2d\u6587\u4f1a\u7f3a\u5931\uff0c\u9700\u8981\u6539\u4e3a\u968f\u5305\u5185\u7f6e\u5b57\u4f53");
            }
            return;
        } else {
            return;
        }
    }

    private static String safeReason(java.net.HttpURLConnection p1)
    {
        Throwable v0 = "OK";
        try {
            Throwable v1_1 = p1.getResponseMessage();
        } catch (Throwable v1) {
            return "OK";
        }
        if (v1_1 != null) {
            v0 = v1_1;
        }
        return v0;
    }

    private android.webkit.WebResourceResponse shellResponse()
    {
        try {
            android.webkit.WebResourceResponse v2_10 = this.getAssets().open("ruffle/shell.html");
            android.webkit.WebResourceResponse v3_18 = com.taomee.mole.MainActivity.readAll(v2_10);
            v2_10.close();
            android.webkit.WebResourceResponse v2_1 = new String(v3_18, java.nio.charset.StandardCharsets.UTF_8);
            android.webkit.WebResourceResponse v3_3 = new StringBuilder("[");
            int v4_1 = 0;
        } catch (byte[] v0_2) {
            android.util.Log.e("MoleShell", "\u58f3\u9875\u4e0b\u53d1\u5931\u8d25", v0_2);
            return 0;
        }
        while (v4_1 < com.taomee.mole.MainActivity.FONT_SOURCES.length) {
            if (v4_1 > 0) {
                v3_3.append(44);
            }
            v3_3.append(39).append(com.taomee.mole.MainActivity.FONT_SOURCES[v4_1]).append(39);
            v4_1++;
        }
        v3_3.append(93);
        byte[] v0_6 = v2_1.replace("__FONT_SOURCES__", v3_3.toString()).replace("__SOCKET_PROXY__", this.socketProxyJs()).replace("__PIXEL_BUDGET__", String.valueOf(this.pixelBudget())).replace("__RENDERER__", new StringBuilder().append("\'").append(this.preferredRenderer()).append("\'").toString());
        android.util.Log.i("MoleShell", new StringBuilder().append("\u4e0b\u53d1\u7a7a\u58f3\u9875\uff08\u5b57\u4f53\u6e90 ").append(com.taomee.mole.MainActivity.FONT_SOURCES.length).append(" \u4e2a\uff0csocketProxy ").append(this.targets.size()).append(" \u6761\uff0c\u6e32\u67d3\u9884\u7b97 ").append(this.pixelBudget()).append(" px\uff0c\u540e\u7aef ").append(this.preferredRenderer()).append("\uff09").toString());
        java.util.HashMap v8_1 = new java.util.HashMap();
        v8_1.put("Cache-Control", "no-store");
        android.webkit.WebResourceResponse v2_21 = new android.webkit.WebResourceResponse;
        v2_21("text/html", "UTF-8", 200, "OK", v8_1, new java.io.ByteArrayInputStream(v0_6.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        return v2_21;
    }

    private String socketProxyJs()
    {
        String v0_5;
        if (this.bridge != null) {
            v0_5 = this.bridge.getPort();
        } else {
            v0_5 = 0;
        }
        StringBuilder v2_1 = new StringBuilder("[");
        if (v0_5 > null) {
            java.util.Iterator v3_1 = this.targets.iterator();
            int v4_0 = 1;
            while (v3_1.hasNext()) {
                String v5_2 = ((String) v3_1.next());
                String v6_1 = v5_2.lastIndexOf(58);
                if (v6_1 > null) {
                    String v7 = v5_2.substring(0, v6_1);
                    String v5_3 = v5_2.substring((v6_1 + 1));
                    if (v4_0 == 0) {
                        v2_1.append(44);
                    }
                    v2_1.append("{host:\'").append(v7).append("\',port:").append(v5_3).append(",proxyUrl:\'ws://127.0.0.1:").append(v0_5).append("/?host=").append(v7).append("&port=").append(v5_3).append("\'}");
                    v4_0 = 0;
                }
            }
        }
        return v2_1.append(93).toString();
    }

    private void startGpuWatch()
    {
        try {
            this.gpuThread = new android.os.HandlerThread("mole-gpu-watch");
            this.gpuThread.start();
            this.gpuHandler = new android.os.Handler(this.gpuThread.getLooper());
            this.gpuWatchOn = 1;
            this.gpuHandler.postDelayed(this.gpuWatch, 8000);
        } catch (String v0_4) {
            android.util.Log.w("MoleShell", new StringBuilder().append("GPU \u770b\u62a4\u542f\u52a8\u5931\u8d25\uff08\u4e0d\u5f71\u54cd\u6e38\u620f\uff09\uff1a").append(v0_4).toString());
        }
        return;
    }

    private void stopGpuWatch()
    {
        this.gpuWatchOn = 0;
        try {
            if (this.gpuThread != null) {
                this.gpuThread.quitSafely();
            }
        } catch (int v0) {
        }
        this.gpuThread = 0;
        this.gpuHandler = 0;
        return;
    }

    private static String unmaskStr(String p4)
    {
        int v0 = 0;
        String v4_1 = android.util.Base64.decode(p4, 0);
        StringBuilder v1_1 = new StringBuilder(v4_1.length);
        int v2_1 = v4_1.length;
        while (v0 < v2_1) {
            v1_1.append(((char) ((v4_1[v0] & 255) ^ 90)));
            v0++;
        }
        return v1_1.toString();
    }

    private android.webkit.WebResourceResponse upstream(android.webkit.WebResourceRequest p22)
    {
        String v4 = p22.getUrl().toString();
        try {
            android.webkit.WebResourceResponse v0_22;
            android.webkit.WebResourceResponse v0_0 = p22.getRequestHeaders();
        } catch (android.webkit.WebResourceResponse v0) {
            v0_22 = 0;
        }
        if (v0_0 != null) {
            android.webkit.WebResourceResponse v0_13 = v0_0.keySet().iterator();
            while (v0_13.hasNext()) {
                java.io.SequenceInputStream v7_6 = ((String) v0_13.next());
                if ((v7_6 != null) && (v7_6.equalsIgnoreCase("range"))) {
                    v0_22 = 1;
                    if ((v0_22 != null) || ((!com.taomee.mole.HttpCache.cacheable(v4)) || (this.cache == null))) {
                        java.io.SequenceInputStream v7_12 = 0;
                    } else {
                        v7_12 = 1;
                    }
                    if (v7_12 != null) {
                        android.webkit.WebResourceResponse v0_61 = this.cache.hit(v4);
                        if (v0_61 != null) {
                            try {
                                int v15_11 = com.taomee.mole.MainActivity.corsHeaders();
                                v15_11.put("Cache-Control", "public, max-age=604800");
                                java.util.Map v18_3 = new android.webkit.WebResourceResponse;
                                v18_3(com.taomee.mole.MainActivity.guessMime(v4), 0, 200, "OK", v15_11, new java.io.FileInputStream(v0_61));
                                return v18_3;
                            } catch (android.webkit.WebResourceResponse v0_64) {
                                android.util.Log.w("MoleShell", new StringBuilder().append("\u7f13\u5b58\u547d\u4e2d\u4f46\u8bfb\u53d6\u5931\u8d25\uff0c\u8f6c\u56de\u7f51\u7edc\uff1a").append(v0_64).toString());
                            }
                        }
                    }
                    try {
                        int v12_0 = ((java.net.HttpURLConnection) new java.net.URL(v4).openConnection());
                        try {
                            v12_0.setRequestMethod("GET");
                            v12_0.setConnectTimeout(15000);
                            v12_0.setReadTimeout(25000);
                            v12_0.setInstanceFollowRedirects(1);
                            v12_0.setRequestProperty("User-Agent", this.ua);
                            v12_0.setRequestProperty("Referer", new StringBuilder().append("http://").append(p22.getUrl().getHost()).append("/").toString());
                            v12_0.setRequestProperty("Accept", "*/*");
                            v12_0.setRequestProperty("Accept-Encoding", "identity");
                            android.webkit.WebResourceResponse v0_3 = p22.getRequestHeaders();
                            try {
                                if (v0_3 != null) {
                                    java.io.ByteArrayInputStream v5_7 = v0_3.entrySet().iterator();
                                    while (v5_7.hasNext()) {
                                        android.webkit.WebResourceResponse v0_51 = ((java.util.Map$Entry) v5_7.next());
                                        android.webkit.WebResourceResponse v13_9 = ((String) v0_51.getKey());
                                        if (v13_9 != null) {
                                            boolean v14_2 = v13_9.toLowerCase(java.util.Locale.ROOT);
                                            if ((v14_2.equals("accept")) || ((v14_2.equals("accept-language")) || ((v14_2.equals("x-requested-with")) || (v14_2.equals("range"))))) {
                                                try {
                                                    v12_0.setRequestProperty(v13_9, ((String) v0_51.getValue()));
                                                } catch (android.webkit.WebResourceResponse v0) {
                                                }
                                            }
                                        } else {
                                        }
                                    }
                                }
                            } catch (android.webkit.WebResourceResponse v0_47) {
                                android.util.Log.w("MoleShell", new StringBuilder().append("\u4ee3\u53d6\u5931\u8d25\uff0c\u4ea4\u56de WebView \u539f\u751f\u5904\u7406\uff1a").append(v4).append(" (").append(v0_47).append(")").toString());
                                if (v12_0 != 0) {
                                    try {
                                        v12_0.disconnect();
                                    } catch (android.webkit.WebResourceResponse v0) {
                                    }
                                }
                                return 0;
                            }
                            try {
                                android.webkit.WebResourceResponse v0_7 = android.webkit.CookieManager.getInstance().getCookie(v4);
                            } catch (android.webkit.WebResourceResponse v0) {
                                v0_7 = 0;
                            }
                            if ((v0_7 != null) && (!v0_7.isEmpty())) {
                                v12_0.setRequestProperty("Cookie", v0_7);
                            }
                            boolean v14_0;
                            String v3_2 = v12_0.getResponseCode();
                            android.webkit.WebResourceResponse v0_9 = com.taomee.mole.MainActivity.guessMime(v4);
                            java.io.ByteArrayInputStream v5_8 = v12_0.getContentType();
                            if ((v5_8 == null) || (v5_8.isEmpty())) {
                                v14_0 = v0_9;
                            } else {
                                v14_0 = v5_8.split(";")[0].trim();
                            }
                            android.webkit.WebResourceResponse v0_15 = v12_0.getHeaderFields();
                            java.io.ByteArrayInputStream v5_11 = ((java.util.List) v0_15.get("Set-Cookie"));
                            if (v5_11 == null) {
                                v5_11 = ((java.util.List) v0_15.get("set-cookie"));
                            }
                            if (v5_11 != null) {
                                java.io.ByteArrayInputStream v5_14 = v5_11.iterator();
                                while (v5_14.hasNext()) {
                                    try {
                                        android.webkit.CookieManager.getInstance().setCookie(v4, ((String) v5_14.next()));
                                    } catch (android.webkit.WebResourceResponse v0) {
                                    }
                                }
                            }
                            android.webkit.WebResourceResponse v0_19;
                            if (v3_2 < 400) {
                                v0_19 = v12_0.getInputStream();
                            } else {
                                v0_19 = v12_0.getErrorStream();
                            }
                            java.io.ByteArrayInputStream v5_15 = v0_19;
                            if (v5_15 != null) {
                                java.util.Map v6_0 = com.taomee.mole.MainActivity.corsHeaders();
                                try {
                                    int v20 = v12_0;
                                    long v11_0 = ((long) v12_0.getContentLength());
                                    try {
                                        if ((v7_12 == null) || ((v3_2 != 200) || ((v11_0 >= 0) && (v11_0 > 6291456)))) {
                                            v6_0.put("Cache-Control", "no-store");
                                            if ((v3_2 >= 200) && ((v3_2 < 300) && (!com.taomee.mole.MainActivity.isBinary(v14_0)))) {
                                                android.util.Log.i("MoleShell", new StringBuilder().append("\u4ee3\u53d6 ").append(v3_2).append(" ").append(v14_0).append(" ").append(v4).toString());
                                            }
                                            android.webkit.WebResourceResponse v0_34 = new android.webkit.WebResourceResponse;
                                            v0_34(v14_0, 0, v3_2, com.taomee.mole.MainActivity.safeReason(v20), v6_0, v5_15);
                                            return v0_34;
                                        } else {
                                            byte[] v2_1 = com.taomee.mole.MainActivity.readCap(v5_15, 6291456);
                                            if ((v2_1.length <= 0) || (v2_1.length >= 6291456)) {
                                                v6_0.put("Cache-Control", "public, max-age=604800");
                                                android.webkit.WebResourceResponse v0_36 = new android.webkit.WebResourceResponse;
                                                v0_36(v14_0, 0, v3_2, com.taomee.mole.MainActivity.safeReason(v20), v6_0, new java.io.SequenceInputStream(new java.io.ByteArrayInputStream(v2_1), v5_15));
                                                return v0_36;
                                            } else {
                                                try {
                                                    v5_15.close();
                                                } catch (android.webkit.WebResourceResponse v0) {
                                                }
                                                this.cache.store(v4, v2_1);
                                                v6_0.put("Cache-Control", "public, max-age=604800");
                                                if (!com.taomee.mole.MainActivity.isBinary(v14_0)) {
                                                    android.util.Log.i("MoleShell", new StringBuilder().append("\u4ee3\u53d6\u5e76\u7f13\u5b58 ").append(v2_1.length).append("B ").append(com.taomee.mole.MainActivity.basename(v4)).toString());
                                                }
                                                android.webkit.WebResourceResponse v0_46 = new android.webkit.WebResourceResponse;
                                                v0_46(v14_0, 0, v3_2, com.taomee.mole.MainActivity.safeReason(v20), v6_0, new java.io.ByteArrayInputStream(v2_1));
                                                return v0_46;
                                            }
                                        }
                                    } catch (android.webkit.WebResourceResponse v0_47) {
                                        v12_0 = v20;
                                    }
                                } catch (android.webkit.WebResourceResponse v0) {
                                    v20 = v12_0;
                                    v11_0 = -1;
                                }
                            } else {
                                return 0;
                            }
                        } catch (android.webkit.WebResourceResponse v0_47) {
                        }
                    } catch (android.webkit.WebResourceResponse v0_47) {
                        v12_0 = 0;
                    }
                }
            }
        }
        v0_22 = 0;
    }

    private android.webkit.WebResourceResponse wasmResponse(String p10)
    {
        try {
            java.util.zip.GZIPInputStream v7_1 = new java.util.zip.GZIPInputStream(this.getAssets().open(new StringBuilder().append("ruffle/").append(p10).append(".gz").toString()));
            java.util.HashMap v6_1 = new java.util.HashMap();
            v6_1.put("Access-Control-Allow-Origin", "*");
            v6_1.put("Cache-Control", "no-store");
            android.util.Log.i("MoleShell", new StringBuilder().append("\u4e0b\u53d1 wasm\uff1a").append(p10).toString());
            android.webkit.WebResourceResponse v8 = new android.webkit.WebResourceResponse;
            v8("application/wasm", 0, 200, "OK", v6_1, v7_1);
            return v8;
        } catch (Throwable v1_10) {
            android.util.Log.e("MoleShell", new StringBuilder().append("wasm \u4e0b\u53d1\u5931\u8d25\uff1a").append(p10).append(" \u2014\u2014 Ruffle \u8bf7\u6c42\u7684 wasm \u540d\u4e0e assets \u4e0d\u5339\u914d").toString(), v1_10);
            return 0;
        }
    }

    public void onBackPressed()
    {
        if ((this.web == null) || (!this.web.canGoBack())) {
            super.onBackPressed();
        } else {
            this.web.goBack();
        }
        return;
    }

    public void onConfigurationChanged(android.content.res.Configuration p4)
    {
        super.onConfigurationChanged(p4);
        this.goImmersive();
        if (this.web != null) {
            this.web.evaluateJavascript("(function(){try{window.dispatchEvent(new Event(\'resize\'));}catch(e){}})();", 0);
        }
        android.util.Log.i("MoleShell", new StringBuilder().append("\u7a97\u53e3\u53d8\u5316 \u2192 ").append(p4.screenWidthDp).append("x").append(p4.screenHeightDp).append("dp / orientation=").append(p4.orientation).toString());
        return;
    }

    protected void onCreate(android.os.Bundle p5)
    {
        String v0_1;
        super.onCreate(p5);
        this.getWindow().addFlags(128);
        android.webkit.WebView v5_24 = this.getResources().getConfiguration().smallestScreenWidthDp;
        if (v5_24 < 600) {
            v0_1 = 0;
        } else {
            v0_1 = 1;
        }
        android.widget.FrameLayout$LayoutParams v2_0;
        if (v0_1 == null) {
            v2_0 = 6;
        } else {
            v2_0 = 10;
        }
        String v0_3;
        this.setRequestedOrientation(v2_0);
        StringBuilder vtmp6 = new StringBuilder().append("\u5c4f\u5e55\uff1asmallestWidthDp=").append(v5_24).append(" \u2192 ");
        if (v0_1 == null) {
            v0_3 = "\u9501\u5b9a\u6a2a\u5c4f\uff08\u624b\u673a\uff09";
        } else {
            v0_3 = "\u8ddf\u968f\u4f20\u611f\u5668\uff08\u5e73\u677f/\u684c\u9762\uff09";
        }
        android.util.Log.i("MoleShell", vtmp6.append(v0_3).toString());
        this.bridge = new com.taomee.mole.SocketBridge();
        this.bridge.start();
        try {
            this.cache = new com.taomee.mole.HttpCache(this.getCacheDir());
        } catch (android.webkit.WebView v5_11) {
            android.util.Log.w("MoleShell", new StringBuilder().append("\u78c1\u76d8\u7f13\u5b58\u521d\u59cb\u5316\u5931\u8d25\uff0c\u9000\u5316\u4e3a\u76f4\u8fde\uff1a").append(v5_11).toString());
        }
        this.loadTargets();
        android.util.Log.i("MoleShell", new StringBuilder().append("socketProxy \u76ee\u6807\u5df2\u5c31\u7eea\uff0c\u5171 ").append(this.targets.size()).append(" \u6761").toString());
        this.evaluateLoadLevel();
        this.startGpuWatch();
        android.webkit.WebView v5_22 = new android.widget.FrameLayout(this);
        v5_22.setBackgroundColor(-16777216);
        this.web = new android.webkit.WebView(this);
        v5_22.addView(this.web, new android.widget.FrameLayout$LayoutParams(-1, -1));
        this.setContentView(v5_22);
        try {
            android.webkit.WebView.setWebContentsDebuggingEnabled(1);
        } catch (android.webkit.WebView v5) {
        }
        this.configure();
        this.web.loadUrl("http://mole.61.com/__mole_shell__");
        return;
    }

    protected void onDestroy()
    {
        this.gpuWatchOn = 0;
        this.stopGpuWatch();
        this.markCleanExit();
        if (this.bridge != null) {
            this.bridge.stop();
        }
        if (this.web != null) {
            android.webkit.WebView v0_3 = ((android.view.ViewGroup) this.web.getParent());
            if (v0_3 != null) {
                v0_3.removeView(this.web);
            }
            this.web.loadUrl("about:blank");
            this.web.destroy();
        }
        super.onDestroy();
        return;
    }

    protected void onPause()
    {
        super.onPause();
        this.web.evaluateJavascript("(function(){try{var n=document.querySelectorAll(\'ruffle-player,ruffle-object,ruffle-embed\');for(var i=0;i<n.length;i++){try{n[i].pause&&n[i].pause();}catch(e){}}window.dispatchEvent(new Event(\'blur\'));}catch(e){}})();", 0);
        this.web.onPause();
        this.web.pauseTimers();
        return;
    }

    protected void onResume()
    {
        super.onResume();
        this.web.onResume();
        this.web.resumeTimers();
        this.goImmersive();
        return;
    }

    public void onTrimMemory(int p3)
    {
        super.onTrimMemory(p3);
        android.util.Log.w("MoleShell", new StringBuilder().append("onTrimMemory(").append(p3).append(") \u8d1f\u8f7d\u6863=").append(this.loadLevel).toString());
        if ((p3 >= 80) && (this.web != null)) {
            try {
                this.web.clearCache(0);
                android.util.Log.w("MoleShell", "\u5df2\u91ca\u653e WebView HTTP \u7f13\u5b58\uff08\u8f6c\u540e\u53f0\uff09");
            } catch (Throwable v3) {
            }
        }
        return;
    }
}
