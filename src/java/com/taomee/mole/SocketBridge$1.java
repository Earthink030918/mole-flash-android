package com.taomee.mole;
 class SocketBridge$1 implements java.lang.Runnable {
    final synthetic com.taomee.mole.SocketBridge this$0;
    final synthetic java.util.concurrent.ExecutorService val$ex;
    final synthetic java.net.ServerSocket val$srv;

    SocketBridge$1(com.taomee.mole.SocketBridge p1, java.net.ServerSocket p2, java.util.concurrent.ExecutorService p3)
    {
        this.this$0 = p1;
        this.val$srv = p2;
        this.val$ex = p3;
        return;
    }

    public void run()
    {
        while (!this.val$srv.isClosed()) {
            try {
                this.val$ex.execute(new com.taomee.mole.SocketBridge$1$1(this, this.val$srv.accept()));
            } catch (String v0_1) {
                if (!this.val$srv.isClosed()) {
                    android.util.Log.w("MoleSocketBridge", new StringBuilder().append("accept \u5f02\u5e38\uff1a").append(v0_1.getMessage()).toString());
                }
                break;
            }
        }
        return;
    }
}
