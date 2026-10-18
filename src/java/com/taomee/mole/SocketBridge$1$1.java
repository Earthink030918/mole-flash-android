package com.taomee.mole;
 class SocketBridge$1$1 implements java.lang.Runnable {
    final synthetic com.taomee.mole.SocketBridge$1 this$1;
    final synthetic java.net.Socket val$client;

    SocketBridge$1$1(com.taomee.mole.SocketBridge$1 p1, java.net.Socket p2)
    {
        this.this$1 = p1;
        this.val$client = p2;
        return;
    }

    public void run()
    {
        com.taomee.mole.SocketBridge.access$000(this.this$1.this$0, this.val$client);
        return;
    }
}
