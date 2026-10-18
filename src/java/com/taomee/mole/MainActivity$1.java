package com.taomee.mole;
 class MainActivity$1 implements java.lang.Runnable {
    final synthetic com.taomee.mole.MainActivity this$0;

    MainActivity$1(com.taomee.mole.MainActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    public void run()
    {
        if (com.taomee.mole.MainActivity.access$000(this.this$0)) {
            long v1_30 = android.os.SystemClock.elapsedRealtime();
            try {
                int v3_0 = com.taomee.mole.MainActivity.access$100(this.this$0);
            } catch (int v3_1) {
                android.util.Log.w("MoleShell", new StringBuilder().append("GPU \u91c7\u96c6\u5f02\u5e38\uff1a").append(v3_1).toString());
                v3_0 = -1;
            }
            long v4_6 = (android.os.SystemClock.elapsedRealtime() - v1_30);
            if (v3_0 > 0) {
                android.os.Handler v2_16 = 0;
                if (v3_0 < 410) {
                    if ((v3_0 >= 400) && (com.taomee.mole.MainActivity.access$300(this.this$0) < 2)) {
                        android.util.Log.w("MoleShell", new StringBuilder().append("GPU \u663e\u5b58 ").append(v3_0).append(" MB \u8d8a\u8fc7\u8f6f\u95f8 ").append(400).append(" \u2192 \u964d\u4e00\u6863").toString());
                        com.taomee.mole.MainActivity.access$400(this.this$0, (com.taomee.mole.MainActivity.access$300(this.this$0) + 1));
                        v2_16 = 1;
                    }
                } else {
                    android.util.Log.w("MoleShell", new StringBuilder().append("GPU \u663e\u5b58 ").append(v3_0).append(" MB \u8d8a\u8fc7\u91ca\u653e\u95f8 ").append(410).append(" \u2192 \u6e05\u7a7a\u91cd\u8f7d\u5f52\u8fd8\u7eb9\u7406").toString());
                    com.taomee.mole.MainActivity.access$200(this.this$0, 0);
                    v2_16 = 1;
                }
                if ((v2_16 != null) || ((com.taomee.mole.MainActivity.access$508(this.this$0) & 3) == 0)) {
                    android.util.Log.i("MoleShell", new StringBuilder().append("GPU \u663e\u5b58 ").append(v3_0).append(" MB\uff08\u6863 ").append(com.taomee.mole.MainActivity.access$300(this.this$0)).append("\uff0c\u9884\u7b97 ").append(com.taomee.mole.MainActivity.access$600(this.this$0)).append(" px\uff0c\u91c7\u96c6\u8017\u65f6 ").append(v4_6).append("ms\uff09").toString());
                }
            }
            if (v4_6 <= 1500) {
                if ((v4_6 < 200) && (com.taomee.mole.MainActivity.access$700(this.this$0) > 8000)) {
                    com.taomee.mole.MainActivity.access$702(this.this$0, Math.max((com.taomee.mole.MainActivity.access$700(this.this$0) / 2), 8000));
                }
            } else {
                com.taomee.mole.MainActivity.access$702(this.this$0, Math.min((com.taomee.mole.MainActivity.access$700(this.this$0) * 2), 60000));
                android.util.Log.i("MoleShell", new StringBuilder().append("GPU \u91c7\u96c6\u8017\u65f6 ").append(v4_6).append("ms\uff0c\u95f4\u9694\u9000\u907f\u5230 ").append(com.taomee.mole.MainActivity.access$700(this.this$0)).append("ms").toString());
            }
            if ((com.taomee.mole.MainActivity.access$000(this.this$0)) && (com.taomee.mole.MainActivity.access$800(this.this$0) != null)) {
                if ((v3_0 <= 0) || (v3_0 < 350)) {
                    long v0_11 = com.taomee.mole.MainActivity.access$700(this.this$0);
                } else {
                    v0_11 = 3000;
                }
                com.taomee.mole.MainActivity.access$800(this.this$0).postDelayed(this, v0_11);
            }
            return;
        } else {
            return;
        }
    }
}
