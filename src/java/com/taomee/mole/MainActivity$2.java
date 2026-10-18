package com.taomee.mole;
 class MainActivity$2 implements java.lang.Runnable {
    final synthetic com.taomee.mole.MainActivity this$0;

    MainActivity$2(com.taomee.mole.MainActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    public void run()
    {
        if (com.taomee.mole.MainActivity.access$900(this.this$0) != null) {
            try {
                com.taomee.mole.MainActivity.access$900(this.this$0).loadUrl("about:blank");
                com.taomee.mole.MainActivity v0_2 = new android.os.Handler(this.this$0.getMainLooper());
                com.taomee.mole.MainActivity$2$1 v1_3 = new com.taomee.mole.MainActivity$2$1(this);
                v0_2.postDelayed(v1_3, 2000);
                return;
            } catch (com.taomee.mole.MainActivity v0_4) {
                android.util.Log.w("MoleShell", new StringBuilder().append("\u5bfc\u822a\u7a7a\u767d\u9875\u5931\u8d25\uff1a").append(v0_4).toString());
                com.taomee.mole.MainActivity.access$1002(this.this$0, v1_3);
                return;
            }
        } else {
            com.taomee.mole.MainActivity.access$1002(this.this$0, 0);
            return;
        }
    }
}
