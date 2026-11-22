.class Lcom/taomee/mole/AboutDialog$1;
.super Ljava/lang/Object;
.source "AboutDialog.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingClass;
    value = Lcom/taomee/mole/AboutDialog;
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic val$ctx:Landroid/content/Context;

.field final synthetic val$force:Z


# direct methods
.method constructor <init>(Landroid/content/Context;Z)V
    .locals 0

    iput-object p1, p0, Lcom/taomee/mole/AboutDialog$1;->val$ctx:Landroid/content/Context;

    iput-boolean p2, p0, Lcom/taomee/mole/AboutDialog$1;->val$force:Z

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 4

    iget-boolean v0, p0, Lcom/taomee/mole/AboutDialog$1;->val$force:Z

    if-nez v0, :after

    # 已弹过就不弹；读失败就按「没弹过」处理，宁可多弹一次也别让人看不到声明。
    :try_start_0
    iget-object v1, p0, Lcom/taomee/mole/AboutDialog$1;->val$ctx:Landroid/content/Context;

    if-eqz v1, :after

    const-string v2, "mole_shell"

    const/4 v3, 0x0

    invoke-virtual {v1, v2, v3}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v1

    const-string v2, "mole_about_v1"

    invoke-interface {v1, v2, v3}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z

    move-result v2

    if-eqz v2, :after

    invoke-interface {v1}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    const-string v2, "mole_about_v1"

    const/4 v3, 0x1

    invoke-interface {v1, v2, v3}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;

    move-result-object v1

    invoke-interface {v1}, Landroid/content/SharedPreferences$Editor;->apply()V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    goto :after

    :catch_0
    move-exception v1

    const-string v2, "MoleShell"

    const-string v3, "\u5173\u4e8e\u5f39\u7a97\u504f\u597d\u8bfb\u5199\u5931\u8d25\uff08\u4ecd\u7ee7\u7eed\u5f39\uff09"

    invoke-static {v2, v3, v1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    :after
    iget-object v1, p0, Lcom/taomee/mole/AboutDialog$1;->val$ctx:Landroid/content/Context;

    invoke-static {v1}, Lcom/taomee/mole/AboutDialog;->show(Landroid/content/Context;)V

    return-void
.end method
