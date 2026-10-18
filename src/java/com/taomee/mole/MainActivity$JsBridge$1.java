package com.taomee.mole;
 class MainActivity$JsBridge$1 implements java.lang.Runnable {
    final synthetic com.taomee.mole.MainActivity$JsBridge this$1;
    final synthetic String val$msg;

    MainActivity$JsBridge$1(com.taomee.mole.MainActivity$JsBridge p1, String p2)
    {
        this.this$1 = p1;
        this.val$msg = p2;
        return;
    }

    public void run()
    {
        android.widget.Toast.makeText(this.this$1.this$0, this.val$msg, 0).show();
        return;
    }
}
