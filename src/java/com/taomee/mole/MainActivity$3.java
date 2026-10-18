package com.taomee.mole;
 class MainActivity$3 implements java.lang.Runnable {
    final synthetic com.taomee.mole.MainActivity this$0;
    final synthetic int val$px;

    MainActivity$3(com.taomee.mole.MainActivity p1, int p2)
    {
        this.this$0 = p1;
        this.val$px = p2;
        return;
    }

    public void run()
    {
        if (com.taomee.mole.MainActivity.access$900(this.this$0) != null) {
            try {
                com.taomee.mole.MainActivity.access$900(this.this$0).evaluateJavascript(new StringBuilder().append("(function(){try{window.__moleSetBudget&&window.__moleSetBudget(").append(this.val$px).append(");}catch(e){}})();").toString(), 0);
            } catch (String v0_2) {
                android.util.Log.w("MoleShell", new StringBuilder().append("\u964d\u8f7d\u4e0b\u53d1\u5931\u8d25\uff1a").append(v0_2).toString());
            }
            return;
        } else {
            return;
        }
    }
}
