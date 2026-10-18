package com.taomee.mole;
public class SocketBridge {
    private static final String DEFAULT_HOST = "123.206.131.236";
    private static final int DEFAULT_PORT = 1863;
    private static final boolean ENABLE_BYTE_SNIFF = False;
    private static final int MAX_HEADER = 65536;
    private static final String TAG = "MoleSocketBridge";
    private static final String WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    private volatile com.taomee.mole.SocketBridge$DiscoveryListener listener;
    private java.util.concurrent.ExecutorService pool;
    private volatile int port;
    private volatile java.net.ServerSocket server;

    public SocketBridge()
    {
        this.port = 0;
        return;
    }

    static synthetic void access$000(com.taomee.mole.SocketBridge p0, java.net.Socket p1)
    {
        p0.handle(p1);
        return;
    }

    static synthetic void access$100(com.taomee.mole.SocketBridge p0, java.io.InputStream p1, java.io.OutputStream p2)
    {
        p0.pumpClientToTcp(p1, p2);
        return;
    }

    static synthetic void access$200(com.taomee.mole.SocketBridge p0, java.io.InputStream p1, java.io.OutputStream p2)
    {
        p0.pumpTcpToClient(p1, p2);
        return;
    }

    private static byte[] buildFrame(int p8, byte[] p9, int p10)
    {
        byte[] v0_2;
        if (p10 >= 126) {
            if (p10 >= 65536) {
                v0_2 = new byte[10];
                v0_2[0] = ((byte) (p8 | 128));
                v0_2[1] = 127;
                int v8_3 = 0;
                while (v8_3 < 8) {
                    v0_2[(v8_3 + 2)] = ((byte) ((int) ((((long) p10) >> ((7 - v8_3) * 8)) & 255)));
                    v8_3++;
                }
            } else {
                long v4_4 = new byte[4];
                v4_4[0] = ((byte) (p8 | 128));
                v4_4[1] = 126;
                v4_4[2] = ((byte) ((p10 >> 8) & 255));
                v4_4[3] = ((byte) (p10 & 255));
                v0_2 = v4_4;
            }
        } else {
            v0_2 = new byte[2];
            v0_2[0] = ((byte) (p8 | 128));
            v0_2[1] = ((byte) p10);
        }
        int v8_16 = new byte[(v0_2.length + p10)];
        System.arraycopy(v0_2, 0, v8_16, 0, v0_2.length);
        System.arraycopy(p9, 0, v8_16, v0_2.length, p10);
        return v8_16;
    }

    private static void closeQuietly(java.io.Closeable p0)
    {
        if (p0 == null) {
        } else {
            try {
                p0.close();
            } catch (Throwable v0) {
            }
        }
        return;
    }

    private static String extractHeader(String p6, String p7)
    {
        String v6_1 = p6.split("\r\n");
        int v0_1 = v6_1.length;
        int v2 = 0;
        while (v2 < v0_1) {
            String v3 = v6_1[v2];
            int v4_1 = v3.indexOf(58);
            if ((v4_1 <= 0) || (!v3.substring(0, v4_1).trim().equalsIgnoreCase(p7))) {
                v2++;
            } else {
                return v3.substring((v4_1 + 1)).trim();
            }
        }
        return 0;
    }

    private static String firstLinePath(String p2)
    {
        int v0_2 = p2.indexOf("\r\n");
        if (v0_2 >= 0) {
            p2 = p2.substring(0, v0_2);
        }
        String v2_1;
        String v2_2 = p2.split(" ");
        if (v2_2.length <= 1) {
            v2_1 = "/";
        } else {
            v2_1 = v2_2[1];
        }
        return v2_1;
    }

