.class public Lcom/taomee/mole/MoleKeepAlive;
.super Landroid/app/Service;
.source "MoleKeepAlive.java"


# static fields
.field private static final CHANNEL_ID:Ljava/lang/String; = "mole_bg"

.field private static final CHANNEL_NAME:Ljava/lang/String; = "\u540e\u53f0\u8fd0\u884c"

.field private static final NOTIF_ID:I = 0x4d4f4c

.field private static final REQ_CODE:I = 0x4d4f


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
    const v1, 0x7f010000

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

    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x1a

    if-ge v0, v1, :cond_done

    const-string v0, "notification"

    invoke-virtual {p0, v0}, Lcom/taomee/mole/MoleKeepAlive;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/app/NotificationManager;

    if-nez v0, :cond_have

    return-void

    :cond_have
    new-instance v1, Landroid/app/NotificationChannel;

    const-string v2, "mole_bg"

    const-string v3, "\u540e\u53f0\u8fd0\u884c"

    const/4 v4, 0x2

    invoke-direct {v1, v2, v3, v4}, Landroid/app/NotificationChannel;-><init>(Ljava/lang/String;Ljava/lang/CharSequence;I)V

    invoke-virtual {v0, v1}, Landroid/app/NotificationManager;->createNotificationChannel(Landroid/app/NotificationChannel;)V

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
    .locals 3

    # START_NOT_STICKY：进程真被杀了就别再复活。
    # 用 START_STICKY 的话，Activity 已经没了，系统还会把服务拉起来，
    # 于是留下一条永远消不掉的通知（僵尸前台服务）。
    const/4 v0, 0x2

    :try_start_0
    invoke-direct {p0}, Lcom/taomee/mole/MoleKeepAlive;->ensureChannel()V

    invoke-direct {p0}, Lcom/taomee/mole/MoleKeepAlive;->buildNotification()Landroid/app/Notification;

    move-result-object v1

    const v2, 0x4d4f4c

    invoke-virtual {p0, v2, v1}, Landroid/app/Service;->startForeground(ILandroid/app/Notification;)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception v1

    :goto_0
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
