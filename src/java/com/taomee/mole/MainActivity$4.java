package com.taomee.mole;
 class MainActivity$4 implements java.lang.Runnable {
    final synthetic com.taomee.mole.MainActivity this$0;

    MainActivity$4(com.taomee.mole.MainActivity p1)
    {
        this.this$0 = p1;
        return;
    }

    public void run()
    {
        try {
            this.this$0.getSharedPreferences("mole_shell", 0).edit().putBoolean("boot_running_v1", 0).apply();
        } catch (Throwable v0) {
        }
        return;
    }
}
