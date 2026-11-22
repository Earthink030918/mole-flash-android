.class public final Lcom/taomee/mole/AboutDialog;
.super Ljava/lang/Object;
.source "AboutDialog.java"


# 1.2.6-beta：启动时那一屏「关于本作」—— 用系统原生 AlertDialog，
# 不用网页自绘的框。第二段（非官方声明）走 Html.fromHtml 的 <font color>，
# 在系统弹窗里就是真·红字（ForegroundColorSpan），跟随系统深浅色与字体缩放。
#
# 为什么落在这儿而不是 JS 里：
#   · 系统弹窗的按钮、返回键、无障碍朗读都由系统负责，网页自绘做不到；
#   · 是否「只弹一次」记在 SharedPreferences(mole_shell)，
#     用户清 WebView 缓存 / localStorage 之后照样不重复骚扰。
#
# 红线：这个类只读一个布尔值、只弹一个框，不碰 WebView、不碰渲染、不碰预算。
.method private constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# 启动时调用（JS 每轮启动都会问，是否已经弹过由这里判断）。
# 必须在主线程弹窗，而 JS 桥调用落在后台线程 —— 所以统一 post 到主线程。
.method public static showOnce(Landroid/content/Context;)V
    .locals 3

    if-eqz p0, :end

    new-instance v0, Landroid/os/Handler;

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    new-instance v1, Lcom/taomee/mole/AboutDialog$1;

    const/4 v2, 0x0

    invoke-direct {v1, p0, v2}, Lcom/taomee/mole/AboutDialog$1;-><init>(Landroid/content/Context;Z)V

    invoke-virtual {v0, v1}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    :end
    return-void
.end method


# 强制弹一次（崩溃页的「关于本作」按钮，或调试口 __moleAbout.show(true)）
.method public static showForce(Landroid/content/Context;)V
    .locals 3

    if-eqz p0, :end

    new-instance v0, Landroid/os/Handler;

    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    new-instance v1, Lcom/taomee/mole/AboutDialog$1;

    const/4 v2, 0x1

    invoke-direct {v1, p0, v2}, Lcom/taomee/mole/AboutDialog$1;-><init>(Landroid/content/Context;Z)V

    invoke-virtual {v0, v1}, Landroid/os/Handler;->post(Ljava/lang/Runnable;)Z

    :end
    return-void
.end method


# 真正建框。只允许在主线程调用。
.method public static show(Landroid/content/Context;)V
    .locals 4

    if-eqz p0, :end

    :try_start_0
    new-instance v0, Landroid/app/AlertDialog$Builder;

    invoke-direct {v0, p0}, Landroid/app/AlertDialog$Builder;-><init>(Landroid/content/Context;)V

    const-string v1, "\u5173\u4e8e\u672c\u4f5c \u00b7 \u5148\u8bf4\u4e09\u53e5\u5fc3\u91cc\u8bdd"

    invoke-virtual {v0, v1}, Landroid/app/AlertDialog$Builder;->setTitle(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;

    const-string v1, "\u8c22\u8c22\u4f60\u9009\u62e9\u4e86\u6211\u8fd9\u4e48\u4e00\u4e2a\u5c0f\u5c0f\u7684\u5f00\u6e90\u9879\u76ee\uff5e\u80fd\u5728\u8fd9\u91cc\u9047\u89c1\u4f60\uff0c\u771f\u7684\u5f88\u5f00\u5fc3\uff01\u2661<br><br><font color='#E23A3A'>\u5c0f\u63d0\u9192\u4e00\u4e0b\uff1a\u672c\u4f5c\u5e76\u975e\u6469\u5c14\u5e84\u56ed\u5b98\u65b9\u9879\u76ee\uff0c\u4ec5\u4e3a\u7b2c\u4e09\u65b9\u7231\u597d\u8005\u79fb\u690d\uff0c\u8bf7\u4e0d\u8981\u548c\u5b98\u65b9\u7248\u672c\u7684\u300a\u6469\u5c14\u5e84\u56ed\u300b\u624b\u6e38\u6df7\u6dc6\u54e6\uff01\uff01\uff01</font><br><br>\u672c\u4f5c\u76ee\u524d\u8fd8\u5728\u5f00\u53d1\u9636\u6bb5\uff0c\u9047\u5230\u95ee\u9898\u6b22\u8fce\u968f\u65f6\u6307\u51fa\uff5e\u53e6\u5916\u90d1\u91cd\u8bf4\u4e00\u53e5\uff1a\u4e25\u7981\u5012\u5356\uff0c\u4e5f\u4e25\u7981\u5728\u4e8c\u6b21\u4fee\u6539\u65f6\u52a0\u5165\u6536\u8d39\u5f39\u7a97\uff1b\u5982\u679c\u53d1\u73b0\u4efb\u4f55\u4ee5\u6b64\u76c8\u5229\u7684\u884c\u4e3a\uff0c\u6b22\u8fce\u5927\u5bb6\u5411\u6211\u53cd\u9988\uff01"

    invoke-static {v1}, Landroid/text/Html;->fromHtml(Ljava/lang/String;)Landroid/text/Spanned;

    move-result-object v1

    invoke-virtual {v0, v1}, Landroid/app/AlertDialog$Builder;->setMessage(Ljava/lang/CharSequence;)Landroid/app/AlertDialog$Builder;

    const-string v1, "\u6211\u77e5\u9053\u5566 \u2661"

    const/4 v2, 0x0

    invoke-virtual {v0, v1, v2}, Landroid/app/AlertDialog$Builder;->setPositiveButton(Ljava/lang/CharSequence;Landroid/content/DialogInterface$OnClickListener;)Landroid/app/AlertDialog$Builder;

    invoke-virtual {v0}, Landroid/app/AlertDialog$Builder;->create()Landroid/app/AlertDialog;

    move-result-object v0

    invoke-virtual {v0}, Landroid/app/AlertDialog;->show()V

    const-string v1, "MoleShell"

    const-string v2, "关于本作弹窗已显示"

    invoke-static {v1, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v0

    const-string v1, "MoleShell"

    const-string v2, "关于本作弹窗显示失败"

    invoke-static {v1, v2, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    :end
    return-void
.end method
