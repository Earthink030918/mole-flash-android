.class public Lcom/taomee/mole/SocketBridge;
.super Ljava/lang/Object;
.source "SocketBridge.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lcom/taomee/mole/SocketBridge$DiscoveryListener;
    }
.end annotation


# static fields
.field private static final DEFAULT_HOST:Ljava/lang/String; = "123.206.131.236"

.field private static final DEFAULT_PORT:I = 0x747

.field private static final ENABLE_BYTE_SNIFF:Z = false

.field private static final MAX_HEADER:I = 0x10000

.field private static final TAG:Ljava/lang/String; = "MoleSocketBridge"

.field private static final WS_GUID:Ljava/lang/String; = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


# instance fields
.field private volatile listener:Lcom/taomee/mole/SocketBridge$DiscoveryListener;

.field private pool:Ljava/util/concurrent/ExecutorService;

.field private volatile port:I

.field private volatile server:Ljava/net/ServerSocket;


# direct methods
.method public constructor <init>()V
    .locals 1

    .line 40
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 50
    const/4 v0, 0x0

    iput v0, p0, Lcom/taomee/mole/SocketBridge;->port:I

    return-void
.end method

.method static synthetic access$000(Lcom/taomee/mole/SocketBridge;Ljava/net/Socket;)V
    .locals 0

    .line 40
    invoke-direct {p0, p1}, Lcom/taomee/mole/SocketBridge;->handle(Ljava/net/Socket;)V

    return-void
.end method

.method static synthetic access$100(Lcom/taomee/mole/SocketBridge;Ljava/io/InputStream;Ljava/io/OutputStream;)V
    .locals 0

    .line 40
    invoke-direct {p0, p1, p2}, Lcom/taomee/mole/SocketBridge;->pumpClientToTcp(Ljava/io/InputStream;Ljava/io/OutputStream;)V

    return-void
.end method

.method static synthetic access$200(Lcom/taomee/mole/SocketBridge;Ljava/io/InputStream;Ljava/io/OutputStream;)V
    .locals 0

    .line 40
    invoke-direct {p0, p1, p2}, Lcom/taomee/mole/SocketBridge;->pumpTcpToClient(Ljava/io/InputStream;Ljava/io/OutputStream;)V

    return-void
.end method

