package com.taomee.mole;
 class MainActivity$JsBridge {
    final synthetic com.taomee.mole.MainActivity this$0;

    private MainActivity$JsBridge(com.taomee.mole.MainActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    synthetic MainActivity$JsBridge(com.taomee.mole.MainActivity p1, com.taomee.mole.MainActivity$1 p2)
    {
        this(p1);
        return;
    }

    public int bridgePort()
    {
        int v0_4;
        if (com.taomee.mole.MainActivity.access$2100(this.this$0) != null) {
            v0_4 = com.taomee.mole.MainActivity.access$2100(this.this$0).getPort();
        } else {
            v0_4 = 0;
        }
        return v0_4;
    }

    public void log(String p3)
    {
        android.util.Log.i("MoleShell", new StringBuilder().append("[js] ").append(p3).toString());
        return;
    }

    public void onGpuExhausted(String p4)
    {
        com.taomee.mole.MainActivity$JsBridge$3 v1_0;
        boolean v0_1 = "dead".equals(p4);
        com.taomee.mole.MainActivity v4_4 = new StringBuilder().append("\u9875\u9762\u62a5\u544a GPU \u4e0a\u4e0b\u6587\u5f02\u5e38\uff1a").append(p4);
        if (!v0_1) {
            v1_0 = "\uff08\u5148\u964d\u4e00\u6863\u89c2\u5bdf\uff09";
        } else {
            v1_0 = "\uff082.5s \u672a\u6062\u590d \u2192 \u91cd\u8f7d\uff09";
        }
        android.util.Log.w("MoleShell", v4_4.append(v1_0).toString());
        this.this$0.runOnUiThread(new com.taomee.mole.MainActivity$JsBridge$3(this, v0_1));
        return;
    }

    public void onMissingProxy(String p2, int p3)
    {
        try {
            if ((p2 == null) || ((p2.isEmpty()) || ((p3 <= null) || (p3 > 65535)))) {
            } else {
                com.taomee.mole.MainActivity.access$2200(this.this$0, p2, p3);
            }
        } catch (String v2_3) {
            android.util.Log.w("MoleShell", new StringBuilder().append("\u8865\u5f55\u5931\u8d25\uff1a").append(v2_3).toString());
        }
        return;
    }

    public void onPanic()
    {
        android.util.Log.w("MoleShell", "\u9875\u9762\u62a5\u544a Ruffle panic \u2192 \u5f3a\u5236\u6e05\u7a7a\u91cd\u8f7d");
        this.this$0.runOnUiThread(new com.taomee.mole.MainActivity$JsBridge$2(this));
        return;
    }

    public void toast(String p3)
    {
        this.this$0.runOnUiThread(new com.taomee.mole.MainActivity$JsBridge$1(this, p3));
        return;
    }
}
