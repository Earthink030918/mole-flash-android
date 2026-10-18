package com.taomee.mole;
 class SocketBridge$3 implements java.lang.Runnable {
    final synthetic com.taomee.mole.SocketBridge this$0;
    final synthetic java.io.OutputStream val$fOut;
    final synthetic java.io.InputStream val$tcpIn;

    SocketBridge$3(com.taomee.mole.SocketBridge p1, java.io.InputStream p2, java.io.OutputStream p3)
    {
        this.this$0 = p1;
        this.val$tcpIn = p2;
        this.val$fOut = p3;
        return;
    }

    public void run()
    {
        com.taomee.mole.SocketBridge.access$200(this.this$0, this.val$tcpIn, this.val$fOut);
        return;
    }
}
