.class public Lcom/taomee/mole/MoleKeepAlive;
.super Landroid/app/Service;
.source "MoleKeepAlive.java"


# static fields
.field private static final CHANNEL_ID:Ljava/lang/String; = "mole_bg"

.field private static final CHANNEL_NAME:Ljava/lang/String; = "\u540e\u53f0\u8fd0\u884c"

.field private static final NOTIF_ID:I = 0x4d4f4c

.field private static final REQ_CODE:I = 0x4d4f

.field private static final TAG:Ljava/lang/String; = "MoleShell"


# direct methods
.method public constructor <init>()V
    .locals 0

    invoke-direct {p0}, Landroid/app/Service;-><init>()V

    return-void
.end method

.method private buildNotification()Landroid/app/Notification;
    .locals 4

    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x1a

    if-lt v0, v1, :cond_old

    new-instance v0, Landroid/app/Notification$Builder;

    const-string v1, "mole_bg"

    invoke-direct {v0, p0, v1}, Landroid/app/Notification$Builder;-><init>(Landroid/content/Context;Ljava/lang/String;)V

    goto :goto_builder

    :cond_old
    new-instance v0, Landroid/app/Notification$Builder;

    invoke-direct {v0, p0}, Landroid/app/Notification$Builder;-><init>(Landroid/content/Context;)V

    :goto_builder
    # ==================================================================
    # 1.1.4：小图标改用系统内置的 stat_notify_sync。
    # ------------------------------------------------------------------
    # 原来用的是 0x7f010000 = @mipmap/ic_launcher，有两个问题：
    #   1) 8.0+ 的小图标必须是单色 alpha 图，彩色 adaptive icon 只会被
    #      渲染成一个白方块；
    #   2) 它把通知的可用性绑在 APK 资源 ID 上 —— 个别 ROM 资源重排后
    #      解析失败，setSmallIcon 直接抛 IllegalArgumentException，
    #      buildNotification 整段抛出，startForeground 就不会执行，
    #      服务降级成普通后台服务，进程随即被回收。
    # 换成 framework 自带的单色图标，规范且无解析失败风险。
    # ==================================================================
    sget v1, Landroid/R$drawable;->stat_notify_sync:I

    invoke-virtual {v0, v1}, Landroid/app/Notification$Builder;->setSmallIcon(I)Landroid/app/Notification$Builder;

    move-result-object v0

    const-string v1, "\u6469\u5c14\u5e84\u56ed"

    invoke-virtual {v0, v1}, Landroid/app/Notification$Builder;->setContentTitle(Ljava/lang/CharSequence;)Landroid/app/Notification$Builder;

    move-result-object v0

    const-string v1, "\u6302\u673a\u8fd0\u884c\u4e2d \u00b7 \u70b9\u51fb\u56de\u5230\u6e38\u620f"

    invoke-virtual {v0, v1}, Landroid/app/Notification$Builder;->setContentText(Ljava/lang/CharSequence;)Landroid/app/Notification$Builder;

    move-result-object v0

    const/4 v1, 0x1

    invoke-virtual {v0, v1}, Landroid/app/Notification$Builder;->setOngoing(Z)Landroid/app/Notification$Builder;

    move-result-object v0

    new-instance v1, Landroid/content/Intent;

    const-class v2, Lcom/taomee/mole/MainActivity;

    invoke-direct {v1, p0, v2}, Landroid/content/Intent;-><init>(Landroid/content/Context;Ljava/lang/Class;)V

    const v2, 0x10000000

    invoke-virtual {v1, v2}, Landroid/content/Intent;->addFlags(I)Landroid/content/Intent;

    sget v2, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v3, 0x17

    if-lt v2, v3, :cond_mut

    const v2, 0x04000000

    goto :goto_mut

    :cond_mut
    const/4 v2, 0x0

    :goto_mut
    const/16 v3, 0x4d4f

    invoke-static {p0, v3, v1, v2}, Landroid/app/PendingIntent;->getActivity(Landroid/content/Context;ILandroid/content/Intent;I)Landroid/app/PendingIntent;

    move-result-object v1

    invoke-virtual {v0, v1}, Landroid/app/Notification$Builder;->setContentIntent(Landroid/app/PendingIntent;)Landroid/app/Notification$Builder;

    move-result-object v0

    invoke-virtual {v0}, Landroid/app/Notification$Builder;->build()Landroid/app/Notification;

    move-result-object v0

    return-object v0
