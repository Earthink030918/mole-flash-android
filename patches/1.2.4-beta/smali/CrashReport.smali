.class public final Lcom/taomee/mole/CrashReport;
.super Ljava/lang/Object;
.source "CrashReport.java"


# direct methods
.method private constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# 1.2.4-beta：崩溃报告落盘 + 调系统分享面板
# 参数：(Context, 文件名, 报告正文)
#   1) 正文写到 getExternalFilesDir("crash")/<name>，免权限、用户可用
#      文件管理器直接取（/sdcard/Android/data/com.taomee.mole/files/crash/）；
#   2) 无论落盘成败，都把正文塞进 ACTION_SEND 的 EXTRA_TEXT 走系统分享，
#      QQ / 微信 / 邮件都能直接收 —— 不依赖 FileProvider，也就不需要
#      额外在清单里声明 provider，改动面更小。
.method public static share(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V
    .locals 7

    if-eqz p0, :end

    if-nez p1, :name_ok

    const-string p1, "mole-crash.txt"

    :name_ok
    if-eqz p2, :do_share

    # ---- 落盘 ----
    :try_start_0
    const/4 v0, 0x0

    invoke-virtual {p0, v0}, Landroid/content/Context;->getExternalFilesDir(Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    if-eqz v0, :do_share

    new-instance v1, Ljava/io/File;

    const-string v2, "crash"

    invoke-direct {v1, v0, v2}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-virtual {v1}, Ljava/io/File;->mkdirs()Z

    new-instance v2, Ljava/io/File;

    invoke-direct {v2, v1, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    new-instance v3, Ljava/io/FileOutputStream;

    invoke-direct {v3, v2}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V

    const-string v4, "UTF-8"

    invoke-virtual {p2, v4}, Ljava/lang/String;->getBytes(Ljava/lang/String;)[B

    move-result-object v4

    invoke-virtual {v3, v4}, Ljava/io/FileOutputStream;->write([B)V

    invoke-virtual {v3}, Ljava/io/FileOutputStream;->close()V

    const-string v4, "MoleShell"

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    const-string v6, "\u5d29\u6e83\u62a5\u544a\u5df2\u843d\u76d8\uff1a"

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v2}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    invoke-static {v4, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    goto :do_share

    :catch_0
    move-exception v0

    const-string v1, "MoleShell"

    const-string v2, "\u5d29\u6e83\u62a5\u544a\u5199\u5165\u5931\u8d25\uff08\u4ecd\u76f4\u63a5\u5206\u4eab\u6587\u672c\uff09"

    invoke-static {v1, v2, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    # ---- 主线程弹分享（后台线程 startActivity 会被系统拒）----
    :do_share
    new-instance v0, Landroid/os/Handler;

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    new-instance v1, Lcom/taomee/mole/CrashReport$1;

    invoke-direct {v1, p0, p1, p2}, Lcom/taomee/mole/CrashReport$1;-><init>(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V

    invoke-virtual {v0, v1}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    :end
    return-void
.end method