.method private static buildFrame(I[BI)[B
    .locals 8

    .line 354
    const/4 v0, 0x2

    const/4 v1, 0x1

    const/4 v2, 0x0

    const/16 v3, 0x7e

    if-ge p2, v3, :cond_0

    .line 355
    new-array v0, v0, [B

    or-int/lit16 p0, p0, 0x80

    int-to-byte p0, p0

    aput-byte p0, v0, v2

    int-to-byte p0, p2

    aput-byte p0, v0, v1

    goto :goto_1

    .line 356
    :cond_0
    const/high16 v4, 0x10000

    if-ge p2, v4, :cond_1

    .line 357
    const/4 v4, 0x4

    new-array v4, v4, [B

    or-int/lit16 p0, p0, 0x80

    int-to-byte p0, p0

    aput-byte p0, v4, v2

    aput-byte v3, v4, v1

    ushr-int/lit8 p0, p2, 0x8

    and-int/lit16 p0, p0, 0xff

    int-to-byte p0, p0

    aput-byte p0, v4, v0

    and-int/lit16 p0, p2, 0xff

    int-to-byte p0, p0

    const/4 v0, 0x3

    aput-byte p0, v4, v0

    move-object v0, v4

    goto :goto_1

    .line 360
    :cond_1
    const/16 v0, 0xa

    new-array v0, v0, [B

    .line 361
    or-int/lit16 p0, p0, 0x80

    int-to-byte p0, p0

    aput-byte p0, v0, v2

    .line 362
    const/16 p0, 0x7f

    aput-byte p0, v0, v1

    .line 363
    const/4 p0, 0x0

    :goto_0
    const/16 v1, 0x8

    if-ge p0, v1, :cond_2

    .line 364
    add-int/lit8 v3, p0, 0x2

    int-to-long v4, p2

    rsub-int/lit8 v6, p0, 0x7

    mul-int/lit8 v6, v6, 0x8

    ushr-long/2addr v4, v6

    const-wide/16 v6, 0xff

    and-long/2addr v4, v6

    long-to-int v1, v4

    int-to-byte v1, v1

    aput-byte v1, v0, v3

    .line 363
    add-int/lit8 p0, p0, 0x1

    goto :goto_0

    .line 367
    :cond_2
    :goto_1
    array-length p0, v0

    add-int/2addr p0, p2

    new-array p0, p0, [B

    .line 368
    array-length v1, v0

    invoke-static {v0, v2, p0, v2, v1}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 369
    array-length v0, v0

    invoke-static {p1, v2, p0, v0, p2}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 370
    return-object p0
.end method

.method private static closeQuietly(Ljava/io/Closeable;)V
    .locals 0

    .line 443
    if-eqz p0, :cond_0

    :try_start_0
    invoke-interface {p0}, Ljava/io/Closeable;->close()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    goto :goto_0

    .line 444
    :catchall_0
    move-exception p0

    goto :goto_1

    .line 445
    :cond_0
    :goto_0
    nop

    .line 446
    :goto_1
    return-void
.end method

.method private static extractHeader(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .locals 6

    .line 397
    const-string v0, "\r\n"

    invoke-virtual {p0, v0}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object p0

    array-length v0, p0

    const/4 v1, 0x0

    const/4 v2, 0x0

    :goto_0
    if-ge v2, v0, :cond_1

    aget-object v3, p0, v2

    .line 398
    const/16 v4, 0x3a

    invoke-virtual {v3, v4}, Ljava/lang/String;->indexOf(I)I

    move-result v4

    .line 399
    if-lez v4, :cond_0

    invoke-virtual {v3, v1, v4}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v5, p1}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v5

    if-eqz v5, :cond_0

    .line 400
    add-int/lit8 v4, v4, 0x1

    invoke-virtual {v3, v4}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 397
    :cond_0
    add-int/lit8 v2, v2, 0x1

    goto :goto_0

    .line 403
    :cond_1
    const/4 p0, 0x0

    return-object p0
.end method

.method private static firstLinePath(Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 390
    const-string v0, "\r\n"

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result v0

    .line 391
    if-ltz v0, :cond_0

    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    .line 392
    :cond_0
    const-string v0, " "

    invoke-virtual {p0, v0}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object p0

    .line 393
    array-length v0, p0

    const/4 v1, 0x1

    if-le v0, v1, :cond_1

    aget-object p0, p0, v1

    goto :goto_0

    :cond_1
    const-string p0, "/"

    :goto_0
    return-object p0
.end method

.method private handle(Ljava/net/Socket;)V
    .locals 12

    .line 114
    const-string v0, ":"

    const-string v1, "MoleSocketBridge"

    .line 116
    const/4 v2, 0x1

    const/4 v3, 0x0

    :try_start_0
    invoke-virtual {p1, v2}, Ljava/net/Socket;->setTcpNoDelay(Z)V

    .line 117
    invoke-virtual {p1}, Ljava/net/Socket;->getInputStream()Ljava/io/InputStream;

    move-result-object v4

    .line 118
    invoke-virtual {p1}, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v5

    .line 120
    invoke-static {v4}, Lcom/taomee/mole/SocketBridge;->readHttpHead(Ljava/io/InputStream;)Ljava/lang/String;

    move-result-object v6
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 121
    if-nez v6, :cond_0

    .line 172
    invoke-static {v3}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 173
    invoke-static {p1}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 121
    return-void

    .line 122
    :cond_0
    :try_start_1
    const-string v7, "sec-websocket-key"

    invoke-static {v6, v7}, Lcom/taomee/mole/SocketBridge;->extractHeader(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    .line 123
    if-nez v7, :cond_1

    .line 124
    const-string v0, "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n"

    sget-object v2, Ljava/nio/charset/StandardCharsets;->ISO_8859_1:Ljava/nio/charset/Charset;

    .line 125
    invoke-virtual {v0, v2}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v0

    .line 124
    invoke-virtual {v5, v0}, Ljava/io/OutputStream;->write([B)V

    .line 126
    invoke-virtual {v5}, Ljava/io/OutputStream;->flush()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 172
    invoke-static {v3}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 173
    invoke-static {p1}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 127
    return-void

    .line 130
    :cond_1
    :try_start_2
    invoke-static {v6}, Lcom/taomee/mole/SocketBridge;->firstLinePath(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v6

    invoke-static {v6}, Lcom/taomee/mole/SocketBridge;->parseTarget(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v6

    .line 131
    new-instance v8, Ljava/lang/StringBuilder;

    invoke-direct {v8}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v8, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    const-string v8, "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v7

    invoke-static {v7}, Lcom/taomee/mole/SocketBridge;->sha1Base64(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    .line 132
    new-instance v8, Ljava/lang/StringBuilder;

    invoke-direct {v8}, Ljava/lang/StringBuilder;-><init>()V

    const-string v9, "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: "

    invoke-virtual {v8, v9}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v8

    invoke-virtual {v8, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    const-string v8, "\r\n\r\n"

    invoke-virtual {v7, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v7

    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v7

    sget-object v8, Ljava/nio/charset/StandardCharsets;->ISO_8859_1:Ljava/nio/charset/Charset;

    .line 136
    invoke-virtual {v7, v8}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v7

    .line 132
    invoke-virtual {v5, v7}, Ljava/io/OutputStream;->write([B)V

    .line 137
    invoke-virtual {v5}, Ljava/io/OutputStream;->flush()V

    .line 139
    new-instance v7, Ljava/net/Socket;

    invoke-direct {v7}, Ljava/net/Socket;-><init>()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 140
    :try_start_3
    invoke-virtual {v7, v2}, Ljava/net/Socket;->setTcpNoDelay(Z)V

    .line 141
    new-instance v3, Ljava/net/InetSocketAddress;

    const/4 v8, 0x0

    aget-object v9, v6, v8

    aget-object v10, v6, v2

    invoke-static {v10}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v10

    invoke-direct {v3, v9, v10}, Ljava/net/InetSocketAddress;-><init>(Ljava/lang/String;I)V

    const/16 v9, 0x2ee0

    invoke-virtual {v7, v3, v9}, Ljava/net/Socket;->connect(Ljava/net/SocketAddress;I)V

    .line 143
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v9, "\u5df2\u63a5\u5165 -> "

    invoke-virtual {v3, v9}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    aget-object v9, v6, v8

    invoke-static {v9}, Lcom/taomee/mole/MainActivity;->mask(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v9

    invoke-virtual {v3, v9}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    aget-object v9, v6, v2

    invoke-virtual {v3, v9}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-static {v1, v3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 145
    invoke-virtual {v7}, Ljava/net/Socket;->getInputStream()Ljava/io/InputStream;

    move-result-object v3

    .line 146
    invoke-virtual {v7}, Ljava/net/Socket;->getOutputStream()Ljava/io/OutputStream;

    move-result-object v9

    .line 147
    nop

    .line 148
    nop

    .line 150
    new-instance v10, Ljava/lang/Thread;

    new-instance v11, Lcom/taomee/mole/SocketBridge$2;

    invoke-direct {v11, p0, v4, v9}, Lcom/taomee/mole/SocketBridge$2;-><init>(Lcom/taomee/mole/SocketBridge;Ljava/io/InputStream;Ljava/io/OutputStream;)V

    const-string v4, "mole-ws-up"

    invoke-direct {v10, v11, v4}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 156
    new-instance v4, Ljava/lang/Thread;

    new-instance v9, Lcom/taomee/mole/SocketBridge$3;

    invoke-direct {v9, p0, v3, v5}, Lcom/taomee/mole/SocketBridge$3;-><init>(Lcom/taomee/mole/SocketBridge;Ljava/io/InputStream;Ljava/io/OutputStream;)V

    const-string v3, "mole-ws-down"

    invoke-direct {v4, v9, v3}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 162
    invoke-virtual {v10, v2}, Ljava/lang/Thread;->setDaemon(Z)V

    .line 163
    invoke-virtual {v4, v2}, Ljava/lang/Thread;->setDaemon(Z)V

    .line 164
    invoke-virtual {v10}, Ljava/lang/Thread;->start()V

    .line 165
    invoke-virtual {v4}, Ljava/lang/Thread;->start()V

    .line 166
    invoke-virtual {v10}, Ljava/lang/Thread;->join()V

    # ===== FIX(S1) 上行结束即拆除两侧链路 =====
    # 原逻辑：join 完上行线程，紧接着无条件 join 下行线程。
    # 问题：WebView 侧发完 close 帧后（页面重载 / 切场景 / 掉线重连都会发生），
    #   pumpClientToTcp 直接 return，但**没有关闭任何 socket**；
    #   此时下行线程仍阻塞在 TCP 的 read() 上，对端不出数据就永远不返回，
    #   于是 handle 线程 + mole-ws-down 线程双双永久挂死，两个 socket 也不释放。
    #   pool 是 newCachedThreadPool（无上限），每泄漏一次就多两个线程一份 fd，
    #   累积到一定程度 → 线程/fd 耗尽 → 渲染线程拿不到资源 → 
    #   进程被系统杀掉或 Chrome_InProcGp SIGTRAP，体感就是「整个 APP 自己重启」；
    #   同时商城这种一次性开大量连接又大量断开的页面会最先顶不住 → 「进商城卡死」。
    # 修法：上行一结束就把两侧 socket 关掉，下行 read() 立刻抛异常退出，
    #   两个 join 都能正常返回，线程与 fd 归还。
    invoke-static {v7}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    invoke-static {p1}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 167
    invoke-virtual {v4}, Ljava/lang/Thread;->join()V

    .line 168
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "\u65ad\u5f00 "

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    aget-object v4, v6, v8

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    aget-object v2, v6, v2

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v1, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_0

    .line 172
    invoke-static {v7}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    goto :goto_1

    .line 169
    :catchall_0
    move-exception v0

    move-object v3, v7

    goto :goto_0

    :catchall_1
    move-exception v0

    .line 170
    :goto_0
    :try_start_4
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "\u6865\u8fde\u63a5\u7ed3\u675f\uff1a"

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v1, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_2

    .line 172
    invoke-static {v3}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 173
    :goto_1
    invoke-static {p1}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 174
    nop

    .line 175
    return-void

    .line 172
    :catchall_2
    move-exception v0

    invoke-static {v3}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 173
    invoke-static {p1}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    .line 174
    throw v0
.end method

.method private static parseTarget(Ljava/lang/String;)[Ljava/lang/String;
    .locals 8

    .line 408
    const/16 v0, 0x3f

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v0

    .line 409
    if-ltz v0, :cond_0

    add-int/lit8 v0, v0, 0x1

    invoke-virtual {p0, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    goto :goto_0

    :cond_0
    const-string p0, ""

    .line 410
    :goto_0
    nop

    .line 411
    const/16 v0, 0x747

    invoke-static {v0}, Ljava/lang/String;->valueOf(I)Ljava/lang/String;

    move-result-object v0

    .line 412
    const-string v1, "&"

    invoke-virtual {p0, v1}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object p0

    array-length v1, p0

    const/4 v2, 0x0

    const-string v3, "123.206.131.236"

    const/4 v4, 0x0

    :goto_1
    if-ge v4, v1, :cond_4

    aget-object v5, p0, v4

    .line 413
    const/16 v6, 0x3d

    invoke-virtual {v5, v6}, Ljava/lang/String;->indexOf(I)I

    move-result v6

    .line 414
    if-gtz v6, :cond_1

    goto :goto_2

    .line 415
    :cond_1
    invoke-virtual {v5, v2, v6}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v7

    .line 416
    add-int/lit8 v6, v6, 0x1

    invoke-virtual {v5, v6}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v5

    .line 417
    const-string v6, "host"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_2

    move-object v3, v5

    goto :goto_2

    .line 418
    :cond_2
    const-string v6, "port"

    invoke-virtual {v6, v7}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v6

    if-eqz v6, :cond_3

    move-object v0, v5

    .line 412
    :cond_3
    :goto_2
    add-int/lit8 v4, v4, 0x1

    goto :goto_1

    .line 420
    :cond_4
    filled-new-array {v3, v0}, [Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private static plausibleIp(IIII)Z
    .locals 2

    .line 333
    const/4 p2, 0x0

    const/4 v0, 0x1

    if-lt p0, v0, :cond_9

    const/16 v1, 0xdf

    if-le p0, v1, :cond_0

    goto :goto_2

    .line 334
    :cond_0
    if-eqz p3, :cond_8

    const/16 v1, 0xff

    if-ne p3, v1, :cond_1

    goto :goto_1

    .line 335
    :cond_1
    const/16 p3, 0xa

    if-eq p0, p3, :cond_7

    const/16 p3, 0x7f

    if-ne p0, p3, :cond_2

    goto :goto_0

    .line 336
    :cond_2
    const/16 v1, 0xac

    if-ne p0, v1, :cond_3

    const/16 v1, 0x10

    if-lt p1, v1, :cond_3

    const/16 v1, 0x1f

    if-gt p1, v1, :cond_3

    return p2

    .line 337
    :cond_3
    const/16 v1, 0xc0

    if-ne p0, v1, :cond_4

    const/16 v1, 0xa8

    if-ne p1, v1, :cond_4

    return p2

    .line 338
    :cond_4
    const/16 v1, 0xa9

    if-ne p0, v1, :cond_5

    const/16 v1, 0xfe

    if-ne p1, v1, :cond_5

    return p2

    .line 339
    :cond_5
    const/16 v1, 0x64

    if-ne p0, v1, :cond_6

    const/16 p0, 0x40

    if-lt p1, p0, :cond_6

    if-gt p1, p3, :cond_6

    return p2

    .line 340
    :cond_6
    return v0

    .line 335
    :cond_7
    :goto_0
    return p2

    .line 334
    :cond_8
    :goto_1
    return p2

    .line 333
    :cond_9
    :goto_2
    return p2
.end method

.method private pumpClientToTcp(Ljava/io/InputStream;Ljava/io/OutputStream;)V
    .locals 15

    .line 181
    move-object/from16 v0, p1

    :goto_0
    const/4 v1, 0x2

    :try_start_0
    invoke-static {v0, v1}, Lcom/taomee/mole/SocketBridge;->readFully(Ljava/io/InputStream;I)[B

    move-result-object v2

    .line 182
    if-nez v2, :cond_0

    return-void

    .line 183
    :cond_0
    const/4 v3, 0x0

    aget-byte v4, v2, v3

    and-int/lit8 v4, v4, 0xf

    .line 184
    const/4 v5, 0x1

    aget-byte v6, v2, v5

    and-int/lit16 v6, v6, 0x80

    if-eqz v6, :cond_1

    const/4 v6, 0x1

    goto :goto_1

    :cond_1
    const/4 v6, 0x0

    .line 185
    :goto_1
    aget-byte v2, v2, v5

    and-int/lit8 v2, v2, 0x7f

    int-to-long v7, v2

    .line 186
    const-wide/16 v9, 0x7e

    const-wide/16 v11, 0x0

    const/16 v2, 0x8

    cmp-long v13, v7, v9

    if-nez v13, :cond_3

    .line 187
    invoke-static {v0, v1}, Lcom/taomee/mole/SocketBridge;->readFully(Ljava/io/InputStream;I)[B

    move-result-object v1

    .line 188
    if-nez v1, :cond_2

    return-void

    .line 189
    :cond_2
    aget-byte v7, v1, v3

    and-int/lit16 v7, v7, 0xff

    int-to-long v7, v7

    shl-long/2addr v7, v2

    aget-byte v1, v1, v5

    and-int/lit16 v1, v1, 0xff

    int-to-long v9, v1

    or-long/2addr v7, v9

    goto :goto_3

    .line 190
    :cond_3
    const-wide/16 v9, 0x7f

    cmp-long v1, v7, v9

    if-nez v1, :cond_5

    .line 191
    invoke-static {v0, v2}, Lcom/taomee/mole/SocketBridge;->readFully(Ljava/io/InputStream;I)[B

    move-result-object v1

    .line 192
    if-nez v1, :cond_4

    return-void

    .line 193
    :cond_4
    nop

    .line 194
    move-wide v7, v11

    const/4 v5, 0x0

    :goto_2
    if-ge v5, v2, :cond_6

    shl-long/2addr v7, v2

    aget-byte v9, v1, v5

    int-to-long v9, v9

    const-wide/16 v13, 0xff

    and-long/2addr v9, v13

    or-long/2addr v7, v9

    add-int/lit8 v5, v5, 0x1

    goto :goto_2

    .line 190
    :cond_5
    :goto_3
    nop

    .line 196
    :cond_6
    if-eqz v6, :cond_7

    const/4 v1, 0x4

    invoke-static {v0, v1}, Lcom/taomee/mole/SocketBridge;->readFully(Ljava/io/InputStream;I)[B

    move-result-object v1

    goto :goto_4

    :cond_7
    const/4 v1, 0x0

    .line 197
    :goto_4
    if-eqz v6, :cond_8

    if-nez v1, :cond_8

    return-void

    .line 199
    :cond_8
    cmp-long v5, v7, v11

    if-lez v5, :cond_a

    .line 200
    const-wide/32 v5, 0x4000000

    cmp-long v9, v7, v5

    if-lez v9, :cond_9

    return-void

    .line 201
    :cond_9
    long-to-int v5, v7

    invoke-static {v0, v5}, Lcom/taomee/mole/SocketBridge;->readFully(Ljava/io/InputStream;I)[B

    move-result-object v5

    .line 202
    if-nez v5, :cond_b

    return-void

    .line 204
    :cond_a
    new-array v5, v3, [B

    .line 207
    :cond_b
    if-eqz v1, :cond_c

    .line 208
    nop

    :goto_5
    array-length v6, v5

    if-ge v3, v6, :cond_c

    .line 209
    aget-byte v6, v5, v3

    and-int/lit8 v7, v3, 0x3

    aget-byte v7, v1, v7

    xor-int/2addr v6, v7

    int-to-byte v6, v6

    aput-byte v6, v5, v3

    .line 208
    add-int/lit8 v3, v3, 0x1

    goto :goto_5

    .line 213
    :cond_c
    if-ne v4, v2, :cond_d

    return-void

    .line 214
    :cond_d
    const/16 v1, 0x9

    if-eq v4, v1, :cond_10

    const/16 v1, 0xa

    if-ne v4, v1, :cond_e

    goto/16 :goto_0

    .line 215
    :cond_e
    array-length v1, v5

    if-lez v1, :cond_f

    .line 216
    move-object/from16 v1, p2

    invoke-virtual {v1, v5}, Ljava/io/OutputStream;->write([B)V

    .line 217
    invoke-virtual/range {p2 .. p2}, Ljava/io/OutputStream;->flush()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    goto :goto_6

    .line 215
    :cond_f
    move-object/from16 v1, p2

    .line 219
    :goto_6
    goto/16 :goto_0

    .line 214
    :cond_10
    move-object/from16 v1, p2

    goto/16 :goto_0

    .line 220
    :catchall_0
    move-exception v0

    .line 221
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u4e0a\u884c\u7ed3\u675f\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v0}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "MoleSocketBridge"

    invoke-static {v1, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 223
    return-void
.end method

.method private pumpTcpToClient(Ljava/io/InputStream;Ljava/io/OutputStream;)V
    .locals 3

    .line 241
    const/high16 v0, 0x10000

    new-array v0, v0, [B

    .line 242
    nop

    .line 245
    :goto_0
    :try_start_0
    invoke-virtual {p1, v0}, Ljava/io/InputStream;->read([B)I

    move-result v1

    .line 246
    if-gtz v1, :cond_0

    # ===== FIX(S2) 下行结束也拆链路（对称于 FIX(S1)）=====
    # 服务器先断线时，下行 read() 返回 <=0，原逻辑只是 return，
    # 上行线程仍然阻塞在 WebSocket 的 readFully 上 → 同样泄漏。
    # 这里把 WebSocket 侧输出流一并关闭（等于关闭该 socket），
    # 上行 read 立即抛异常退出，两个 join 都能返回。
    invoke-static {p2}, Lcom/taomee/mole/SocketBridge;->closeQuietly(Ljava/io/Closeable;)V

    return-void

    .line 247
    :cond_0
    const/4 v2, 0x2

    invoke-static {v2, v0, v1}, Lcom/taomee/mole/SocketBridge;->buildFrame(I[BI)[B

    move-result-object v1

    invoke-virtual {p2, v1}, Ljava/io/OutputStream;->write([B)V

    .line 248
    invoke-virtual {p2}, Ljava/io/OutputStream;->flush()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 255
    goto :goto_0

    .line 256
    :catchall_0
    move-exception p1

    .line 257
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "\u4e0b\u884c\u7ed3\u675f\uff1a"

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string p2, "MoleSocketBridge"

    invoke-static {p2, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 259
    return-void
.end method

.method private static readFully(Ljava/io/InputStream;I)[B
    .locals 3
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 424
    const/4 v0, 0x0

    if-nez p1, :cond_0

    new-array p0, v0, [B

    return-object p0

    .line 425
    :cond_0
    new-array v1, p1, [B

    .line 426
    nop

    .line 427
    :goto_0
    if-ge v0, p1, :cond_2

    .line 428
    sub-int v2, p1, v0

    invoke-virtual {p0, v1, v0, v2}, Ljava/io/InputStream;->read([BII)I

    move-result v2

    .line 429
    if-gez v2, :cond_1

    const/4 p0, 0x0

    return-object p0

    .line 430
    :cond_1
    add-int/2addr v0, v2

    .line 431
    goto :goto_0

    .line 432
    :cond_2
    return-object v1
.end method

.method private static readHttpHead(Ljava/io/InputStream;)Ljava/lang/String;
    .locals 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 374
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    .line 375
    nop

    .line 376
    const/4 v1, 0x0

    const/4 v2, 0x0

    .line 378
    :goto_0
    invoke-virtual {p0}, Ljava/io/InputStream;->read()I

    move-result v3

    .line 379
    const/4 v4, 0x0

    if-gez v3, :cond_0

    return-object v4

    .line 380
    :cond_0
    add-int/lit8 v1, v1, 0x1

    .line 381
    const/high16 v5, 0x10000

    if-le v1, v5, :cond_1

    return-object v4

    .line 382
    :cond_1
    int-to-char v4, v3

    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 383
    shl-int/lit8 v2, v2, 0x8

    and-int/lit16 v3, v3, 0xff

    or-int/2addr v2, v3

    and-int/lit8 v2, v2, -0x1

    .line 384
    const v3, 0xd0a0d0a

    if-ne v2, v3, :cond_2

    .line 386
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 385
    :cond_2
    goto :goto_0
.end method

.method private report(Ljava/lang/String;I)V
    .locals 1

    .line 344
    const/16 v0, 0x400

    if-lt p2, v0, :cond_4

    const v0, 0xffff

    if-le p2, v0, :cond_0

    goto :goto_1

    .line 345
    :cond_0
    const/16 v0, 0x1f90

    if-eq p2, v0, :cond_3

    const/16 v0, 0x1bb

    if-eq p2, v0, :cond_3

    const/16 v0, 0x50

    if-ne p2, v0, :cond_1

    goto :goto_0

    .line 346
    :cond_1
    iget-object v0, p0, Lcom/taomee/mole/SocketBridge;->listener:Lcom/taomee/mole/SocketBridge$DiscoveryListener;

    .line 347
    if-eqz v0, :cond_2

    invoke-interface {v0, p1, p2}, Lcom/taomee/mole/SocketBridge$DiscoveryListener;->onTarget(Ljava/lang/String;I)V

    .line 348
    :cond_2
    return-void

    .line 345
    :cond_3
    :goto_0
    return-void

    .line 344
    :cond_4
    :goto_1
    return-void
.end method

.method private static sha1Base64(Ljava/lang/String;)Ljava/lang/String;
    .locals 2
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/lang/Exception;
        }
    .end annotation

    .line 436
    const-string v0, "SHA-1"

    invoke-static {v0}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;

    move-result-object v0

    .line 437
    sget-object v1, Ljava/nio/charset/StandardCharsets;->ISO_8859_1:Ljava/nio/charset/Charset;

    invoke-virtual {p0, v1}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object p0

    invoke-virtual {v0, p0}, Ljava/security/MessageDigest;->digest([B)[B

    move-result-object p0

    .line 438
    const/4 v0, 0x2

    invoke-static {p0, v0}, Landroid/util/Base64;->encodeToString([BI)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private sniff([B[BI)[B
    .locals 10

    .line 283
    array-length v0, p1

    .line 284
    add-int v1, v0, p3

    new-array v2, v1, [B

    .line 285
    const/4 v3, 0x0

    invoke-static {p1, v3, v2, v3, v0}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 286
    invoke-static {p2, v3, v2, v0, p3}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 289
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1, v1}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 290
    const/4 p2, 0x0

    :goto_0
    if-ge p2, v1, :cond_1

    .line 291
    aget-byte p3, v2, p2

    and-int/lit16 p3, p3, 0xff

    int-to-char p3, p3

    .line 292
    const/16 v0, 0x20

    if-lt p3, v0, :cond_0

    const/16 v4, 0x7f

    if-ge p3, v4, :cond_0

    goto :goto_1

    :cond_0
    const/16 p3, 0x20

    :goto_1
    invoke-virtual {p1, p3}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 290
    add-int/lit8 p2, p2, 0x1

    goto :goto_0

    .line 294
    :cond_1
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 295
    nop

    .line 296
    const-string p2, "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})(?:\\D{0,3}(\\d{2,5}))?"

    invoke-static {p2}, Ljava/util/regex/Pattern;->compile(Ljava/lang/String;)Ljava/util/regex/Pattern;

    move-result-object p2

    .line 297
    invoke-virtual {p2, p1}, Ljava/util/regex/Pattern;->matcher(Ljava/lang/CharSequence;)Ljava/util/regex/Matcher;

    move-result-object p1

    .line 298
    :goto_2
    invoke-virtual {p1}, Ljava/util/regex/Matcher;->find()Z

    move-result p2

    const-string p3, "."

    if-eqz p2, :cond_4

    .line 299
    const/4 p2, 0x1

    invoke-virtual {p1, p2}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object p2

    invoke-static {p2}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result p2

    .line 300
    const/4 v0, 0x2

    invoke-virtual {p1, v0}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v0

    invoke-static {v0}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v0

    .line 301
    const/4 v4, 0x3

    invoke-virtual {p1, v4}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v4

    invoke-static {v4}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v4

    .line 302
    const/4 v5, 0x4

    invoke-virtual {p1, v5}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v5

    invoke-static {v5}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v5

    .line 303
    invoke-static {p2, v0, v4, v5}, Lcom/taomee/mole/SocketBridge;->plausibleIp(IIII)Z

    move-result v6

    if-nez v6, :cond_2

    goto :goto_2

    .line 304
    :cond_2
    const/4 v6, 0x5

    invoke-virtual {p1, v6}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object v7

    if-eqz v7, :cond_3

    .line 306
    :try_start_0
    new-instance v7, Ljava/lang/StringBuilder;

    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v7, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-virtual {p1, v6}, Ljava/util/regex/Matcher;->group(I)Ljava/lang/String;

    move-result-object p3

    invoke-static {p3}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result p3

    invoke-direct {p0, p2, p3}, Lcom/taomee/mole/SocketBridge;->report(Ljava/lang/String;I)V
    :try_end_0
    .catch Ljava/lang/NumberFormatException; {:try_start_0 .. :try_end_0} :catch_0

    .line 308
    goto :goto_3

    .line 307
    :catch_0
    move-exception p2

    .line 310
    :cond_3
    :goto_3
    goto :goto_2

    .line 313
    :cond_4
    const/4 p1, 0x0

    :goto_4
    add-int/lit8 p2, p1, 0x5

    const/16 v0, 0x8

    if-ge p2, v1, :cond_7

    .line 314
    aget-byte v4, v2, p1

    and-int/lit16 v4, v4, 0xff

    add-int/lit8 v5, p1, 0x1

    aget-byte v6, v2, v5

    and-int/lit16 v6, v6, 0xff

    .line 315
    add-int/lit8 v7, p1, 0x2

    aget-byte v7, v2, v7

    and-int/lit16 v7, v7, 0xff

    add-int/lit8 v8, p1, 0x3

    aget-byte v8, v2, v8

    and-int/lit16 v8, v8, 0xff

    .line 316
    invoke-static {v4, v6, v7, v8}, Lcom/taomee/mole/SocketBridge;->plausibleIp(IIII)Z

    move-result v9

    if-nez v9, :cond_5

    goto :goto_5

    .line 317
    :cond_5
    new-instance v9, Ljava/lang/StringBuilder;

    invoke-direct {v9}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v9, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v6}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v7}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v8}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v4

    .line 318
    add-int/lit8 p1, p1, 0x4

    aget-byte v6, v2, p1

    and-int/lit16 v6, v6, 0xff

    shl-int/2addr v6, v0

    aget-byte v7, v2, p2

    and-int/lit16 v7, v7, 0xff

    or-int/2addr v6, v7

    .line 319
    aget-byte p2, v2, p2

    and-int/lit16 p2, p2, 0xff

    shl-int/2addr p2, v0

    aget-byte p1, v2, p1

    and-int/lit16 p1, p1, 0xff

    or-int/2addr p1, p2

    .line 320
    invoke-direct {p0, v4, v6}, Lcom/taomee/mole/SocketBridge;->report(Ljava/lang/String;I)V

    .line 321
    if-eq p1, v6, :cond_6

    invoke-direct {p0, v4, p1}, Lcom/taomee/mole/SocketBridge;->report(Ljava/lang/String;I)V

    .line 313
    :cond_6
    :goto_5
    move p1, v5

    goto :goto_4

    .line 325
    :cond_7
    invoke-static {v0, v1}, Ljava/lang/Math;->min(II)I

    move-result p1

    .line 326
    new-array p2, p1, [B

    .line 327
    sub-int/2addr v1, p1

    invoke-static {v2, v1, p2, v3, p1}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 328
    return-object p2
.end method


# virtual methods
.method public getPort()I
    .locals 1

    .line 64
    iget v0, p0, Lcom/taomee/mole/SocketBridge;->port:I

    return v0
.end method

.method public setDiscoveryListener(Lcom/taomee/mole/SocketBridge$DiscoveryListener;)V
    .locals 0

    .line 60
    iput-object p1, p0, Lcom/taomee/mole/SocketBridge;->listener:Lcom/taomee/mole/SocketBridge$DiscoveryListener;

    .line 61
    return-void
.end method

.method public declared-synchronized start()V
    .locals 4

    monitor-enter p0

    .line 68
    :try_start_0
    iget-object v0, p0, Lcom/taomee/mole/SocketBridge;->server:Ljava/net/ServerSocket;
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    if-eqz v0, :cond_0

    monitor-exit p0

    return-void

    .line 70
    :cond_0
    :try_start_1
    new-instance v0, Ljava/net/ServerSocket;

    const-string v1, "127.0.0.1"

    invoke-static {v1}, Ljava/net/InetAddress;->getByName(Ljava/lang/String;)Ljava/net/InetAddress;

    move-result-object v1

    const/4 v2, 0x0

    const/16 v3, 0x18

    invoke-direct {v0, v2, v3, v1}, Ljava/net/ServerSocket;-><init>(IILjava/net/InetAddress;)V

    .line 71
    iput-object v0, p0, Lcom/taomee/mole/SocketBridge;->server:Ljava/net/ServerSocket;

    .line 72
    invoke-virtual {v0}, Ljava/net/ServerSocket;->getLocalPort()I

    move-result v1

    iput v1, p0, Lcom/taomee/mole/SocketBridge;->port:I

    .line 73
    # ===== FIX(S3) 线程池加上限 =====
    # newCachedThreadPool 没有上限：只要有一条连接出现悬挂（见 FIX S1/S2），
    # 线程数就会一路涨到进程被杀。改成固定 24，超出部分排队等待。
    # 正常游玩同时只有 1~3 条 WS 连接，24 足够；万一真有异常，
    # 结果是「新连接排队」而不是「线程爆炸拖垮整个进程」。
    const/16 v1, 0x18

    invoke-static {v1}, Ljava/util/concurrent/Executors;->newFixedThreadPool(I)Ljava/util/concurrent/ExecutorService;

    move-result-object v1

    iput-object v1, p0, Lcom/taomee/mole/SocketBridge;->pool:Ljava/util/concurrent/ExecutorService;

    .line 74
    const-string v1, "MoleSocketBridge"

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u6865\u5df2\u542f\u52a8\uff1a127.0.0.1:"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    iget v3, p0, Lcom/taomee/mole/SocketBridge;->port:I

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-static {v1, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 75
    iget-object v1, p0, Lcom/taomee/mole/SocketBridge;->pool:Ljava/util/concurrent/ExecutorService;

    .line 76
    new-instance v2, Ljava/lang/Thread;

    new-instance v3, Lcom/taomee/mole/SocketBridge$1;

    invoke-direct {v3, p0, v0, v1}, Lcom/taomee/mole/SocketBridge$1;-><init>(Lcom/taomee/mole/SocketBridge;Ljava/net/ServerSocket;Ljava/util/concurrent/ExecutorService;)V

    const-string v0, "mole-ws-accept"

    invoke-direct {v2, v3, v0}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 95
    const/4 v0, 0x1

    invoke-virtual {v2, v0}, Ljava/lang/Thread;->setDaemon(Z)V

    .line 96
    invoke-virtual {v2}, Ljava/lang/Thread;->start()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 99
    goto :goto_0

    .line 97
    :catchall_0
    move-exception v0

    .line 98
    :try_start_2
    const-string v1, "MoleSocketBridge"

    const-string v2, "\u6865\u542f\u52a8\u5931\u8d25 \u2014\u2014 \u767b\u5f55\u4e0e\u8fdb\u5730\u56fe\u4f1a\u5931\u8d25"

    invoke-static {v1, v2, v0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    .line 100
    :goto_0
    monitor-exit p0

    return-void

    .line 67
    :catchall_1
    move-exception v0

    monitor-exit p0

    throw v0
.end method

.method public declared-synchronized stop()V
    .locals 1

    monitor-enter p0

    .line 104
    :try_start_0
    iget-object v0, p0, Lcom/taomee/mole/SocketBridge;->server:Ljava/net/ServerSocket;

    if-eqz v0, :cond_0

    iget-object v0, p0, Lcom/taomee/mole/SocketBridge;->server:Ljava/net/ServerSocket;

    invoke-virtual {v0}, Ljava/net/ServerSocket;->close()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 106
    :cond_0
    goto :goto_0

    .line 105
    :catchall_0
    move-exception v0

    .line 107
    :goto_0
    const/4 v0, 0x0

    :try_start_1
    iput-object v0, p0, Lcom/taomee/mole/SocketBridge;->server:Ljava/net/ServerSocket;

    .line 108
    iget-object v0, p0, Lcom/taomee/mole/SocketBridge;->pool:Ljava/util/concurrent/ExecutorService;

    if-eqz v0, :cond_1

    iget-object v0, p0, Lcom/taomee/mole/SocketBridge;->pool:Ljava/util/concurrent/ExecutorService;

    invoke-interface {v0}, Ljava/util/concurrent/ExecutorService;->shutdownNow()Ljava/util/List;
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 109
    :cond_1
    monitor-exit p0

    return-void

    .line 103
    :catchall_1
    move-exception v0

    monitor-exit p0

    throw v0
.end method
