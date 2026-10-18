package com.taomee.mole;
 class MainActivity$5 extends android.webkit.WebChromeClient {
    final synthetic com.taomee.mole.MainActivity this$0;

    MainActivity$5(com.taomee.mole.MainActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    public boolean onConsoleMessage(android.webkit.ConsoleMessage p3)
    {
        android.util.Log.i("MoleShell", new StringBuilder().append("[console] ").append(p3.message()).toString());
        return 1;
    }

    public void onProgressChanged(android.webkit.WebView p1, int p2)
    {
        if (p2 >= 100) {
            com.taomee.mole.MainActivity.access$1200(this.this$0);
        }
        return;
    }
}
