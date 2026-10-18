package com.taomee.mole;
final class CrashProbe {

    private CrashProbe()
    {
        return;
    }

    static int recentCrashStreak(android.content.Context p6)
    {
        try {
            java.util.Iterator v1_4 = ((android.app.ActivityManager) p6.getSystemService("activity"));
        } catch (String v6) {
            return -1;
        }
        if (v1_4 != null) {
            int v4 = 0;
            java.util.Iterator v1_1 = v1_4.getHistoricalProcessExitReasons(p6.getPackageName(), 0, 16);
            if (v1_1 != null) {
                String v6_1 = p6.getPackageName();
                java.util.Iterator v1_2 = v1_1.iterator();
                while (v1_2.hasNext()) {
                    int v2_2 = ((android.app.ApplicationExitInfo) v1_2.next());
                    if (v6_1.equals(v2_2.getProcessName())) {
                        int v2_3 = v2_2.getReason();
                        if ((v2_3 != 5) && ((v2_3 != 4) && (v2_3 != 6))) {
                            break;
                        }
                        v4++;
                        if (v4 >= 4) {
                            break;
                        }
                    } else {
                    }
                }
                return v4;
            } else {
                return -1;
            }
        } else {
            return -1;
        }
    }
}
