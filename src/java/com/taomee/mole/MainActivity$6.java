package com.taomee.mole;
 class MainActivity$6 extends android.webkit.WebViewClient {
    final synthetic com.taomee.mole.MainActivity this$0;

    MainActivity$6(com.taomee.mole.MainActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    public void onPageFinished(android.webkit.WebView p2, String p3)
    {
        android.util.Log.i("MoleShell", new StringBuilder().append("\u2713 \u9875\u9762\u5c31\u7eea\uff1a").append(p3).toString());
        com.taomee.mole.MainActivity.access$1200(this.this$0);
        return;
    }

    public void onPageStarted(android.webkit.WebView p1, String p2, android.graphics.Bitmap p3)
    {
        android.util.Log.i("MoleShell", new StringBuilder().append("\u2192 ").append(p2).toString());
        return;
    }

    public void onReceivedError(android.webkit.WebView p2, android.webkit.WebResourceRequest p3, android.webkit.WebResourceError p4)
    {
        if ((p3 != null) && (p3.isForMainFrame())) {
            android.util.Log.e("MoleShell", new StringBuilder().append("\u4e3b\u9875\u52a0\u8f7d\u5931\u8d25\uff1a").append(p3.getUrl()).append(" code=").append(p4.getErrorCode()).append(" desc=").append(p4.getDescription()).toString());
        }
        return;
    }

    public android.webkit.WebResourceResponse shouldInterceptRequest(android.webkit.WebView p6, android.webkit.WebResourceRequest p7)
    {
        try {
            boolean v1_11 = p7.getUrl().toString();
            String v2_1 = com.taomee.mole.MainActivity.access$1300(v1_11);
        } catch (android.webkit.WebResourceResponse v6_6) {
            android.util.Log.w("MoleShell", new StringBuilder().append("\u62e6\u622a\u5904\u7406\u5f02\u5e38\uff1a").append(v6_6).toString());
            return 0;
        }
        if (!v1_11.endsWith("/__mole_shell__")) {
            if (!v1_11.contains("/fonts/")) {
                if (!"__mole_ruffle__.js".equals(v2_1)) {
                    if (!"__mole_boot__.js".equals(v2_1)) {
                        if ((!v2_1.startsWith("core.ruffle.")) || (!v2_1.endsWith(".js"))) {
                            if ((!v2_1.startsWith("core.ruffle.")) || (!v2_1.endsWith(".js.map"))) {
                                if (!v2_1.endsWith(".wasm")) {
                                    android.webkit.WebResourceResponse v6_15 = p7.getUrl().getHost();
                                    if (v6_15 != null) {
                                        if ((!"GET".equalsIgnoreCase(p7.getMethod())) || (!com.taomee.mole.MainActivity.access$1800(v6_15))) {
                                            return 0;
                                        } else {
                                            return com.taomee.mole.MainActivity.access$1900(this.this$0, p7);
                                        }
                                    } else {
                                        return 0;
                                    }
                                } else {
                                    return com.taomee.mole.MainActivity.access$1700(this.this$0, v2_1);
                                }
                            } else {
                                return com.taomee.mole.MainActivity.access$1600(this.this$0, new StringBuilder().append("ruffle/").append(v2_1).toString(), "application/json");
                            }
                        } else {
                            return com.taomee.mole.MainActivity.access$1600(this.this$0, new StringBuilder().append("ruffle/").append(v2_1).toString(), "application/javascript");
                        }
                    } else {
                        return com.taomee.mole.MainActivity.access$1600(this.this$0, "ruffle/mole_boot.js", "application/javascript");
                    }
                } else {
                    return com.taomee.mole.MainActivity.access$1600(this.this$0, "ruffle/ruffle.js", "application/javascript");
                }
            } else {
                return com.taomee.mole.MainActivity.access$1500(this.this$0, v2_1);
            }
        } else {
            return com.taomee.mole.MainActivity.access$1400(this.this$0);
        }
    }
}