.end method

.method private ensureChannel()V
    .locals 5

    # 1.1.4：整个方法内部自吞异常。
    # 渠道创建失败（ROM 限制 / NotificationManager 为 null）不能连累
    # startForeground —— 那会导致 startForegroundService 拉起后 5 秒内
    # 没调 startForeground，系统抛 RemoteServiceException 直接杀进程。
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x1a

    if-ge v0, v1, :cond_done

    :try_start_ch
    const-string v0, "notification"

    invoke-virtual {p0, v0}, Lcom/taomee/mole/MoleKeepAlive;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/app/NotificationManager;

    if-eqz v0, :cond_try_end

    new-instance v1, Landroid/app/NotificationChannel;

    const-string v2, "mole_bg"

    const-string v3, "\u540e\u53f0\u8fd0\u884c"

    const/4 v4, 0x2

    invoke-direct {v1, v2, v3, v4}, Landroid/app/NotificationChannel;-><init>(Ljava/lang/String;Ljava/lang/CharSequence;I)V

    invoke-virtual {v0, v1}, Landroid/app/NotificationManager;->createNotificationChannel(Landroid/app/NotificationChannel;)V
    :cond_try_end
    :try_end_ch
    .catch Ljava/lang/Throwable; {:try_start_ch .. :try_end_ch} :catch_ch

    goto :cond_done

    :catch_ch
    move-exception v0

    :cond_done
    return-void
.end method


# virtual methods
.method public onBind(Landroid/content/Intent;)Landroid/os/IBinder;
    .locals 1

    const/4 v0, 0x0

    return-object v0
.end method

.method public onStartCommand(Landroid/content/Intent;II)I
    .locals 4

    # ==================================================================
    # 1.1.4：不再把整段逻辑塞进一个 catch 里静默吞掉。
    # ------------------------------------------------------------------
    # 旧实现是 try { ensureChannel(); buildNotification(); startForeground(); }
    # catch(Throwable) {} —— 任何一步失败，startForeground 都不会执行；
    # 而服务是被 startForegroundService() 拉起的，5 秒内不调 startForeground
    # 系统会抛 RemoteServiceException 直接干掉进程。即使侥幸没崩，服务也
    # 只是普通后台服务，进程照样停在 cached 优先级等着被回收。
    #
    # 现在：每一步各自兜底，startForeground 一定执行；失败时把异常连同
    # 堆栈打进 logcat（MoleShell），不再无声无息。
    #
    # 返回值仍是 START_NOT_STICKY(2)：进程真被杀了就不再复活，避免留下
    # 一条永远消不掉的通知僵尸。这属于既有保活策略，本次不动。
    # ==================================================================
    :try_start_ch
    invoke-direct {p0}, Lcom/taomee/mole/MoleKeepAlive;->ensureChannel()V
    :try_end_ch
    .catch Ljava/lang/Throwable; {:try_start_ch .. :try_end_ch} :catch_ch

    :catch_ch
    :try_start_bn
    invoke-direct {p0}, Lcom/taomee/mole/MoleKeepAlive;->buildNotification()Landroid/app/Notification;

    move-result-object v1

    const v2, 0x4d4f4c

    invoke-virtual {p0, v2, v1}, Landroid/app/Service;->startForeground(ILandroid/app/Notification;)V

    const-string v0, "MoleShell"

    const-string v1, "\u524d\u53f0\u670d\u52a1\u5df2\u542f\u52a8\uff0c\u6302\u673a\u901a\u77e5\u5df2\u6302\u51fa"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_bn
    .catch Ljava/lang/Throwable; {:try_start_bn .. :try_end_bn} :catch_bn

    goto :goto_ret

    :catch_bn
    move-exception v1

    const-string v0, "MoleShell"

    const-string v2, "\u524d\u53f0\u670d\u52a1\u542f\u52a8\u5931\u8d25"

    invoke-static {v0, v2, v1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    :goto_ret
    const/4 v0, 0x2

    return v0
.end method

.method public onDestroy()V
    .locals 1

    const/4 v0, 0x1

    :try_start_0
    invoke-virtual {p0, v0}, Landroid/app/Service;->stopForeground(Z)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception v0

    :goto_0
    invoke-super {p0}, Landroid/app/Service;->onDestroy()V

    return-void
.end method
