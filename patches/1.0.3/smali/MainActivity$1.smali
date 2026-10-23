.class Lcom/taomee/mole/MainActivity$1;
.super Ljava/lang/Object;
.source "MainActivity.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lcom/taomee/mole/MainActivity;
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

    .line 349
    iput-object p1, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 10

    .line 352
    const-string v0, "MoleShell"

    iget-object v1, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v1}, Lcom/taomee/mole/MainActivity;->access$000(Lcom/taomee/mole/MainActivity;)Z

    move-result v1

    if-nez v1, :cond_0

    return-void

    .line 353
    :cond_0
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide v1

    .line 354
    nop

    .line 356
    :try_start_0
    iget-object v3, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v3}, Lcom/taomee/mole/MainActivity;->access$100(Lcom/taomee/mole/MainActivity;)I

    move-result v3
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 359
    goto :goto_0

    .line 357
    :catchall_0
    move-exception v3

    .line 358
    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "GPU \u91c7\u96c6\u5f02\u5e38\uff1a"

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-static {v0, v3}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    const/4 v3, -0x1

    .line 360
    :goto_0
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide v4

    sub-long/2addr v4, v1

    .line 362
    if-lez v3, :cond_4

    .line 363
    nop

    .line 364
    const/16 v1, 0x19a

    const/4 v2, 0x0

    const-string v6, "GPU \u663e\u5b58 "

    const/4 v7, 0x1

    if-lt v3, v1, :cond_1

    .line 365
    nop

    .line 366
    new-instance v8, Ljava/lang/StringBuilder;

    invoke-direct {v8}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v8, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v8

    invoke-virtual {v8, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v8

    const-string v9, " MB \u8d8a\u8fc7\u91ca\u653e\u95f8 "

    invoke-virtual {v8, v9}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v8

    invoke-virtual {v8, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v8, " \u2192 \u65e0\u635f\u7eb9\u7406\u56de\u6536\uff08\u4e0d\u91cd\u8f7d/\u4e0d\u964d\u753b\u8d28\uff09"

    invoke-virtual {v1, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 368
    # ===== FIX(G1) 显存越硬闸：只降档，不再整页重载 =====
    # 原逻辑：access$200(activity, false) → releaseTextures(false)
    #   → 主线程 loadUrl("about:blank")，2 秒后再 loadUrl(壳页)。
    #   整个 SWF 会从头再来一遍，用户看到的就是「APP 自己重启了」，
    #   而且人还在场景里时会被强制踢回登录/首页 —— 这是群友反馈第 1 条的主因。
    #   真机上这条路径还会被反复触发：重载后纹理重新堆积，很快又越闸，
    #   于是进入「越闸 → 重载 → 再堆积 → 再越闸」的循环。
    # 修法：越硬闸时只把渲染预算降一档（__moleSetBudget，就地生效、不掉线），
    #   把归还纹理这件事交给 Ruffle 重建 canvas 自己完成。
    #   真正的异常场景（页面 panic / GPU 上下文丢失）仍走 releaseTextures 强制重载，
    #   那条路在 JsBridge 里，不受此处影响。
    # ===== FIX(P1) 越硬闸：改为「无损纹理回收」，不再降档 =====
    # 1.0.2 这里曾改成 raiseLoadLevel(loadLevel+1)，靠降分辨率换显存。两个问题：
    #   ① 降的是像素预算，等于偷偷改画质（用户明令不许动画面/画质）；
    #   ② 档位有上限（MAX_LEVEL=5），到顶之后越闸就**什么都不做**，
    #      显存一路涨到驱动分配不出来 —— 画面冻死，进程却不崩、ANR 也抓不到。
    #   群友这次报的「为了不重启，跑久了直接卡死」正是这条。
    # 现在改成调壳层的 __molePurgeTex()：预算不变、画质不变、帧率不变，
    # 只让 Ruffle 重建一次渲染目标，把 wgpu 纹理池里已失效的位图显存还给驱动。
    # 频率由 JS 侧统一兜底（默认 4 分钟一次），避免闸位抖动时反复重建。
    iget-object v1, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v1}, Lcom/taomee/mole/MainActivity;->access$900(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebView;

    move-result-object v8

    if-eqz v8, :cond_p1

    const-string v9, "try{window.__molePurgeTex&&window.__molePurgeTex()}catch(e){}"

    const/4 v1, 0x0

    invoke-virtual {v8, v9, v1}, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String;Landroid/webkit/ValueCallback;)V

    :cond_p1
    const/4 v2, 0x1

    goto :goto_1

    .line 369
    :cond_1
    const/16 v1, 0x190

    if-lt v3, v1, :cond_2

    iget-object v8, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v8}, Lcom/taomee/mole/MainActivity;->access$300(Lcom/taomee/mole/MainActivity;)I

    move-result v8

    const/4 v9, 0x2

    if-ge v8, v9, :cond_2

    .line 370
    nop

    .line 371
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v2, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v8, " MB \u8d8a\u8fc7\u8f6f\u95f8 "

    invoke-virtual {v2, v8}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, " \u2192 \u65e0\u635f\u7eb9\u7406\u56de\u6536"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 372
    # ===== FIX(P2) 越软闸：同样只做无损回收，不提前降画质 =====
    # 软闸（400MB）的意义是「还没到危险线，先动手」，而不是「先降一档画质」。
    # 之前这里也是 raiseLoadLevel，等于让画质随显存波动被反复下调，
    # 用户能直接看出画面变糊。现在只触发纹理回收。
    iget-object v1, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v1}, Lcom/taomee/mole/MainActivity;->access$900(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebView;

    move-result-object v8

    if-eqz v8, :cond_p2

    const-string v9, "try{window.__molePurgeTex&&window.__molePurgeTex()}catch(e){}"

    const/4 v1, 0x0

    invoke-virtual {v8, v9, v1}, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String;Landroid/webkit/ValueCallback;)V

    :cond_p2
    const/4 v2, 0x1

    .line 375
    :cond_2
    :goto_1
    if-nez v2, :cond_3

    iget-object v1, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v1}, Lcom/taomee/mole/MainActivity;->access$508(Lcom/taomee/mole/MainActivity;)I

    move-result v1

    and-int/lit8 v1, v1, 0x3

    if-nez v1, :cond_4

    .line 376
    :cond_3
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v1, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, " MB\uff08\u6863 "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    iget-object v2, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v2}, Lcom/taomee/mole/MainActivity;->access$300(Lcom/taomee/mole/MainActivity;)I

    move-result v2

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "\uff0c\u9884\u7b97 "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    iget-object v2, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    .line 377
    invoke-static {v2}, Lcom/taomee/mole/MainActivity;->access$600(Lcom/taomee/mole/MainActivity;)I

    move-result v2

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, " px\uff0c\u91c7\u96c6\u8017\u65f6 "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v4, v5}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "ms\uff09"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    .line 376
    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 382
    :cond_4
    const-wide/16 v1, 0x5dc

    const-wide/16 v6, 0x2

    cmp-long v8, v4, v1

    if-lez v8, :cond_5

    .line 383
    iget-object v1, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    iget-object v2, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v2}, Lcom/taomee/mole/MainActivity;->access$700(Lcom/taomee/mole/MainActivity;)J

    move-result-wide v8

    mul-long v8, v8, v6

    const-wide/32 v6, 0xea60

    invoke-static {v8, v9, v6, v7}, Ljava/lang/Math;->min(JJ)J

    move-result-wide v6

    invoke-static {v1, v6, v7}, Lcom/taomee/mole/MainActivity;->access$702(Lcom/taomee/mole/MainActivity;J)J

    .line 384
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "GPU \u91c7\u96c6\u8017\u65f6 "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v4, v5}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "ms\uff0c\u95f4\u9694\u9000\u907f\u5230 "

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    iget-object v2, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v2}, Lcom/taomee/mole/MainActivity;->access$700(Lcom/taomee/mole/MainActivity;)J

    move-result-wide v4

    invoke-virtual {v1, v4, v5}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v2, "ms"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    goto :goto_2

    .line 385
    :cond_5
    const-wide/16 v0, 0xc8

    cmp-long v2, v4, v0

    if-gez v2, :cond_6

    iget-object v0, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$700(Lcom/taomee/mole/MainActivity;)J

    move-result-wide v0

    const-wide/16 v4, 0x1f40

    cmp-long v2, v0, v4

    if-lez v2, :cond_6

    .line 386
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    iget-object v1, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v1}, Lcom/taomee/mole/MainActivity;->access$700(Lcom/taomee/mole/MainActivity;)J

    move-result-wide v1

    div-long/2addr v1, v6

    invoke-static {v1, v2, v4, v5}, Ljava/lang/Math;->max(JJ)J

    move-result-wide v1

    invoke-static {v0, v1, v2}, Lcom/taomee/mole/MainActivity;->access$702(Lcom/taomee/mole/MainActivity;J)J

    .line 389
    :cond_6
    :goto_2
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$000(Lcom/taomee/mole/MainActivity;)Z

    move-result v0

    if-eqz v0, :cond_8

    iget-object v0, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$800(Lcom/taomee/mole/MainActivity;)Landroid/os/Handler;

    move-result-object v0

    if-eqz v0, :cond_8

    .line 392
    if-lez v3, :cond_7

    const/16 v0, 0x15e

    if-lt v3, v0, :cond_7

    const-wide/16 v0, 0xbb8

    goto :goto_3

    :cond_7
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$700(Lcom/taomee/mole/MainActivity;)J

    move-result-wide v0

    .line 393
    :goto_3
    iget-object v2, p0, Lcom/taomee/mole/MainActivity$1;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v2}, Lcom/taomee/mole/MainActivity;->access$800(Lcom/taomee/mole/MainActivity;)Landroid/os/Handler;

    move-result-object v2

    invoke-virtual {v2, p0, v0, v1}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    .line 395
    :cond_8
    return-void
.end method