    private void handle(java.net.Socket p13)
    {
        java.net.Socket v3_4 = 0;
        try {
            p13.setTcpNoDelay(1);
            String v4_3 = p13.getInputStream();
            java.io.OutputStream v5 = p13.getOutputStream();
            String[] v6_0 = com.taomee.mole.SocketBridge.readHttpHead(v4_3);
        } catch (Throwable v0_4) {
            try {
                android.util.Log.w("MoleSocketBridge", new StringBuilder().append("\u6865\u8fde\u63a5\u7ed3\u675f\uff1a").append(v0_4.getMessage()).toString());
                com.taomee.mole.SocketBridge.closeQuietly(v3_4);
            } catch (Throwable v0_8) {
                com.taomee.mole.SocketBridge.closeQuietly(v3_4);
                com.taomee.mole.SocketBridge.closeQuietly(p13);
                throw v0_8;
            }
            com.taomee.mole.SocketBridge.closeQuietly(p13);
            return;
        }
        if (v6_0 != null) {
            java.net.Socket v7_1 = com.taomee.mole.SocketBridge.extractHeader(v6_0, "sec-websocket-key");
            if (v7_1 != null) {
                String[] v6_2 = com.taomee.mole.SocketBridge.parseTarget(com.taomee.mole.SocketBridge.firstLinePath(v6_0));
                v5.write(new StringBuilder().append("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ").append(com.taomee.mole.SocketBridge.sha1Base64(new StringBuilder().append(v7_1).append("258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toString())).append("\r\n\r\n").toString().getBytes(java.nio.charset.StandardCharsets.ISO_8859_1));
                v5.flush();
                java.net.Socket v7_11 = new java.net.Socket();
                try {
                    v7_11.setTcpNoDelay(1);
                    v7_11.connect(new java.net.InetSocketAddress(v6_2[0], Integer.parseInt(v6_2[1])), 12000);
                    android.util.Log.i("MoleSocketBridge", new StringBuilder().append("\u5df2\u63a5\u5165 -> ").append(com.taomee.mole.MainActivity.mask(v6_2[0])).append(":").append(v6_2[1]).toString());
                    java.net.Socket v3_14 = v7_11.getInputStream();
                    com.taomee.mole.SocketBridge$3 v9_7 = v7_11.getOutputStream();
                    Thread v10_3 = new Thread(new com.taomee.mole.SocketBridge$2(this, v4_3, v9_7), "mole-ws-up");
                    String v4_6 = new Thread(new com.taomee.mole.SocketBridge$3(this, v3_14, v5), "mole-ws-down");
                    v10_3.setDaemon(1);
                    v4_6.setDaemon(1);
                    v10_3.start();
                    v4_6.start();
                    v10_3.join();
                    v4_6.join();
                    android.util.Log.i("MoleSocketBridge", new StringBuilder().append("\u65ad\u5f00 ").append(v6_2[0]).append(":").append(v6_2[1]).toString());
                    com.taomee.mole.SocketBridge.closeQuietly(v7_11);
                } catch (Throwable v0_4) {
                    v3_4 = v7_11;
                }
                com.taomee.mole.SocketBridge.closeQuietly(p13);
                return;
            } else {
                v5.write("HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n".getBytes(java.nio.charset.StandardCharsets.ISO_8859_1));
                v5.flush();
                com.taomee.mole.SocketBridge.closeQuietly(0);
                com.taomee.mole.SocketBridge.closeQuietly(p13);
                return;
            }
        } else {
            com.taomee.mole.SocketBridge.closeQuietly(0);
            com.taomee.mole.SocketBridge.closeQuietly(p13);
            return;
        }
    }

    private static String[] parseTarget(String p8)
    {
        String[] v8_3;
        String v0_2 = p8.indexOf(63);
        if (v0_2 < null) {
            v8_3 = "";
        } else {
            v8_3 = p8.substring((v0_2 + 1));
        }
        String v0_1 = String.valueOf(1863);
        String[] v8_1 = v8_3.split("&");
        int v1_1 = v8_1.length;
        String v3 = "123.206.131.236";
        int v4 = 0;
        while (v4 < v1_1) {
            String v5_0 = v8_1[v4];
            boolean v6_1 = v5_0.indexOf(61);
            if (v6_1) {
                String v7 = v5_0.substring(0, v6_1);
                String v5_1 = v5_0.substring((v6_1 + 1));
                if (!"host".equals(v7)) {
                    if ("port".equals(v7)) {
                        v0_1 = v5_1;
                    }
                } else {
                    v3 = v5_1;
                }
            }
            v4++;
        }
        return new String[] {v3, v0_1});
    }

    private static boolean plausibleIp(int p2, int p3, int p4, int p5)
    {
        if ((p2 >= 1) && (p2 <= 223)) {
            if ((p5 != 0) && (p5 != 255)) {
                if ((p2 != 10) && (p2 != 127)) {
                    if ((p2 != 172) || ((p3 < 16) || (p3 > 31))) {
                        if ((p2 != 192) || (p3 != 168)) {
                            if ((p2 != 169) || (p3 != 254)) {
                                if ((p2 != 100) || ((p3 < 64) || (p3 > 127))) {
                                    return 1;
                                } else {
                                    return 0;
                                }
                            } else {
                                return 0;
                            }
                        } else {
                            return 0;
                        }
                    } else {
                        return 0;
                    }
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

    private void pumpClientToTcp(java.io.InputStream p16, java.io.OutputStream p17)
    {
        try {
            do {
                int v2_4 = com.taomee.mole.SocketBridge.readFully(p16, 2);
            } while(byte[] v5_2.length <= 0);
            p17.write(v5_2);
            p17.flush();
        } catch (String v0_4) {
            android.util.Log.w("MoleSocketBridge", new StringBuilder().append("\u4e0a\u884c\u7ed3\u675f\uff1a").append(v0_4.getMessage()).toString());
            return;
        }
        if (v2_4 != 0) {
            byte v6_1;
            int v3 = 0;
            int v4_1 = (v2_4[0] & 15);
            if ((v2_4[1] & 128) == 0) {
                v6_1 = 0;
            } else {
                v6_1 = 1;
            }
            int v7_0 = ((long) (v2_4[1] & 127));
            if (v7_0 != 126) {
                if (v7_0 != 127) {
                } else {
                    java.io.OutputStream v1_5 = com.taomee.mole.SocketBridge.readFully(p16, 8);
                    if (v1_5 != null) {
                        v7_0 = 0;
                        byte[] v5_0 = 0;
                        while (v5_0 < 8) {
                            v7_0 = ((v7_0 << 8) | (((long) v1_5[v5_0]) & 255));
                            v5_0++;
                        }
                    } else {
                        return;
                    }
                }
            } else {
                java.io.OutputStream v1_6 = com.taomee.mole.SocketBridge.readFully(p16, 2);
                if (v1_6 != null) {
                    v7_0 = ((((long) (v1_6[0] & 255)) << 8) | ((long) (v1_6[1] & 255)));
                } else {
                    return;
                }
            }
            java.io.OutputStream v1_9;
            if (v6_1 == 0) {
                v1_9 = 0;
            } else {
                v1_9 = com.taomee.mole.SocketBridge.readFully(p16, 4);
            }
            if ((v6_1 == 0) || (v1_9 != null)) {
                if (v7_0 <= 0) {
                    v5_2 = new byte[0];
                } else {
                    if (v7_0 <= 67108864) {
                        v5_2 = com.taomee.mole.SocketBridge.readFully(p16, ((int) v7_0));
                        if (v5_2 == null) {
                            return;
                        }
                    } else {
                        return;
                    }
                }
                if (v1_9 != null) {
                    while (v3 < v5_2.length) {
                        v5_2[v3] = ((byte) (v5_2[v3] ^ v1_9[(v3 & 3)]));
                        v3++;
                    }
                }
                if (v4_1 != 8) {
                    if (v4_1 != 9) {
                        if (v4_1 != 10) {
                            if (v5_2.length > 0) {
                            }
                        } else {
                        }
                    }
                } else {
                    return;
                }
            } else {
                return;
            }
        } else {
            return;
        }
    }

    private void pumpTcpToClient(java.io.InputStream p4, java.io.OutputStream p5)
    {
        String v0_1 = new byte[65536];
        try {
            while(true) {
                byte[] v1_0 = p4.read(v0_1);
                p5.write(com.taomee.mole.SocketBridge.buildFrame(2, v0_1, v1_0));
                p5.flush();
            }
            return;
        } catch (String v4_1) {
            android.util.Log.w("MoleSocketBridge", new StringBuilder().append("\u4e0b\u884c\u7ed3\u675f\uff1a").append(v4_1.getMessage()).toString());
            return;
        }
        if (v1_0 > null) {
        }
        return;
    }

    private static byte[] readFully(java.io.InputStream p3, int p4)
    {
        int v0 = 0;
        if (p4 != 0) {
            byte[] v1 = new byte[p4];
            while (v0 < p4) {
                int v2_1 = p3.read(v1, v0, (p4 - v0));
                if (v2_1 >= 0) {
                    v0 += v2_1;
                } else {
                    return 0;
                }
            }
            return v1;
        } else {
            int v3_2 = new byte[0];
            return v3_2;
        }
    }

    private static String readHttpHead(java.io.InputStream p6)
    {
        StringBuilder v0_1 = new StringBuilder();
        int v1 = 0;
        int v2_2 = 0;
        do {
            int v3_2 = p6.read();
            if (v3_2 >= 0) {
                v1++;
                if (v1 <= 65536) {
                    v0_1.append(((char) v3_2));
                    v2_2 = (((v2_2 << 8) | (v3_2 & 255)) & -1);
                } else {
                    return 0;
                }
            } else {
                return 0;
            }
        } while(v2_2 != 218762506);
        return v0_1.toString();
    }

    private void report(String p2, int p3)
    {
        if ((p3 >= 1024) && (p3 <= 65535)) {
            if ((p3 != 8080) && ((p3 != 443) && (p3 != 80))) {
                com.taomee.mole.SocketBridge$DiscoveryListener v0_1 = this.listener;
                if (v0_1 != null) {
                    v0_1.onTarget(p2, p3);
                }
                return;
            } else {
                return;
            }
        } else {
            return;
        }
    }

    private static String sha1Base64(String p2)
    {
        return android.util.Base64.encodeToString(java.security.MessageDigest.getInstance("SHA-1").digest(p2.getBytes(java.nio.charset.StandardCharsets.ISO_8859_1)), 2);
    }

    private byte[] sniff(byte[] p11, byte[] p12, int p13)
    {
        int v0_0 = p11.length;
        int v1_0 = (v0_0 + p13);
        byte[] v2 = new byte[v1_0];
        System.arraycopy(p11, 0, v2, 0, v0_0);
        System.arraycopy(p12, 0, v2, v0_0, p13);
        int v11_7 = new StringBuilder(v1_0);
        int v12_10 = 0;
        while (v12_10 < v1_0) {
            int v13_5 = ((char) (v2[v12_10] & 255));
            if ((v13_5 < 32) || (v13_5 >= 127)) {
                v13_5 = 32;
            }
            v11_7.append(v13_5);
            v12_10++;
        }
        int v11_1 = v11_7.toString();
        int v11_2 = java.util.regex.Pattern.compile("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})(?:\\D{0,3}(\\d{2,5}))?").matcher(v11_1);
        while(true) {
            int v13_6 = ".";
            if (!v11_2.find()) {
                break;
            }
            int v12_20 = Integer.parseInt(v11_2.group(1));
            int v0_5 = Integer.parseInt(v11_2.group(2));
            String v4_13 = Integer.parseInt(v11_2.group(3));
            int v5_0 = Integer.parseInt(v11_2.group(4));
            if ((com.taomee.mole.SocketBridge.plausibleIp(v12_20, v0_5, v4_13, v5_0)) && (v11_2.group(5) != null)) {
                try {
                    this.report(new StringBuilder().append(v12_20).append(".").append(v0_5).append(v13_6).append(v4_13).append(".").append(v5_0).toString(), Integer.parseInt(v11_2.group(5)));
                } catch (int v12) {
                }
            }
        }
        int v11_3 = 0;
        while(true) {
            int v12_13 = (v11_3 + 5);
            if (v12_13 >= v1_0) {
                break;
            }
            String v4_2 = (v2[v11_3] & 255);
            int v5_1 = (v11_3 + 1);
            int v6_3 = (v2[v5_1] & 255);
            int v7_5 = (v2[(v11_3 + 2)] & 255);
            int v8_2 = (v2[(v11_3 + 3)] & 255);
            if (com.taomee.mole.SocketBridge.plausibleIp(v4_2, v6_3, v7_5, v8_2)) {
                String v4_10 = new StringBuilder().append(v4_2).append(".").append(v6_3).append(v13_6).append(v7_5).append(v13_6).append(v8_2).toString();
                int v11_6 = (v11_3 + 4);
                int v6_7 = (((v2[v11_6] & 255) << 8) | (v2[v12_13] & 255));
                int v11_10 = ((v2[v11_6] & 255) | ((v2[v12_13] & 255) << 8));
                this.report(v4_10, v6_7);
                if (v11_10 != v6_7) {
                    this.report(v4_10, v11_10);
                }
            }
            v11_3 = v5_1;
        }
        int v11_4 = Math.min(8, v1_0);
        int v12_14 = new byte[v11_4];
        System.arraycopy(v2, (v1_0 - v11_4), v12_14, 0, v11_4);
        return v12_14;
    }

    public int getPort()
    {
        return this.port;
    }

    public void setDiscoveryListener(com.taomee.mole.SocketBridge$DiscoveryListener p1)
    {
        this.listener = p1;
        return;
    }

    public declared_synchronized void start()
    {
        try {
            if (this.server == null) {
                try {
                    Throwable v0_6 = new java.net.ServerSocket(0, 24, java.net.InetAddress.getByName("127.0.0.1"));
                    this.server = v0_6;
                    this.port = v0_6.getLocalPort();
                    this.pool = java.util.concurrent.Executors.newCachedThreadPool();
                    android.util.Log.i("MoleSocketBridge", new StringBuilder().append("\u6865\u5df2\u542f\u52a8\uff1a127.0.0.1:").append(this.port).toString());
                    String v2_6 = new Thread(new com.taomee.mole.SocketBridge$1(this, v0_6, this.pool), "mole-ws-accept");
                    v2_6.setDaemon(1);
                    v2_6.start();
                } catch (Throwable v0_4) {
                    android.util.Log.e("MoleSocketBridge", "\u6865\u542f\u52a8\u5931\u8d25 \u2014\u2014 \u767b\u5f55\u4e0e\u8fdb\u5730\u56fe\u4f1a\u5931\u8d25", v0_4);
                }
                return;
            } else {
                return;
            }
        } catch (Throwable v0_5) {
            throw v0_5;
        }
    }

    public declared_synchronized void stop()
    {
        try {
            if (this.server != null) {
                this.server.close();
            }
            try {
                this.server = 0;
            } catch (java.util.concurrent.ExecutorService v0_1) {
                throw v0_1;
            }
            if (this.pool != null) {
                this.pool.shutdownNow();
            }
            return;
        } catch (java.util.concurrent.ExecutorService v0) {
        }
    }
}
