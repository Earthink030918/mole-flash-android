.class public Lcom/taomee/mole/MoleKeepAlive;
.super Landroid/app/Service;
.source "MoleKeepAlive.java"


# static fields
.field private static final CHANNEL_ID:Ljava/lang/String; = "mole_bg_v2"

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

    const-string v1, "mole_bg_v2"

    invoke-direct {v0, p0, v1}, Landroid/app/Notification$Builder;-><init>(Landroid/content/Context;Ljava/lang/String;)V

    goto :goto_builder

    :cond_old
    new-instance v0, Landroid/app/Notification$Builder;

    invoke-direct {v0, p0}, Landroid/app/Notification$Builder;-><init>(Landroid/content/Context;)V

    :goto_builder
    # 小图标用 framework 自带的单色图标：8.0+ 要求小图标必须是单色
    # alpha 图，彩色 launcher 图标只会渲染成白方块；而且它不依赖 APK
    # 自己的资源 ID，不存在个别 ROM 上解析失败导致整段构造抛出的问题。
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

    # 整个方法内部自吞异常：渠道建失败不能连累 startForeground，
    # 否则 startForegroundService 拉起后 5 秒内没调 startForeground，
    # 系统会抛 RemoteServiceException 直接干掉进程。
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x1a

    if-ge v0, v1, :cond_done

    :try_start_ch
    const-string v0, "notification"

    invoke-virtual {p0, v0}, Lcom/taomee/mole/MoleKeepAlive;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Landroid/app/NotificationManager;

    if-eqz v0, :cond_try_end

    # 1.1.5：渠道 ID 从 mole_bg 换成 mole_bg_v2。
    # Android 的渠道一旦建过，后续代码改 importance 不会生效（只有
    # 用户能改），而 1.1.2 建的是 IMPORTANCE_LOW —— 部分 ROM 会把
    # LOW 渠道折叠进「静默通知 / 其他通知」，用户根本看不到。换新 ID
    # 并提到 IMPORTANCE_DEFAULT，保证通知一定出现在通知栏。
    new-instance v1, Landroid/app/NotificationChannel;

    const-string v2, "mole_bg_v2"

    const-string v3, "\u540e\u53f0\u8fd0\u884c"

    const/4 v4, 0x3

    invoke-direct {v1, v2, v3, v4}, Landroid/app/NotificationChannel;-><init>(Ljava/lang/String;Ljava/lang/CharSequence;I)V

    const-string v2, "\u5207\u5230\u540e\u53f0\u65f6\u4fdd\u6301\u6e38\u620f\u8fdb\u7a0b\u5b58\u6d3b"

    invoke-virtual {v1, v2}, Landroid/app/NotificationChannel;->setDescription(Ljava/lang/String;)V

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

.method public onCreate()V
    .locals 2

    # 服务类被成功实例化就会打这一行。logcat 里看不到它，
    # 就说明服务压根没起来（类加载失败 / 服务没被 start），
    # 而不是 startForeground 失败。
    invoke-super {p0}, Landroid/app/Service;->onCreate()V

    const-string v0, "MoleShell"

    const-string v1, "\u4fdd\u6d3b\u670d\u52a1\u5df2\u521b\u5efa"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    return-void
.end method

.method public onStartCommand(Landroid/content/Intent;II)I
    .locals 5

    # ==================================================================
    # 1.1.5
    # ------------------------------------------------------------------
    # 1.1.4 在这里踩了一个致命的形式错误：外层那个
    #   try { ensureChannel(); } catch (Throwable) {}
    # 生成的 catch handler 入口不是 move-exception（因为 handler 里不
    # 需要异常对象，我没写）。dex 规范要求 catch handler 入口必须是
    # move-exception，ART 的类验证会因此直接拒绝这个类 —— 服务加载
    # 不起来，Activity 侧 startForegroundService 抛的异常又被
    # catch(Throwable) 吞掉，外部表现就是「通知永远不出现、切后台照样
    # 被杀」。
    #
    # 现在：ensureChannel 内部已自行兜底，这里不再包外层 try；
    # 只保留 startForeground 这一段，catch handler 以 move-exception
    # 开头，并打印完整堆栈。
    # ==================================================================
    invoke-direct {p0}, Lcom/taomee/mole/MoleKeepAlive;->ensureChannel()V

    :try_start_fg
    invoke-direct {p0}, Lcom/taomee/mole/MoleKeepAlive;->buildNotification()Landroid/app/Notification;

    move-result-object v1

    const v2, 0x4d4f4c

    # API 29 起用三参版本，显式指定 foregroundServiceType =
    # FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK(2)。两参版本依赖清单里
    # 声明的类型，个别 ROM 上会抛 MissingForegroundServiceTypeException。
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v3, 0x1d

    if-lt v0, v3, :cond_fg_two

    const/4 v3, 0x2

    invoke-virtual {p0, v2, v1, v3}, Landroid/app/Service;->startForeground(ILandroid/app/Notification;I)V

    goto :fg_done

    :cond_fg_two
    invoke-virtual {p0, v2, v1}, Landroid/app/Service;->startForeground(ILandroid/app/Notification;)V

    :fg_done
    const-string v0, "MoleShell"

    const-string v1, "\u524d\u53f0\u670d\u52a1\u5df2\u542f\u52a8\uff0c\u6302\u673a\u901a\u77e5\u5df2\u6302\u51fa"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_fg
    .catch Ljava/lang/Throwable; {:try_start_fg .. :try_end_fg} :catch_fg

    goto :fg_ret

    :catch_fg
    move-exception v1

    const-string v0, "MoleShell"

    const-string v2, "\u524d\u53f0\u670d\u52a1\u542f\u52a8\u5931\u8d25"

    invoke-static {v0, v2, v1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    :fg_ret
    # START_NOT_STICKY(2)：进程真被杀了就不再复活，避免留下一条永远
    # 消不掉的通知僵尸。既有保活策略，本次不动。
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
