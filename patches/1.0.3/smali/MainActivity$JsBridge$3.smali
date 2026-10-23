.class Lcom/taomee/mole/MainActivity$JsBridge$3;
.super Ljava/lang/Object;
.source "MainActivity.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lcom/taomee/mole/MainActivity$JsBridge;->onGpuExhausted(Ljava/lang/String;)V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic this$1:Lcom/taomee/mole/MainActivity$JsBridge;

.field final synthetic val$dead:Z


# direct methods
.method constructor <init>(Lcom/taomee/mole/MainActivity$JsBridge;Z)V
    .locals 0
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "()V"
        }
    .end annotation

    .line 1462
    iput-object p1, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->this$1:Lcom/taomee/mole/MainActivity$JsBridge;

    iput-boolean p2, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->val$dead:Z

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 3

    .line 1465
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->this$1:Lcom/taomee/mole/MainActivity$JsBridge;

    iget-object v0, v0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$900(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebView;

    move-result-object v0

    if-nez v0, :cond_0

    return-void

    .line 1466
    :cond_0
    iget-boolean v0, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->val$dead:Z

    if-nez v0, :cond_1

    # ===== FIX(P3) 上下文丢失：只做无损回收，不降档 =====
    # 原逻辑 lost → raiseLoadLevel(+1)：既动了画质，又在上下文已经半死的
    # 时候再抖一次容器尺寸，反而加重抖动。丢失但还没死的时候，
    # 唯一该做的事是把纹理池清一遍，让驱动把内存还回来。
    # 传 30s 冷却 —— lost 是紧急信号，允许比常规水位触发更勤。
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->this$1:Lcom/taomee/mole/MainActivity$JsBridge;

    iget-object v0, v0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$900(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebView;

    move-result-object v0

    if-eqz v0, :cond_p3

    const-string v1, "try{window.__molePurgeTex&&window.__molePurgeTex(30000)}catch(e){}"

    const/4 v2, 0x0

    invoke-virtual {v0, v1, v2}, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String;Landroid/webkit/ValueCallback;)V

    :cond_p3
    .line 1470
    return-void

    .line 1472
    :cond_1
    # ===== FIX(P4) 上下文 2.5s 未恢复：保留重载兜底，但不再降档 =====
    # 原来这里先把 loadLevel 顶到 MAX_LEVEL 再 reload，而 reload 之后
    # evaluateLoadLevel() 会从 SharedPreferences 读回 boot_crashes_v4，
    # 于是「这次救急降的档」被永久写死 —— 用户看到的就是画质越来越糊，
    # 而且再也回升不了。救一次急的代价不该是画质永久降级。
    # 现在只 reload（上限 8 次），档位完全交给崩溃历史独立判定。

    .line 1473
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->this$1:Lcom/taomee/mole/MainActivity$JsBridge;

    iget-object v0, v0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$2000(Lcom/taomee/mole/MainActivity;)I

    move-result v0

    const/16 v1, 0x8

    const-string v2, "MoleShell"

    if-lt v0, v1, :cond_2

    .line 1474
    const-string v0, "\u81ea\u52a8\u6062\u590d\u5df2\u8fbe\u4e0a\u9650\uff0c\u4fdd\u6301\u5f53\u524d\u753b\u9762\u4e0d\u518d\u91cd\u8f7d"

    invoke-static {v2, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 1475
    return-void

    .line 1477
    :cond_2
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->this$1:Lcom/taomee/mole/MainActivity$JsBridge;

    iget-object v0, v0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$2008(Lcom/taomee/mole/MainActivity;)I

    .line 1478
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u56e0 GPU \u4e0a\u4e0b\u6587\u672a\u6062\u590d\u800c\u91cd\u8f7d\uff08\u7b2c "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget-object v1, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->this$1:Lcom/taomee/mole/MainActivity$JsBridge;

    iget-object v1, v1, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v1}, Lcom/taomee/mole/MainActivity;->access$2000(Lcom/taomee/mole/MainActivity;)I

    move-result v1

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " \u6b21\uff09"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v2, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 1479
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$JsBridge$3;->this$1:Lcom/taomee/mole/MainActivity$JsBridge;

    iget-object v0, v0, Lcom/taomee/mole/MainActivity$JsBridge;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$900(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebView;

    move-result-object v0

    invoke-virtual {v0}, Landroid/webkit/WebView;->reload()V

    .line 1480
    return-void
.end method
