package com.taomee.mole;
 class MainActivity$JsBridge$3 implements java.lang.Runnable {
    final synthetic com.taomee.mole.MainActivity$JsBridge this$1;
    final synthetic boolean val$dead;

    MainActivity$JsBridge$3(com.taomee.mole.MainActivity$JsBridge p1, boolean p2)
    {
        this.this$1 = p1;
        this.val$dead = p2;
        return;
    }

    public void run()
    {
        if (com.taomee.mole.MainActivity.access$900(this.this$1.this$0) != null) {
            if (this.val$dead) {
                com.taomee.mole.MainActivity.access$400(this.this$1.this$0, com.taomee.mole.MainActivity.access$2300());
                if (com.taomee.mole.MainActivity.access$2000(this.this$1.this$0) < 8) {
                    com.taomee.mole.MainActivity.access$2008(this.this$1.this$0);
                    android.util.Log.i("MoleShell", new StringBuilder().append("\u56e0 GPU \u4e0a\u4e0b\u6587\u672a\u6062\u590d\u800c\u91cd\u8f7d\uff08\u7b2c ").append(com.taomee.mole.MainActivity.access$2000(this.this$1.this$0)).append(" \u6b21\uff09").toString());
                    com.taomee.mole.MainActivity.access$900(this.this$1.this$0).reload();
                    return;
                } else {
                    android.util.Log.w("MoleShell", "\u81ea\u52a8\u6062\u590d\u5df2\u8fbe\u4e0a\u9650\uff0c\u4fdd\u6301\u5f53\u524d\u753b\u9762\u4e0d\u518d\u91cd\u8f7d");
                    return;
                }
            } else {
                com.taomee.mole.MainActivity.access$400(this.this$1.this$0, (com.taomee.mole.MainActivity.access$300(this.this$1.this$0) + 1));
                return;
            }
        } else {
            return;
        }
    }
}
