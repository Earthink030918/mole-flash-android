package com.taomee.mole;
final class HttpCache {
    private static final long MAX_TOTAL = 209715200;
    static final int SAFE_MEM = 6291456;
    private static final String[] STATIC_EXT = None;
    private static final String TAG = "MoleCache";
    private final java.io.File dir;
    private final java.util.concurrent.ConcurrentHashMap locks;

    static HttpCache()
    {
        String v2 = "js";
        String v4 = "txt";
        String v6 = "png";
        String v8 = "jpeg";
        String v10 = "webp";
        String v12 = "mp3";
        String v14 = "ogg";
        String v16 = "bin";
        com.taomee.mole.HttpCache.STATIC_EXT = new String[] {"swf", "ini"});
        return;
    }

    HttpCache(java.io.File p4)
    {
        this.locks = new java.util.concurrent.ConcurrentHashMap();
        this.dir = new java.io.File(p4, "upstream");
        try {
            if ((!this.dir.isDirectory()) && (!this.dir.mkdirs())) {
                android.util.Log.w("MoleCache", new StringBuilder().append("\u7f13\u5b58\u76ee\u5f55\u521b\u5efa\u5931\u8d25\uff1a").append(this.dir).toString());
            }
        } catch (String v4_9) {
            android.util.Log.w("MoleCache", new StringBuilder().append("\u7f13\u5b58\u76ee\u5f55\u5f02\u5e38\uff1a").append(v4_9).toString());
        }
        String v4_13 = new Thread(new com.taomee.mole.HttpCache$1(this), "mole-cache-trim");
        v4_13.setDaemon(1);
        v4_13.start();
        return;
    }

    static synthetic void access$000(com.taomee.mole.HttpCache p0)
    {
        p0.trim();
        return;
    }

    static boolean cacheable(String p6)
    {
        if (p6 != null) {
            String v6_1 = p6.toLowerCase(java.util.Locale.ROOT);
            if (!v6_1.contains("newmisc.taomee.com")) {
                int v1_1 = v6_1.indexOf(63);
                if (v1_1 >= 0) {
                    v6_1 = v6_1.substring(0, v1_1);
                }
                int v1_3 = v6_1.indexOf(35);
                if (v1_3 >= 0) {
                    v6_1 = v6_1.substring(0, v1_3);
                }
                int v1_6 = v6_1.lastIndexOf(47);
                String[] v2_1 = v6_1.lastIndexOf(46);
                if ((v2_1 >= null) && (v2_1 >= v1_6)) {
                    String vtmp9 = v6_1.substring((v2_1 + 1));
                    String[] v2_3 = com.taomee.mole.HttpCache.STATIC_EXT;
                    int v4 = 0;
                    while (v4 < v2_3.length) {
                        if (!v2_3[v4].equals(vtmp9)) {
                            v4++;
                        } else {
                            return 1;
                        }
                    }
                    return 0;
                } else {
                    return 0;
                }
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }

    private java.io.File fileFor(String p3)
    {
        return new java.io.File(this.dir, com.taomee.mole.HttpCache.key(p3));
    }

    static String key(String p7)
    {
        try {
            Throwable v0_2 = java.security.MessageDigest.getInstance("SHA-1").digest(p7.getBytes("UTF-8"));
            StringBuilder v1_0 = new StringBuilder(40);
            int v2_0 = v0_2.length;
            int v3 = 0;
        } catch (Throwable v0) {
            return Integer.toHexString(p7.hashCode());
        }
        while (v3 < v2_0) {
            char v4_1 = (v0_2[v3] & 255);
            v1_0.append(Character.forDigit((v4_1 >> 4), 16));
            v1_0.append(Character.forDigit((v4_1 & 15), 16));
            v3++;
        }
        return v1_0.toString();
    }

    private Object lockFor(String p3)
    {
        Object v3_1 = com.taomee.mole.HttpCache.key(p3);
        Object v0_2 = this.locks.get(v3_1);
        if (v0_2 == null) {
            Object v0_0 = new Object();
            Object v3_2 = this.locks.putIfAbsent(v3_1, v0_0);
            if (v3_2 != null) {
                v0_0 = v3_2;
            }
            return v0_0;
        } else {
            return v0_2;
        }
    }

    private void trim()
    {
        try {
            String v1_3 = this.dir.listFiles();
        } catch (String v1_20) {
            android.util.Log.w("MoleCache", new StringBuilder().append("\u7f13\u5b58\u6574\u7406\u5f02\u5e38\uff1a").append(v1_20).toString());
            return;
        }
        if (v1_3 != null) {
            if (v1_3.length != 0) {
                String v2_3 = v1_3.length;
                int v3_0 = 0;
                int v4_0 = 0;
                int v6_0 = 0;
                int v7_0 = 0;
                while (v6_0 < v2_3) {
                    long v8_2 = v1_3[v6_0];
                    if (v8_2.isFile()) {
                        if (!v8_2.getName().endsWith(".tmp")) {
                            v4_0 += v8_2.length();
                            v7_0++;
                        } else {
                            v8_2.delete();
                        }
                    } else {
                    }
                    v6_0++;
                }
                if (v4_0 > 209715200) {
                    java.util.Arrays.sort(v1_3, new com.taomee.mole.HttpCache$2(this));
                    int v7_3 = v1_3.length;
                    long v8_1 = v4_0;
                    int v4_1 = 0;
                    while (v3_0 < v7_3) {
                        boolean v5_0 = v1_3[v3_0];
                        if (v8_1 > 167772160) {
                            if (v5_0.isFile()) {
                                long v10_3 = v5_0.length();
                                if (v5_0.delete()) {
                                    v8_1 -= v10_3;
                                    v4_1++;
                                }
                            } else {
                            }
                            v3_0++;
                        } else {
                            break;
                        }
                    }
                    android.util.Log.i("MoleCache", new StringBuilder().append("\u7f13\u5b58\u8d85\u9650\uff1a\u6dd8\u6c70 ").append(v4_1).append(" \u9879\uff0c\u73b0 ").append((v8_1 >> 20)).append(" MB").toString());
                    return;
                } else {
                    android.util.Log.i("MoleCache", new StringBuilder().append("\u7f13\u5b58\u5df2\u6709 ").append(v7_0).append(" \u9879 / ").append((v4_0 >> 20)).append(" MB").toString());
                    return;
                }
            } else {
            }
        }
        return;
    }

    java.io.File hit(String p6)
    {
        try {
            int v6_1 = this.fileFor(p6);
        } catch (int v6_5) {
            android.util.Log.w("MoleCache", new StringBuilder().append("\u7f13\u5b58\u67e5\u8be2\u5f02\u5e38\uff1a").append(v6_5).toString());
            return 0;
        }
        if ((!v6_1.isFile()) || (v6_1.length() <= 0)) {
            return 0;
        } else {
            try {
                v6_1.setLastModified(System.currentTimeMillis());
            } catch (Throwable v0) {
            }
            return v6_1;
        }
    }

    void store(String p6, byte[] p7)
    {
        if ((p7 != null) && ((p7.length != 0) && (p7.length <= 6291456))) {
            String v0_3 = this.fileFor(p6);
            this.lockFor(p6);
            try {
                java.io.File v1_1 = new java.io.File(new StringBuilder().append(v0_3.getPath()).append(".tmp").toString());
                StringBuilder v2_5 = 0;
                try {
                    StringBuilder v3_3 = new java.io.FileOutputStream(v1_1);
                    try {
                        v3_3.write(p7);
                        v3_3.flush();
                        v3_3.close();
                    } catch (Throwable v7_1) {
                        v2_5 = v3_3;
                        android.util.Log.w("MoleCache", new StringBuilder().append("\u7f13\u5b58\u5199\u5165\u5931\u8d25\uff1a").append(v7_1).toString());
                        if (v2_5 == null) {
                        } else {
                            try {
                                v2_5.close();
                            } catch (Throwable v7) {
                            }
                        }
                        v1_1.delete();
                        return;
                    }
                    if (v1_1.renameTo(v0_3)) {
                        return;
                    } else {
                        v0_3.delete();
                        if (v1_1.renameTo(v0_3)) {
                            return;
                        } else {
                            v1_1.delete();
                            return;
                        }
                    }
                } catch (Throwable v7_1) {
                }
            } catch (Throwable v7_6) {
                throw v7_6;
            }
        } else {
            return;
        }
    }
}
