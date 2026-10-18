package com.taomee.mole;
 class MainActivity$7 implements java.lang.Runnable {
    final synthetic com.taomee.mole.MainActivity this$0;

    MainActivity$7(com.taomee.mole.MainActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    public void run()
    {
        if (com.taomee.mole.MainActivity.access$900(this.this$0) != null) {
            if (com.taomee.mole.MainActivity.access$2000(this.this$0) < 8) {
                com.taomee.mole.MainActivity.access$2008(this.this$0);
                android.util.Log.i("MoleShell", new StringBuilder().append("\u9759\u9ed8\u70ed\u91cd\u542f\u4ee5\u5e94\u7528\u65b0\u7684 socketProxy\uff08\u7b2c ").append(com.taomee.mole.MainActivity.access$2000(this.this$0)).append(" \u6b21\uff09").toString());
                com.taomee.mole.MainActivity.access$900(this.this$0).reload();
                return;
            } else {
                android.util.Log.w("MoleShell", "\u81ea\u52a8\u70ed\u91cd\u542f\u6b21\u6570\u5df2\u8fbe\u4e0a\u9650\uff0c\u8bf7\u624b\u52a8\u91cd\u542f\u5e94\u7528");
                return;
            }
        } else {
            return;
        }
    }
}
