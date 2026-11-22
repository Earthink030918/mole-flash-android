.class Lcom/taomee/mole/MainActivity$JsBridge;
.super Ljava/lang/Object;
.source "MainActivity.java"


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lcom/taomee/mole/MainActivity;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x2
    name = "JsBridge"
.end annotation


# instance fields
.field final synthetic this$0:Lcom/taomee/mole/MainActivity;


# direct methods
.method private constructor <init>(Lcom/taomee/mole/MainActivity;)V
    .locals 0

    .line 1395
    iput-object p1, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method synthetic constructor <init>(Lcom/taomee/mole/MainActivity;Lcom/taomee/mole/MainActivity$1;)V
    .locals 0

    .line 1395
    invoke-direct {p0, p1}, Lcom/taomee/mole/MainActivity$JsBridge;-><init>(Lcom/taomee/mole/MainActivity;)V

    return-void
.end method


# virtual methods
.method public bridgePort()I
    .locals 1
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    .line 1413
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$2100(Lcom/taomee/mole/MainActivity;)Lcom/taomee/mole/SocketBridge;

    move-result-object v0

    if-nez v0, :cond_0

    const/4 v0, 0x0

    goto :goto_0

    :cond_0
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$2100(Lcom/taomee/mole/MainActivity;)Lcom/taomee/mole/SocketBridge;

    move-result-object v0

    invoke-virtual {v0}, Lcom/taomee/mole/SocketBridge;->getPort()I

    move-result v0

    :goto_0
    return v0
.end method

.method public log(Ljava/lang/String;)V
    .locals 2
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    .line 1398
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "[js] "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string v0, "MoleShell"

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 1399
    return-void
.end method

.method public onGpuExhausted(Ljava/lang/String;)V
    .locals 3
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    .line 1459
    const-string v0, "dead"

    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    .line 1460
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u9875\u9762\u62a5\u544a GPU \u4e0a\u4e0b\u6587\u5f02\u5e38\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    .line 1461
    if-eqz v0, :cond_0

    const-string v1, "\uff082.5s \u672a\u6062\u590d \u2192 \u91cd\u8f7d\uff09"

    goto :goto_0

    :cond_0
    const-string v1, "\uff08\u5148\u964d\u4e00\u6863\u89c2\u5bdf\uff09"

    :goto_0
    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 1460
    const-string v1, "MoleShell"

    invoke-static {v1, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 1462
    iget-object p1, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    new-instance v1, Lcom/taomee/mole/MainActivity$JsBridge$3;

    invoke-direct {v1, p0, v0}, Lcom/taomee/mole/MainActivity$JsBridge$3;-><init>(Lcom/taomee/mole/MainActivity$JsBridge;Z)V

    invoke-virtual {p1, v1}, Lcom/taomee/mole/MainActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 1482
    return-void
.end method

.method public onMissingProxy(Ljava/lang/String;I)V
    .locals 1
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    .line 1423
    if-eqz p1, :cond_0

    :try_start_0
    invoke-virtual {p1}, Ljava/lang/String;->isEmpty()Z

    move-result v0

    if-nez v0, :cond_0

    if-lez p2, :cond_0

    const v0, 0xffff

    if-gt p2, v0, :cond_0

    .line 1424
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0, p1, p2}, Lcom/taomee/mole/MainActivity;->access$2200(Lcom/taomee/mole/MainActivity;Ljava/lang/String;I)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    goto :goto_0

    .line 1426
    :catchall_0
    move-exception p1

    .line 1427
    new-instance p2, Ljava/lang/StringBuilder;

    invoke-direct {p2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v0, "\u8865\u5f55\u5931\u8d25\uff1a"

    invoke-virtual {p2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p2

    invoke-virtual {p2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string p2, "MoleShell"

    invoke-static {p2, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    goto :goto_1

    .line 1428
    :cond_0
    :goto_0
    nop

    .line 1429
    :goto_1
    return-void
.end method

.method public onPanic()V
    .locals 2
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    .line 1448
    const-string v0, "MoleShell"

    const-string v1, "\u9875\u9762\u62a5\u544a Ruffle panic \u2192 \u5f3a\u5236\u6e05\u7a7a\u91cd\u8f7d"

    invoke-static {v0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 1449
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    new-instance v1, Lcom/taomee/mole/MainActivity$JsBridge$2;

    invoke-direct {v1, p0}, Lcom/taomee/mole/MainActivity$JsBridge$2;-><init>(Lcom/taomee/mole/MainActivity$JsBridge;)V

    invoke-virtual {v0, v1}, Lcom/taomee/mole/MainActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 1455
    return-void
.end method

.method public toast(Ljava/lang/String;)V
    .locals 2
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    .line 1403
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    new-instance v1, Lcom/taomee/mole/MainActivity$JsBridge$1;

    invoke-direct {v1, p0, p1}, Lcom/taomee/mole/MainActivity$JsBridge$1;-><init>(Lcom/taomee/mole/MainActivity$JsBridge;Ljava/lang/String;)V

    invoke-virtual {v0, v1}, Lcom/taomee/mole/MainActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 1409
    return-void
.end method

.method public reportCrash(Ljava/lang/String;Ljava/lang/String;)V
    .locals 3
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    :try_start_0
    if-nez p1, :p1_ok

    const-string p1, "mole-crash.txt"

    :p1_ok
    const-string v0, "MoleShell"

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "[js] \u53d7\u7406\u5d29\u6e83\u62a5\u544a\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0, p1, p2}, Lcom/taomee/mole/CrashReport;->share(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v0

    const-string v1, "MoleShell"

    const-string v2, "\u5d29\u6e83\u62a5\u544a\u5904\u7406\u5f02\u5e38"

    invoke-static {v1, v2, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method

.method public saveCrash(Ljava/lang/String;Ljava/lang/String;)V
    .locals 3
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    # 1.2.6-beta：只落盘、不弹分享。崩溃页出现时先静默存一份底。
    :try_start_0
    if-nez p1, :p1_ok

    const-string p1, "mole-crash.txt"

    :p1_ok
    const-string v0, "MoleShell"

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u9759\u9ed8\u843d\u76d8\u5d29\u6e83\u62a5\u544a\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0, p1, p2}, Lcom/taomee/mole/CrashReport;->save(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)Z
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v0

    const-string v1, "MoleShell"

    const-string v2, "\u9759\u9ed8\u843d\u76d8\u5d29\u6e83\u62a5\u544a\u5f02\u5e38"

    invoke-static {v1, v2, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method


.method public showAbout(Z)V
    .locals 3
    .annotation runtime Landroid/webkit/JavascriptInterface;
    .end annotation

    # 1.2.6-beta：关于本作 → 交给系统原生 AlertDialog。
    # p1 = force（true 忽略「只弹一次」，崩溃页的按钮用）
    :try_start_0
    const-string v0, "MoleShell"

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "[js] \u5173\u4e8e\u672c\u4f5c\u5f39\u7a97\uff0cforce="

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Z)Ljava/lang/StringBuilder;

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    if-eqz p1, :once

    invoke-static {v0}, Lcom/taomee/mole/AboutDialog;->showForce(Landroid/content/Context;)V

    return-void

    :once
    invoke-static {v0}, Lcom/taomee/mole/AboutDialog;->showOnce(Landroid/content/Context;)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    return-void

    :catch_0
    move-exception v0

    const-string v1, "MoleShell"

    const-string v2, "\u5173\u4e8e\u672c\u4f5c\u5f39\u7a97\u8c03\u7528\u5f02\u5e38"

    invoke-static {v1, v2, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    return-void
.end method
