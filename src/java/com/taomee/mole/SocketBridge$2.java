package com.taomee.mole;
 class SocketBridge$2 implements java.lang.Runnable {
    final synthetic com.taomee.mole.SocketBridge this$0;
    final synthetic java.io.InputStream val$fIn;
    final synthetic java.io.OutputStream val$tcpOut;

    SocketBridge$2(com.taomee.mole.SocketBridge p1, java.io.InputStream p2, java.io.OutputStream p3)
    {
        this.this$0 = p1;
        this.val$fIn = p2;
        this.val$tcpOut = p3;
        return;
    }

    public void run()
    {
        com.taomee.mole.SocketBridge.access$100(this.this$0, this.val$fIn, this.val$tcpOut);
        return;
    }
}
