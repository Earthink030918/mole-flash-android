.class Lcom/taomee/mole/MainActivity$7;
.super Ljava/lang/Object;
.source "MainActivity.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lcom/taomee/mole/MainActivity;->learnMissingProxy(Ljava/lang/String;I)V
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

    .line 959
    iput-object p1, p0, Lcom/taomee/mole/MainActivity$7;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 3

    .line 962
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$7;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$900(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebView;

    move-result-object v0

    if-nez v0, :cond_0

    return-void

    .line 963
    :cond_0
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$7;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$2000(Lcom/taomee/mole/MainActivity;)I

    move-result v0

    const/16 v1, 0x8

    const-string v2, "MoleShell"

    if-lt v0, v1, :cond_1

    .line 964
    const-string v0, "\u81ea\u52a8\u70ed\u91cd\u542f\u6b21\u6570\u5df2\u8fbe\u4e0a\u9650\uff0c\u8bf7\u624b\u52a8\u91cd\u542f\u5e94\u7528"

    invoke-static {v2, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 965
    return-void

    .line 967
    :cond_1
    iget-object v0, p0, Lcom/taomee/mole/MainActivity$7;->this$0:Lcom/taomee/mole/MainActivity;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->access$2008(Lcom/taomee/mole/MainActivity;)I

    .line 968
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u9759\u9ed8\u70ed\u91cd\u542f\u4ee5\u5e94\u7528\u65b0\u7684 socketProxy\uff08\u7b2c "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget-object v1, p0, Lcom/taomee/mole/MainActivity$7;->this$0:Lcom/taomee/mole/MainActivity;

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

    .line 969
    # ===== FIX(G2) 补录端口后不再静默热重启 =====
    # 原逻辑：web.reload() —— 每发现一个「缺失代理」的端口就整页重载一次，
    #   最多 8 次。而 onMissingProxy 在换场景、进商城、开小游戏时都会触发，
    #   于是用户正玩着就被「静默重启」一下（回到登录/加载画面），
    #   在商城里重载还会叠加一次全量资源拉取 —— 直接表现为「进商城卡死」。
    #   这也是群友反馈第 1 条「隔一段时间整个 APP 自动重启」的第二条来源。
    # 修法：只落盘 + 留在内存 targets 里，**下次正常启动时自然生效**。
    #   现有 SEED 端口池已覆盖 1860-1880 / 3195-3215 / 6650-6700 及常用端口，
    #   补录属于极少数兜底场景，绝不值得为它重载整个游戏。
    const-string v0, "\u5df2\u8bb0\u5f55\u7f3a\u5931\u7aef\u53e3\uff0c\u4e0b\u6b21\u542f\u52a8\u751f\u6548\uff08\u4e0d\u518d\u70ed\u91cd\u542f\uff09"

    invoke-static {v2, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 970
    return-void
.end method
