.class Lcom/taomee/mole/MainActivity$6;
.super Landroid/webkit/WebViewClient;
.source "MainActivity.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lcom/taomee/mole/MainActivity;->configure()V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic this$0:Lcom/taomee/mole/MainActivity;


# direct methods
.method constructor <init>(Lcom/taomee/mole/MainActivity;)V
    .locals 0

    .line 838
    iput-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-direct {p0}, Landroid/webkit/WebViewClient;-><init>()V

    return-void
.end method


# virtual methods
.method public onPageFinished(Landroid/webkit/WebView;Ljava/lang/String;)V
    .locals 6

    .line 881
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "\u2713 \u9875\u9762\u5c31\u7eea\uff1a"

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string p2, "MoleShell"

    invoke-static {p2, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 886
    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {p1}, Lcom/taomee/mole/MainActivity;->access$1200(Lcom/taomee/mole/MainActivity;)V

    .line 887
    return-void
.end method

.method public onPageStarted(Landroid/webkit/WebView;Ljava/lang/String;Landroid/graphics/Bitmap;)V
    .locals 0

    .line 876
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string p3, "\u2192 "

    invoke-virtual {p1, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string p2, "MoleShell"

    invoke-static {p2, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 877
    return-void
.end method

.method public onReceivedError(Landroid/webkit/WebView;Landroid/webkit/WebResourceRequest;Landroid/webkit/WebResourceError;)V
    .locals 1

    .line 892
    if-eqz p2, :cond_0

    invoke-interface {p2}, Landroid/webkit/WebResourceRequest;->isForMainFrame()Z

    move-result p1

    if-eqz p1, :cond_0

    .line 893
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "\u4e3b\u9875\u52a0\u8f7d\u5931\u8d25\uff1a"

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-interface {p2}, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;

    move-result-object p2

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string p2, " code="

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    .line 894
    invoke-virtual {p3}, Landroid/webkit/WebResourceError;->getErrorCode()I

    move-result p2

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string p2, " desc="

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p3}, Landroid/webkit/WebResourceError;->getDescription()Ljava/lang/CharSequence;

    move-result-object p2

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 893
    const-string p2, "MoleShell"

    invoke-static {p2, p1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 896
    :cond_0
    return-void
.end method

.method public shouldInterceptRequest(Landroid/webkit/WebView;Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
    .locals 5

    .line 843
    const-string p1, "core.ruffle."

    const/4 v0, 0x0

    :try_start_0
    invoke-interface {p2}, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;

    move-result-object v1

    invoke-virtual {v1}, Landroid/net/Uri;->toString()Ljava/lang/String;

    move-result-object v1

    .line 844
    invoke-static {v1}, Lcom/taomee/mole/MainActivity;->access$1300(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v2

    .line 847
    const-string v3, "/__mole_shell__"

    invoke-virtual {v1, v3}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_0

    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {p1}, Lcom/taomee/mole/MainActivity;->access$1400(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebResourceResponse;

    move-result-object p1

    return-object p1

    .line 850
    :cond_0
    const-string v3, "/fonts/"

    invoke-virtual {v1, v3}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result v1

    if-eqz v1, :cond_1

    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {p1, v2}, Lcom/taomee/mole/MainActivity;->access$1500(Lcom/taomee/mole/MainActivity;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p1

    return-object p1

    .line 853
    :cond_1
    const-string v1, "__mole_ruffle__.js"

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    const-string v3, "application/javascript"

    if-eqz v1, :cond_2

    :try_start_1
    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    const-string p2, "ruffle/ruffle.js"

    invoke-static {p1, p2, v3}, Lcom/taomee/mole/MainActivity;->access$1600(Lcom/taomee/mole/MainActivity;Ljava/lang/String;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p1

    return-object p1

    .line 854
    :cond_2
    const-string v1, "__mole_boot__.js"

    invoke-virtual {v1, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v1

    if-eqz v1, :cond_3

    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    const-string p2, "ruffle/mole_boot.js"

    invoke-static {p1, p2, v3}, Lcom/taomee/mole/MainActivity;->access$1600(Lcom/taomee/mole/MainActivity;Ljava/lang/String;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p1

    return-object p1

    .line 855
    :cond_3
    invoke-virtual {v2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    const-string v4, "ruffle/"

    if-eqz v1, :cond_4

    :try_start_2
    const-string v1, ".js"

    invoke-virtual {v2, v1}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_4

    .line 856
    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {p2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    invoke-static {p1, p2, v3}, Lcom/taomee/mole/MainActivity;->access$1600(Lcom/taomee/mole/MainActivity;Ljava/lang/String;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p1

    return-object p1

    .line 857
    :cond_4
    invoke-virtual {v2, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p1

    if-eqz p1, :cond_5

    const-string p1, ".js.map"

    invoke-virtual {v2, p1}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p1

    if-eqz p1, :cond_5

    .line 858
    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {p2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p2

    const-string v1, "application/json"

    invoke-static {p1, p2, v1}, Lcom/taomee/mole/MainActivity;->access$1600(Lcom/taomee/mole/MainActivity;Ljava/lang/String;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p1

    return-object p1

    .line 859
    :cond_5
    const-string p1, ".wasm"

    invoke-virtual {v2, p1}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p1

    if-eqz p1, :cond_6

    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {p1, v2}, Lcom/taomee/mole/MainActivity;->access$1700(Lcom/taomee/mole/MainActivity;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p1

    return-object p1

    .line 863
    :cond_6
    invoke-interface {p2}, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;

    move-result-object p1

    invoke-virtual {p1}, Landroid/net/Uri;->getHost()Ljava/lang/String;

    move-result-object p1

    .line 864
    if-nez p1, :cond_7

    return-object v0

    .line 865
    :cond_7
    const-string v1, "GET"

    invoke-interface {p2}, Landroid/webkit/WebResourceRequest;->getMethod()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v1, v2}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_8

    invoke-static {p1}, Lcom/taomee/mole/MainActivity;->access$1800(Ljava/lang/String;)Z

    move-result p1

    if-eqz p1, :cond_8

    .line 866
    iget-object p1, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {p1, p2}, Lcom/taomee/mole/MainActivity;->access$1900(Lcom/taomee/mole/MainActivity;Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;

    move-result-object p1
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    return-object p1

    .line 870
    :cond_8
    goto :goto_0

    .line 868
    :catchall_0
    move-exception p1

    .line 869
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u62e6\u622a\u5904\u7406\u5f02\u5e38\uff1a"

    invoke-virtual {p2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string p2, "MoleShell"

    invoke-static {p2, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 871
    :goto_0
    return-object v0
.end method

# ======================================================================
# 1.1.3 新增：渲染进程被系统回收 / 崩溃
# ----------------------------------------------------------------------
# 不实现这个方法时，WebView 的默认行为是 Process.killProcess(myPid())
# —— 整个 App 无声消失，连崩溃弹窗都没有。这就是「切到后台以后软件
# 自动死了、切回前台自动重启」的真正机制：后台被冻结的渲染进程是
# 系统内存回收的头号目标，被回收后 App 跟着一起被杀，任务残留在最近
# 任务里，再点回来就是系统重建 Activity。
#
# 返回 true = 我来善后，别杀进程。真正的重建交给 MainActivity.onRendererGone()。
# ======================================================================
.method public onRenderProcessGone(Landroid/webkit/WebView;Landroid/webkit/RenderProcessGoneDetail;)Z
    .locals 4

    const-string v0, "MoleShell"

    :try_start_rpg_log
    new-instance v1, Ljava/lang/StringBuilder;

    const-string v2, "\u6e32\u67d3\u8fdb\u7a0b\u5df2\u6d88\u5931\uff08didCrash="

    invoke-direct {v1, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    invoke-virtual {p2}, Landroid/webkit/RenderProcessGoneDetail;->didCrash()Z

    move-result v2

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "\uff0c\u9000\u51fa\u65f6\u4f18\u5148\u7ea7="

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {p2}, Landroid/webkit/RenderProcessGoneDetail;->rendererPriorityAtExit()I

    move-result v2

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "\uff09\u2192 \u62a5\u544a\u4e0d\u6740\u8fdb\u7a0b"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_rpg_log
    .catch Ljava/lang/Throwable; {:try_start_rpg_log .. :try_end_rpg_log} :catch_rpg_log

    goto :goto_rpg_mark

    :catch_rpg_log
    move-exception v1

    :goto_rpg_mark
    :try_start_rpg_mark
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$6;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-virtual {v0}, Lcom/taomee/mole/MainActivity;->onRendererGone()V
    :try_end_rpg_mark
    .catch Ljava/lang/Throwable; {:try_start_rpg_mark .. :try_end_rpg_mark} :catch_rpg_mark

    goto :goto_rpg_ret

    :catch_rpg_mark
    move-exception v0

    :goto_rpg_ret
    const/4 v0, 0x1

    return v0
.end method
