.class public final Lcom/taomee/mole/CrashReport;
.super Ljava/lang/Object;
.source "CrashReport.java"


.method private constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# 1.2.4-beta：崩溃报告落盘（只写文件，不弹任何东西）
# 1.2.6-beta：从 share() 里拆出来 —— 崩溃页出现时先静默存一份底，
#            用户即使直接杀进程 / 点「重新进入」不再分享，现场也还在。
# 路径：/sdcard/Android/data/com.taomee.mole/files/crash/<name>（免权限）
# 返回：true = 写成功
.method public static save(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)Z
    .locals 6

    const/4 v0, 0x0

    if-eqz p0, :ret

    if-nez p1, :ret

    if-nez p2, :ret

    :try_start_0
    const/4 v1, 0x0

    invoke-virtual {p0, v1}, Landroid/content/Context;->getExternalFilesDir(Ljava/lang/String;)Ljava/io/File;

    move-result-object v1

    if-eqz v1, :ret

    new-instance v2, Ljava/io/File;

    const-string v3, "crash"

    invoke-direct {v2, v1, v3}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    invoke-virtual {v2}, Ljava/io/File;->mkdirs()Z

    new-instance v3, Ljava/io/File;

    invoke-direct {v3, v2, p1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V

    new-instance v4, Ljava/io/FileOutputStream;

    invoke-direct {v4, v3}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V

    const-string v5, "UTF-8"

    invoke-virtual {p2, v5}, Ljava/lang/String;->getBytes(Ljava/lang/String;)[B

    move-result-object v5

    invoke-virtual {v4, v5}, Ljava/io/FileOutputStream;->write([B)V

    invoke-virtual {v4}, Ljava/io/FileOutputStream;->close()V

    const/4 v0, 0x1

    const-string v4, "MoleShell"

    const-string v5, "\u5d29\u6e83\u62a5\u544a\u5df2\u843d\u76d8\uff1a"

    invoke-static {v4, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    invoke-virtual {v3}, Ljava/io/File;->getAbsolutePath()Ljava/lang/String;

    move-result-object v4

    const-string v5, "MoleShell"

    invoke-static {v5, v4}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    goto :ret

    :catch_0
    move-exception v1

    const-string v2, "MoleShell"

    const-string v3, "\u5d29\u6e83\u62a5\u544a\u5199\u5165\u5931\u8d25\uff08\u4ecd\u7ee7\u7eed\u5206\u4eab\u6587\u672c\uff09"

    invoke-static {v2, v3, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    const/4 v0, 0x0

    :ret
    return v0
.end method


# 落盘 + 调系统分享（ACTION_SEND + createChooser），选 QQ 即可发到群里。
# 不依赖 FileProvider：正文直接塞 EXTRA_TEXT，附件不是必需的。
.method public static share(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V
    .locals 3

    if-eqz p0, :end

    if-nez p1, :name_ok

    const-string p1, "mole-crash.txt"

    :name_ok
    if-nez p2, :end

    invoke-static {p0, p1, p2}, Lcom/taomee/mole/CrashReport;->save(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)Z

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
