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

    # ===== FIX(A1) 排除系统手势区，救回屏幕边缘的触摸 =====
    # 针对：一加全系平板 / ColorOS 17 / 红米 K90（HyperOS）等全面屏手势机型。
    # 现象：游戏里贴着屏幕左右边缘的按钮（背包、地图、商城侧栏、贴边 NPC）
    #   点不动，或者要点好几次才中 —— 用户描述为「触控逻辑混乱」。
    # 原因：Android 10 起系统在手势导航模式下会**优先拦截**屏幕左右边缘
    #   （默认约 20dp）与底部边缘的触摸，用于「返回 / 回桌面」。
    #   这部分事件根本不会送到 WebView，Ruffle 自然也收不到，
    #   属于壳层必须主动申请豁免的部分，跟 Ruffle 的输入映射无关。
    # 修法：把左右各 3% 宽度报给系统作为「手势排除区」
    #   （系统上限每边 200dp，3% 远低于此，不会影响用户滑动返回）。
    #   只在 API 29+ 调用；低版本没有该机制，直接跳过。
    # 全程不涉及帧率、画质、画幅。
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x1d

    if-lt v0, v1, :a1_done

    invoke-virtual {p1}, Landroid/webkit/WebView;->getWidth()I

    move-result v0

    invoke-virtual {p1}, Landroid/webkit/WebView;->getHeight()I

    move-result v1

    if-lez v0, :a1_done

    if-lez v1, :a1_done

    mul-int/lit8 v2, v0, 0x3

    div-int/lit8 v2, v2, 0x64

    if-lez v2, :a1_done

    new-instance v3, Ljava/util/ArrayList;

    const/4 v4, 0x2

    invoke-direct {v3, v4}, Ljava/util/ArrayList;-><init>(I)V

    const/4 v5, 0x0

    new-instance v4, Landroid/graphics/Rect;

    invoke-direct {v4, v5, v5, v2, v1}, Landroid/graphics/Rect;-><init>(IIII)V

    invoke-virtual {v3, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    sub-int v2, v0, v2

    new-instance v4, Landroid/graphics/Rect;

    invoke-direct {v4, v2, v5, v0, v1}, Landroid/graphics/Rect;-><init>(IIII)V

    invoke-virtual {v3, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    invoke-virtual {p1, v3}, Landroid/webkit/WebView;->setSystemGestureExclusionRects(Ljava/util/List;)V

    :a1_done
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
