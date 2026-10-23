.class final Lcom/taomee/mole/HttpCache;
.super Ljava/lang/Object;
.source "HttpCache.java"


# static fields
.field private static final MAX_TOTAL:J = 0xc800000L

.field static final SAFE_MEM:I = 0x600000

.field private static final STATIC_EXT:[Ljava/lang/String;

.field private static final TAG:Ljava/lang/String; = "MoleCache"


# instance fields
.field private final dir:Ljava/io/File;

.field private final locks:Ljava/util/concurrent/ConcurrentHashMap;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/concurrent/ConcurrentHashMap<",
            "Ljava/lang/String;",
            "Ljava/lang/Object;",
            ">;"
        }
    .end annotation
.end field


# direct methods
.method static constructor <clinit>()V
    .locals 19

    # ===== FIX(C1) 只剩「二进制大资源」进磁盘缓存，文本类一律不进 =====
    # 现象（群友反馈第 2 条）：「进入金豆商城页面会卡死」，截图里商城框架、
    #   左侧角色、金豆/积分数字、底部分页 1~10 全部正常，**唯独商品列表整片空白**。
    #   这种「骨架在、内容空」正是接口数据被错误缓存的特征。
    #
    # 原逻辑把 ini / xml / js / css / txt / json / cfg 也当作可缓存静态资源，
    # 命中后由 upstream() 以 `public, max-age=604800`（7 天）返回。
    # 但淘米的商城商品列表、活动、公告这类**动态数据**恰好就用 xml/ini 下发，
    # 于是出现两个致命后果：
    #   1. 只要某一次进商城时后端返回了空列表（角色数据尚未就绪、
    #      登录态刚建立、服务端瞬时限流都会导致），这个**空响应就被钉在磁盘上 7 天**，
    #      之后无论重进多少次商城都只有空白列表 —— 用户看到的就是「卡死」。
    #   2. 商城数据永不刷新，买了东西数量不变、换活动还在显示上一期。
    #
    # 修法：只保留真正「大且内容不变」的二进制资源（swf/图片/音频/dat/bin），
    # 文本类统一不缓存 —— 它们体积小，每次直连服务端的开销可以忽略，
    # 而由 WebView 自身的 HTTP 缓存（服务端给了 ETag/Last-Modified）兜底。
    # 这里把文本扩展名改成不可能命中的占位串，等价于从白名单中移除，
    # 但不改动数组结构与寄存器分配，风险最低。
    const-string v17, "~cfg"

    const-string v18, "~ini"

    const-string v0, "swf"

    const-string v1, "~xml"

    const-string v2, "~js"

    const-string v3, "~css"

    const-string v4, "~txt"

    const-string v5, "~json"

    const-string v6, "png"

    const-string v7, "jpg"

    const-string v8, "jpeg"

    const-string v9, "gif"

    const-string v10, "webp"

    const-string v11, "bmp"

    const-string v12, "mp3"

    const-string v13, "wav"

    const-string v14, "ogg"

    const-string v15, "dat"

    const-string v16, "bin"

    filled-new-array/range {v0 .. v18}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lcom/taomee/mole/HttpCache;->STATIC_EXT:[Ljava/lang/String;

    return-void
.end method

.method constructor <init>(Ljava/io/File;)V
    .locals 3

    .line 60
    const-string v0, "MoleCache"

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 57
    new-instance v1, Ljava/util/concurrent/ConcurrentHashMap;

    invoke-direct {v1}, Ljava/util/concurrent/ConcurrentHashMap;-><init>()V

    iput-object v1, p0, Lcom/taomee/mole/HttpCache;->locks:Ljava/util/concurrent/ConcurrentHashMap;

    .line 61
    new-instance v1, Ljava/io/File;

    const-string v2, "upstream"

    invoke-direct {v1, p1, v2}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    iput-object v1, p0, Lcom/taomee/mole/HttpCache;->dir:Ljava/io/File;

    .line 63
    :try_start_0
    iget-object p1, p0, Lcom/taomee/mole/HttpCache;->dir:Ljava/io/File;

    invoke-virtual {p1}, Ljava/io/File;->isDirectory()Z

    move-result p1

    if-nez p1, :cond_0

    iget-object p1, p0, Lcom/taomee/mole/HttpCache;->dir:Ljava/io/File;

    invoke-virtual {p1}, Ljava/io/File;->mkdirs()Z

    move-result p1

    if-nez p1, :cond_0

    .line 64
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u7f13\u5b58\u76ee\u5f55\u521b\u5efa\u5931\u8d25\uff1a"

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    iget-object v1, p0, Lcom/taomee/mole/HttpCache;->dir:Ljava/io/File;

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 68
    :cond_0
    goto :goto_0

    .line 66
    :catchall_0
    move-exception p1

    .line 67
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u7f13\u5b58\u76ee\u5f55\u5f02\u5e38\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 69
    :goto_0
    new-instance p1, Ljava/lang/Thread;

    new-instance v0, Lcom/taomee/mole/HttpCache$1;

    invoke-direct {v0, p0}, Lcom/taomee/mole/HttpCache$1;-><init>(Lcom/taomee/mole/HttpCache;)V

    const-string v1, "mole-cache-trim"

    invoke-direct {p1, v0, v1}, Ljava/lang/Thread;-><init>(Ljava/lang/Runnable;Ljava/lang/String;)V

    .line 75
    const/4 v0, 0x1

    invoke-virtual {p1, v0}, Ljava/lang/Thread;->setDaemon(Z)V

    .line 76
    invoke-virtual {p1}, Ljava/lang/Thread;->start()V

    .line 77
    return-void
.end method

.method static synthetic access$000(Lcom/taomee/mole/HttpCache;)V
    .locals 0

    .line 39
    invoke-direct {p0}, Lcom/taomee/mole/HttpCache;->trim()V

    return-void
.end method

.method static cacheable(Ljava/lang/String;)Z
    .locals 6

    .line 104
    const/4 v0, 0x0

    if-nez p0, :cond_0

    return v0

    .line 105
    :cond_0
    sget-object v1, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, v1}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    .line 106
    const-string v1, "newmisc.taomee.com"

    invoke-virtual {p0, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v1

    if-eqz v1, :cond_1

    return v0

    .line 108
    :cond_1
    nop

    .line 109
    const/16 v1, 0x3f

    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    .line 110
    if-ltz v1, :cond_2

    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    .line 111
    :cond_2
    const/16 v1, 0x23

    invoke-virtual {p0, v1}, Ljava/lang/String;->indexOf(I)I

    move-result v1

    .line 112
    if-ltz v1, :cond_3

    invoke-virtual {p0, v0, v1}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    .line 113
    :cond_3
    const/16 v1, 0x2f

    invoke-virtual {p0, v1}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v1

    .line 114
    const/16 v2, 0x2e

    invoke-virtual {p0, v2}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v2

    .line 115
    if-ltz v2, :cond_7

    if-ge v2, v1, :cond_4

    goto :goto_1

    .line 116
    :cond_4
    const/4 v1, 0x1

    add-int/2addr v2, v1

    invoke-virtual {p0, v2}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    .line 117
    sget-object v2, Lcom/taomee/mole/HttpCache;->STATIC_EXT:[Ljava/lang/String;

    array-length v3, v2

    const/4 v4, 0x0

    :goto_0
    if-ge v4, v3, :cond_6

    aget-object v5, v2, v4

    .line 118
    invoke-virtual {v5, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v5

    if-eqz v5, :cond_5

    return v1

    .line 117
    :cond_5
    add-int/lit8 v4, v4, 0x1

    goto :goto_0

    .line 120
    :cond_6
    return v0

    .line 115
    :cond_7
    :goto_1
    return v0
.end method

.method private fileFor(Ljava/lang/String;)Ljava/io/File;
    .locals 2

    .line 124
    new-instance v0, Ljava/io/File;

    iget-object v1, p0, Lcom/taomee/mole/HttpCache;->dir:Ljava/io/File;

    invoke-static {p1}, Lcom/taomee/mole/HttpCache;->key(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    invoke-direct {v0, v1, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    return-object v0
.end method

.method static key(Ljava/lang/String;)Ljava/lang/String;
    .locals 7

    .line 82
    :try_start_0
    const-string v0, "SHA-1"

    invoke-static {v0}, Ljava/security/MessageDigest;->getInstance(Ljava/lang/String;)Ljava/security/MessageDigest;

    move-result-object v0

    .line 83
    const-string v1, "UTF-8"

    invoke-virtual {p0, v1}, Ljava/lang/String;->getBytes(Ljava/lang/String;)[B

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/security/MessageDigest;->digest([B)[B

    move-result-object v0

    .line 84
    new-instance v1, Ljava/lang/StringBuilder;

    const/16 v2, 0x28

    invoke-direct {v1, v2}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 85
    array-length v2, v0

    const/4 v3, 0x0

    :goto_0
    if-ge v3, v2, :cond_0

    aget-byte v4, v0, v3

    .line 86
    and-int/lit16 v4, v4, 0xff

    .line 87
    ushr-int/lit8 v5, v4, 0x4

    const/16 v6, 0x10

    invoke-static {v5, v6}, Ljava/lang/Character;->forDigit(II)C

    move-result v5

    invoke-virtual {v1, v5}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 88
    and-int/lit8 v4, v4, 0xf

    invoke-static {v4, v6}, Ljava/lang/Character;->forDigit(II)C

    move-result v4

    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 85
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 90
    :cond_0
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-object p0

    .line 91
    :catchall_0
    move-exception v0

    .line 92
    invoke-virtual {p0}, Ljava/lang/String;->hashCode()I

    move-result p0

    invoke-static {p0}, Ljava/lang/Integer;->toHexString(I)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private lockFor(Ljava/lang/String;)Ljava/lang/Object;
    .locals 2

    .line 128
    invoke-static {p1}, Lcom/taomee/mole/HttpCache;->key(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    .line 129
    iget-object v0, p0, Lcom/taomee/mole/HttpCache;->locks:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v0, p1}, Ljava/util/concurrent/ConcurrentHashMap;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    .line 130
    if-eqz v0, :cond_0

    return-object v0

    .line 131
    :cond_0
    new-instance v0, Ljava/lang/Object;

    invoke-direct {v0}, Ljava/lang/Object;-><init>()V

    .line 132
    iget-object v1, p0, Lcom/taomee/mole/HttpCache;->locks:Ljava/util/concurrent/ConcurrentHashMap;

    invoke-virtual {v1, p1, v0}, Ljava/util/concurrent/ConcurrentHashMap;->putIfAbsent(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object p1

    .line 133
    if-eqz p1, :cond_1

    move-object v0, p1

    :cond_1
    return-object v0
.end method

.method private trim()V
    .locals 13

    .line 184
    const-string v0, "MoleCache"

    :try_start_0
    iget-object v1, p0, Lcom/taomee/mole/HttpCache;->dir:Ljava/io/File;

    invoke-virtual {v1}, Ljava/io/File;->listFiles()[Ljava/io/File;

    move-result-object v1

    .line 185
    if-eqz v1, :cond_9

    array-length v2, v1

    if-nez v2, :cond_0

    goto/16 :goto_5

    .line 187
    :cond_0
    nop

    .line 188
    nop

    .line 189
    array-length v2, v1

    const/4 v3, 0x0

    const-wide/16 v4, 0x0

    const/4 v6, 0x0

    const/4 v7, 0x0

    :goto_0
    if-ge v6, v2, :cond_3

    aget-object v8, v1, v6

    .line 190
    invoke-virtual {v8}, Ljava/io/File;->isFile()Z

    move-result v9

    if-nez v9, :cond_1

    goto :goto_1

    .line 191
    :cond_1
    invoke-virtual {v8}, Ljava/io/File;->getName()Ljava/lang/String;

    move-result-object v9

    const-string v10, ".tmp"

    invoke-virtual {v9, v10}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v9

    if-eqz v9, :cond_2

    .line 192
    invoke-virtual {v8}, Ljava/io/File;->delete()Z

    .line 193
    goto :goto_1

    .line 195
    :cond_2
    invoke-virtual {v8}, Ljava/io/File;->length()J

    move-result-wide v8
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    add-long/2addr v4, v8

    .line 196
    add-int/lit8 v7, v7, 0x1

    .line 189
    :goto_1
    add-int/lit8 v6, v6, 0x1

    goto :goto_0

    .line 198
    :cond_3
    const-wide/32 v8, 0xc800000

    const-string v2, " MB"

    const/16 v6, 0x14

    cmp-long v10, v4, v8

    if-gtz v10, :cond_4

    .line 199
    :try_start_1
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u7f13\u5b58\u5df2\u6709 "

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v7}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v3, " \u9879 / "

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    shr-long v3, v4, v6

    invoke-virtual {v1, v3, v4}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 200
    return-void

    .line 203
    :cond_4
    new-instance v7, Lcom/taomee/mole/HttpCache$2;

    invoke-direct {v7, p0}, Lcom/taomee/mole/HttpCache$2;-><init>(Lcom/taomee/mole/HttpCache;)V

    invoke-static {v1, v7}, Ljava/util/Arrays;->sort([Ljava/lang/Object;Ljava/util/Comparator;)V

    .line 210
    nop

    .line 211
    nop

    .line 212
    array-length v7, v1

    move-wide v8, v4

    const/4 v4, 0x0

    :goto_2
    if-ge v3, v7, :cond_8

    aget-object v5, v1, v3

    .line 213
    const-wide/32 v10, 0xa000000

    cmp-long v12, v8, v10

    if-gtz v12, :cond_5

    goto :goto_4

    .line 214
    :cond_5
    invoke-virtual {v5}, Ljava/io/File;->isFile()Z

    move-result v10

    if-nez v10, :cond_6

    goto :goto_3

    .line 215
    :cond_6
    invoke-virtual {v5}, Ljava/io/File;->length()J

    move-result-wide v10

    .line 216
    invoke-virtual {v5}, Ljava/io/File;->delete()Z

    move-result v5

    if-eqz v5, :cond_7

    .line 217
    sub-long/2addr v8, v10

    .line 218
    add-int/lit8 v4, v4, 0x1

    .line 212
    :cond_7
    :goto_3
    add-int/lit8 v3, v3, 0x1

    goto :goto_2

    .line 221
    :cond_8
    :goto_4
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u7f13\u5b58\u8d85\u9650\uff1a\u6dd8\u6c70 "

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v4}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v3, " \u9879\uff0c\u73b0 "

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    shr-long v3, v8, v6

    invoke-virtual {v1, v3, v4}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 224
    goto :goto_6

    .line 185
    :cond_9
    :goto_5
    return-void

    .line 222
    :catchall_0
    move-exception v1

    .line 223
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u7f13\u5b58\u6574\u7406\u5f02\u5e38\uff1a"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 225
    :goto_6
    return-void
.end method


# virtual methods
.method hit(Ljava/lang/String;)Ljava/io/File;
    .locals 5

    .line 139
    :try_start_0
    invoke-direct {p0, p1}, Lcom/taomee/mole/HttpCache;->fileFor(Ljava/lang/String;)Ljava/io/File;

    move-result-object p1

    .line 140
    invoke-virtual {p1}, Ljava/io/File;->isFile()Z

    move-result v0

    if-eqz v0, :cond_0

    invoke-virtual {p1}, Ljava/io/File;->length()J

    move-result-wide v0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    const-wide/16 v2, 0x0

    cmp-long v4, v0, v2

    if-lez v4, :cond_0

    .line 142
    :try_start_1
    invoke-static {}, Ljava/lang/System;->currentTimeMillis()J

    move-result-wide v0

    invoke-virtual {p1, v0, v1}, Ljava/io/File;->setLastModified(J)Z
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 144
    goto :goto_0

    .line 143
    :catchall_0
    move-exception v0

    .line 145
    :goto_0
    return-object p1

    .line 149
    :cond_0
    goto :goto_1

    .line 147
    :catchall_1
    move-exception p1

    .line 148
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u7f13\u5b58\u67e5\u8be2\u5f02\u5e38\uff1a"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string v0, "MoleCache"

    invoke-static {v0, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 150
    :goto_1
    const/4 p1, 0x0

    return-object p1
.end method

.method store(Ljava/lang/String;[B)V
    .locals 5

    .line 155
    if-eqz p2, :cond_3

    array-length v0, p2

    if-eqz v0, :cond_3

    array-length v0, p2

    const/high16 v1, 0x600000

    if-le v0, v1, :cond_0

    goto/16 :goto_4

    .line 156
    :cond_0
    invoke-direct {p0, p1}, Lcom/taomee/mole/HttpCache;->fileFor(Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 157
    invoke-direct {p0, p1}, Lcom/taomee/mole/HttpCache;->lockFor(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object p1

    monitor-enter p1

    .line 158
    :try_start_0
    new-instance v1, Ljava/io/File;

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v0}, Ljava/io/File;->getPath()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v3, ".tmp"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-direct {v1, v2}, Ljava/io/File;-><init>(Ljava/lang/String;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_3

    .line 159
    nop

    .line 161
    const/4 v2, 0x0

    :try_start_1
    new-instance v3, Ljava/io/FileOutputStream;

    invoke-direct {v3, v1}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 162
    :try_start_2
    invoke-virtual {v3, p2}, Ljava/io/OutputStream;->write([B)V

    .line 163
    invoke-virtual {v3}, Ljava/io/OutputStream;->flush()V

    .line 164
    invoke-virtual {v3}, Ljava/io/OutputStream;->close()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    .line 165
    nop

    .line 166
    :try_start_3
    invoke-virtual {v1, v0}, Ljava/io/File;->renameTo(Ljava/io/File;)Z

    move-result p2

    if-nez p2, :cond_1

    .line 167
    invoke-virtual {v0}, Ljava/io/File;->delete()Z

    .line 168
    invoke-virtual {v1, v0}, Ljava/io/File;->renameTo(Ljava/io/File;)Z

    move-result p2

    if-nez p2, :cond_1

    invoke-virtual {v1}, Ljava/io/File;->delete()Z
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    .line 177
    :cond_1
    goto :goto_3

    .line 170
    :catchall_0
    move-exception p2

    move-object v2, v3

    goto :goto_0

    :catchall_1
    move-exception p2

    .line 171
    :goto_0
    :try_start_4
    const-string v0, "MoleCache"

    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "\u7f13\u5b58\u5199\u5165\u5931\u8d25\uff1a"

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-static {v0, p2}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_3

    .line 173
    if-eqz v2, :cond_2

    :try_start_5
    invoke-virtual {v2}, Ljava/io/OutputStream;->close()V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    goto :goto_1

    .line 174
    :catchall_2
    move-exception p2

    goto :goto_2

    .line 175
    :cond_2
    :goto_1
    nop

    .line 176
    :goto_2
    :try_start_6
    invoke-virtual {v1}, Ljava/io/File;->delete()Z

    .line 178
    :goto_3
    monitor-exit p1

    .line 179
    return-void

    .line 178
    :catchall_3
    move-exception p2

    monitor-exit p1
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_3

    throw p2

    .line 155
    :cond_3
    :goto_4
    return-void
.end method
