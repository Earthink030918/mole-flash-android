package com.taomee.mole;
 class MainActivity$2$1 implements java.lang.Runnable {
    final synthetic com.taomee.mole.MainActivity$2 this$1;

    MainActivity$2$1(com.taomee.mole.MainActivity$2 p1)
    {
        this.this$1 = p1;
        return;
    }

    public void run()
    {
        try {
            if (com.taomee.mole.MainActivity.access$900(this.this$1.this$0) != null) {
                com.taomee.mole.MainActivity.access$900(this.this$1.this$0).loadUrl("http://mole.61.com/__mole_shell__");
            }
        } catch (com.taomee.mole.MainActivity v0_2) {
            android.util.Log.w("MoleShell", new StringBuilder().append("\u56de\u5230\u58f3\u9875\u5931\u8d25\uff1a").append(v0_2).toString());
        }
        com.taomee.mole.MainActivity.access$1002(this.this$1.this$0, 0);
        return;
    }
}
