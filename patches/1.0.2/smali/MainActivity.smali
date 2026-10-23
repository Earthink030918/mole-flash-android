.class public Lcom/taomee/mole/MainActivity;
.super Landroid/app/Activity;
.source "MainActivity.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lcom/taomee/mole/MainActivity$JsBridge;
    }
.end annotation


# static fields
.field private static final BLUR_JS:Ljava/lang/String; = "(function(){try{var n=document.querySelectorAll(\'ruffle-player,ruffle-object,ruffle-embed\');for(var i=0;i<n.length;i++){try{n[i].pause&&n[i].pause();}catch(e){}}window.dispatchEvent(new Event(\'blur\'));}catch(e){}})();"

.field private static final CACHE_HEADER:Ljava/lang/String; = "public, max-age=604800"

.field private static final CJK_FONT_CANDIDATES:[Ljava/lang/String;

.field private static final CORE_PREFIX:Ljava/lang/String; = "core.ruffle."

.field private static final DIAG_HUD:Z = false

.field private static final FONT_SOURCES:[Ljava/lang/String;

.field private static final GPU_POLL_MAX_MS:J = 0xea60L

.field private static final GPU_POLL_MIN_MS:J = 0x1f40L

.field private static final GPU_RELEASE_MB:I = 0x19a

.field private static final GPU_SOFT_MB:I = 0x190

.field private static final KEY_CRASHES:Ljava/lang/String; = "boot_crashes_v4"

.field private static final KEY_GOOD_RUNS:Ljava/lang/String; = "boot_good_runs_v4"

.field private static final KEY_RUNNING:Ljava/lang/String; = "boot_running_v1"

.field private static final KEY_TARGETS:Ljava/lang/String; = "socket_targets_v2"

.field private static final LATIN_FONT_CANDIDATES:[Ljava/lang/String;

.field private static final LATIN_NAMES:[Ljava/lang/String;

.field private static final MAX_AUTO_RELOADS:I = 0x8

.field private static final MAX_LEVEL:I

.field private static final MAX_RELEASES:I = 0xa

.field private static final PIXEL_BUDGETS:[I

.field private static final PREF:Ljava/lang/String; = "mole_shell"

.field private static final P_BOOT:Ljava/lang/String; = "__mole_boot__.js"

.field private static final P_RUFFLE:Ljava/lang/String; = "__mole_ruffle__.js"

.field private static final RELEASE_COOLDOWN_MS:J = 0x1d4c0L

.field private static final SEED_HOSTS_ENC:[Ljava/lang/String;

.field private static final SEED_PORTS:[I

.field private static final SHELL_PATH:Ljava/lang/String; = "/__mole_shell__"

.field private static final SOFT_LEVEL_CAP:I = 0x2

.field private static final STABLE_AFTER_MS:J = 0x493e0L

.field private static final START_URL:Ljava/lang/String; = "http://mole.61.com/__mole_shell__"

.field private static final TAG:Ljava/lang/String; = "MoleShell"


# instance fields
.field private autoReloads:I

.field private bridge:Lcom/taomee/mole/SocketBridge;

.field private cache:Lcom/taomee/mole/HttpCache;

.field private volatile cjkFontPath:Ljava/lang/String;

.field private volatile fontsResolved:Z

.field private gpuHandler:Landroid/os/Handler;

.field private volatile gpuPollMs:J

.field private gpuThread:Landroid/os/HandlerThread;

.field private gpuTicks:I

.field private final gpuWatch:Ljava/lang/Runnable;

.field private volatile gpuWatchOn:Z

.field private lastReleaseAt:J

.field private volatile latinFontPath:Ljava/lang/String;

.field private volatile loadLevel:I

.field private releaseCount:I

.field private volatile releasing:Z

.field private final targets:Ljava/util/LinkedHashSet;
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "Ljava/util/LinkedHashSet<",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation
.end field

.field private ua:Ljava/lang/String;

.field private web:Landroid/webkit/WebView;


# direct methods
.method static constructor <clinit>()V
    .locals 13

    .line 106
    const-string v5, "/system/fonts/NotoSansSC-Regular.otf"

    const-string v6, "/system/fonts/NotoSansCJKsc-Regular.otf"

    const-string v0, "/system/fonts/NotoSansCJK-Regular.ttc"

    const-string v1, "/system/fonts/DroidSansFallbackBBK.ttf"

    const-string v2, "/system/fonts/DroidSansFallbackMonster.ttf"

    const-string v3, "/system/fonts/DroidSansFallbackFull.ttf"

    const-string v4, "/system/fonts/DroidSansFallback.ttf"

    filled-new-array/range {v0 .. v6}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lcom/taomee/mole/MainActivity;->CJK_FONT_CANDIDATES:[Ljava/lang/String;

    .line 115
    const-string v0, "/system/fonts/NotoSans-Regular.ttf"

    const-string v1, "/system/fonts/DroidSans.ttf"

    const-string v2, "/system/fonts/Roboto-Regular.ttf"

    filled-new-array {v2, v0, v1}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lcom/taomee/mole/MainActivity;->LATIN_FONT_CANDIDATES:[Ljava/lang/String;

    .line 121
    const-string v11, "couriernew"

    const-string v12, "consolas"

    const-string v1, "arial"

    const-string v2, "tahoma"

    const-string v3, "verdana"

    const-string v4, "helvetica"

    const-string v5, "calibri"

    const-string v6, "segoeui"

    const-string v7, "times"

    const-string v8, "timesnewroman"

    const-string v9, "georgia"

    const-string v10, "courier"

    filled-new-array/range {v1 .. v12}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lcom/taomee/mole/MainActivity;->LATIN_NAMES:[Ljava/lang/String;

    .line 143
    const/4 v0, 0x0

    new-array v0, v0, [Ljava/lang/String;

    sput-object v0, Lcom/taomee/mole/MainActivity;->FONT_SOURCES:[Ljava/lang/String;

    .line 158
    const-string v0, "a2hpdGhqbHRraWt0bGk="

    const-string v1, "a2hpdGtvanRrbGl0a2ti"

    const-string v2, "a2hpdGhqbHRraWt0aGls"

    filled-new-array {v2, v0, v1}, [Ljava/lang/String;

    move-result-object v0

    sput-object v0, Lcom/taomee/mole/MainActivity;->SEED_HOSTS_ENC:[Ljava/lang/String;

    .line 174
    invoke-static {}, Lcom/taomee/mole/MainActivity;->buildSeedPorts()[I

    move-result-object v0

    sput-object v0, Lcom/taomee/mole/MainActivity;->SEED_PORTS:[I

    .line 272
    const/4 v0, 0x6

    new-array v0, v0, [I

    fill-array-data v0, :array_0

    sput-object v0, Lcom/taomee/mole/MainActivity;->PIXEL_BUDGETS:[I

    .line 284
    sget-object v0, Lcom/taomee/mole/MainActivity;->PIXEL_BUDGETS:[I

    array-length v0, v0

    add-int/lit8 v0, v0, -0x1

    sput v0, Lcom/taomee/mole/MainActivity;->MAX_LEVEL:I

    return-void

    nop

    :array_0
    .array-data 4
        0x127690
        0xdbba0
        0xa1220
        0x704e0
        0x4e200
        0x33450
    .end array-data
.end method

.method public constructor <init>()V
    .locals 3

    .line 67
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V

    .line 196
    new-instance v0, Ljava/util/LinkedHashSet;

    invoke-direct {v0}, Ljava/util/LinkedHashSet;-><init>()V

    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    .line 199
    const/4 v0, 0x0

    iput v0, p0, Lcom/taomee/mole/MainActivity;->autoReloads:I

    .line 212
    const-string v1, "Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"

    iput-object v1, p0, Lcom/taomee/mole/MainActivity;->ua:Ljava/lang/String;

    .line 282
    iput v0, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    .line 327
    const-wide/16 v1, 0x1f40

    iput-wide v1, p0, Lcom/taomee/mole/MainActivity;->gpuPollMs:J

    .line 328
    iput v0, p0, Lcom/taomee/mole/MainActivity;->gpuTicks:I

    .line 349
    new-instance v1, Lcom/taomee/mole/MainActivity$1;

    invoke-direct {v1, p0}, Lcom/taomee/mole/MainActivity$1;-><init>(Lcom/taomee/mole/MainActivity;)V

    iput-object v1, p0, Lcom/taomee/mole/MainActivity;->gpuWatch:Ljava/lang/Runnable;

    .line 422
    const-wide/16 v1, 0x0

    iput-wide v1, p0, Lcom/taomee/mole/MainActivity;->lastReleaseAt:J

    .line 423
    iput v0, p0, Lcom/taomee/mole/MainActivity;->releaseCount:I

    return-void
.end method

.method static synthetic access$000(Lcom/taomee/mole/MainActivity;)Z
    .locals 0

    .line 67
    iget-boolean p0, p0, Lcom/taomee/mole/MainActivity;->gpuWatchOn:Z

    return p0
.end method

.method static synthetic access$100(Lcom/taomee/mole/MainActivity;)I
    .locals 0

    .line 67
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->graphicsMb()I

    move-result p0

    return p0
.end method

.method static synthetic access$1002(Lcom/taomee/mole/MainActivity;Z)Z
    .locals 0

    .line 67
    iput-boolean p1, p0, Lcom/taomee/mole/MainActivity;->releasing:Z

    return p1
.end method

.method static synthetic access$1200(Lcom/taomee/mole/MainActivity;)V
    .locals 0

    .line 67
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->goImmersive()V

    return-void
.end method

.method static synthetic access$1300(Ljava/lang/String;)Ljava/lang/String;
    .locals 0

    .line 67
    invoke-static {p0}, Lcom/taomee/mole/MainActivity;->basename(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method static synthetic access$1400(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebResourceResponse;
    .locals 0

    .line 67
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->shellResponse()Landroid/webkit/WebResourceResponse;

    move-result-object p0

    return-object p0
.end method

.method static synthetic access$1500(Lcom/taomee/mole/MainActivity;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
    .locals 0

    .line 67
    invoke-direct {p0, p1}, Lcom/taomee/mole/MainActivity;->fontResponse(Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p0

    return-object p0
.end method

.method static synthetic access$1600(Lcom/taomee/mole/MainActivity;Ljava/lang/String;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
    .locals 0

    .line 67
    invoke-direct {p0, p1, p2}, Lcom/taomee/mole/MainActivity;->assetStream(Ljava/lang/String;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p0

    return-object p0
.end method

.method static synthetic access$1700(Lcom/taomee/mole/MainActivity;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
    .locals 0

    .line 67
    invoke-direct {p0, p1}, Lcom/taomee/mole/MainActivity;->wasmResponse(Ljava/lang/String;)Landroid/webkit/WebResourceResponse;

    move-result-object p0

    return-object p0
.end method

.method static synthetic access$1800(Ljava/lang/String;)Z
    .locals 0

    .line 67
    invoke-static {p0}, Lcom/taomee/mole/MainActivity;->isTaomeeHost(Ljava/lang/String;)Z

    move-result p0

    return p0
.end method

.method static synthetic access$1900(Lcom/taomee/mole/MainActivity;Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
    .locals 0

    .line 67
    invoke-direct {p0, p1}, Lcom/taomee/mole/MainActivity;->upstream(Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;

    move-result-object p0

    return-object p0
.end method

.method static synthetic access$200(Lcom/taomee/mole/MainActivity;Z)V
    .locals 0

    .line 67
    invoke-direct {p0, p1}, Lcom/taomee/mole/MainActivity;->releaseTextures(Z)V

    return-void
.end method

.method static synthetic access$2000(Lcom/taomee/mole/MainActivity;)I
    .locals 0

    .line 67
    iget p0, p0, Lcom/taomee/mole/MainActivity;->autoReloads:I

    return p0
.end method

.method static synthetic access$2008(Lcom/taomee/mole/MainActivity;)I
    .locals 2

    .line 67
    iget v0, p0, Lcom/taomee/mole/MainActivity;->autoReloads:I

    add-int/lit8 v1, v0, 0x1

    iput v1, p0, Lcom/taomee/mole/MainActivity;->autoReloads:I

    return v0
.end method

.method static synthetic access$2100(Lcom/taomee/mole/MainActivity;)Lcom/taomee/mole/SocketBridge;
    .locals 0

    .line 67
    iget-object p0, p0, Lcom/taomee/mole/MainActivity;->bridge:Lcom/taomee/mole/SocketBridge;

    return-object p0
.end method

.method static synthetic access$2200(Lcom/taomee/mole/MainActivity;Ljava/lang/String;I)V
    .locals 0

    .line 67
    invoke-direct {p0, p1, p2}, Lcom/taomee/mole/MainActivity;->learnMissingProxy(Ljava/lang/String;I)V

    return-void
.end method

.method static synthetic access$2300()I
    .locals 1

    .line 67
    sget v0, Lcom/taomee/mole/MainActivity;->MAX_LEVEL:I

    return v0
.end method

.method static synthetic access$300(Lcom/taomee/mole/MainActivity;)I
    .locals 0

    .line 67
    iget p0, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    return p0
.end method

.method static synthetic access$400(Lcom/taomee/mole/MainActivity;I)V
    .locals 0

    .line 67
    invoke-direct {p0, p1}, Lcom/taomee/mole/MainActivity;->raiseLoadLevel(I)V

    return-void
.end method

.method static synthetic access$508(Lcom/taomee/mole/MainActivity;)I
    .locals 2

    .line 67
    iget v0, p0, Lcom/taomee/mole/MainActivity;->gpuTicks:I

    add-int/lit8 v1, v0, 0x1

    iput v1, p0, Lcom/taomee/mole/MainActivity;->gpuTicks:I

    return v0
.end method

.method static synthetic access$600(Lcom/taomee/mole/MainActivity;)I
    .locals 0

    .line 67
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->pixelBudget()I

    move-result p0

    return p0
.end method

.method static synthetic access$700(Lcom/taomee/mole/MainActivity;)J
    .locals 2

    .line 67
    iget-wide v0, p0, Lcom/taomee/mole/MainActivity;->gpuPollMs:J

    return-wide v0
.end method

.method static synthetic access$702(Lcom/taomee/mole/MainActivity;J)J
    .locals 0

    .line 67
    iput-wide p1, p0, Lcom/taomee/mole/MainActivity;->gpuPollMs:J

    return-wide p1
.end method

.method static synthetic access$800(Lcom/taomee/mole/MainActivity;)Landroid/os/Handler;
    .locals 0

    .line 67
    iget-object p0, p0, Lcom/taomee/mole/MainActivity;->gpuHandler:Landroid/os/Handler;

    return-object p0
.end method

.method static synthetic access$900(Lcom/taomee/mole/MainActivity;)Landroid/webkit/WebView;
    .locals 0

    .line 67
    iget-object p0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    return-object p0
.end method

.method private assetStream(Ljava/lang/String;Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
    .locals 8

    .line 1098
    :try_start_0
    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getAssets()Landroid/content/res/AssetManager;

    move-result-object v0

    invoke-virtual {v0, p1}, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;

    move-result-object v7

    .line 1099
    new-instance v6, Ljava/util/HashMap;

    invoke-direct {v6}, Ljava/util/HashMap;-><init>()V

    .line 1100
    const-string v0, "Access-Control-Allow-Origin"

    const-string v1, "*"

    invoke-interface {v6, v0, v1}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1101
    const-string v0, "Cache-Control"

    const-string v1, "no-store"

    invoke-interface {v6, v0, v1}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1102
    new-instance v0, Landroid/webkit/WebResourceResponse;

    const-string v3, "UTF-8"

    const-string v5, "OK"

    const/16 v4, 0xc8

    move-object v1, v0

    move-object v2, p2

    invoke-direct/range {v1 .. v7}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/util/Map;Ljava/io/InputStream;)V
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0

    return-object v0

    .line 1103
    :catch_0
    move-exception p2

    .line 1104
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "assets \u7f3a\u5931\uff1a"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string v0, "MoleShell"

    invoke-static {v0, p1, p2}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 1105
    const/4 p1, 0x0

    return-object p1
.end method

.method private static basename(Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 1135
    const/16 v0, 0x3f

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v0

    .line 1136
    if-ltz v0, :cond_0

    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    .line 1137
    :cond_0
    const/16 v0, 0x2f

    invoke-virtual {p0, v0}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v0

    .line 1138
    if-ltz v0, :cond_1

    add-int/lit8 v0, v0, 0x1

    invoke-virtual {p0, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    :cond_1
    return-object p0
.end method

.method private static buildSeedPorts()[I
    .locals 5

    .line 177
    new-instance v0, Ljava/util/TreeSet;

    invoke-direct {v0}, Ljava/util/TreeSet;-><init>()V

    .line 179
    const/16 v1, 0x747

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z

    .line 180
    const/16 v1, 0x749

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z

    .line 181
    const/16 v1, 0xc80

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z

    .line 182
    const/16 v1, 0x1a09

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z

    .line 184
    const/16 v1, 0x744

    :goto_0
    const/16 v2, 0x758

    if-gt v1, v2, :cond_0

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    invoke-virtual {v0, v2}, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z

    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 186
    :cond_0
    const/16 v1, 0xc7b

    :goto_1
    const/16 v2, 0xc8f

    if-gt v1, v2, :cond_1

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    invoke-virtual {v0, v2}, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z

    add-int/lit8 v1, v1, 0x1

    goto :goto_1

    .line 187
    :cond_1
    const/16 v1, 0x19fa

    :goto_2
    const/16 v2, 0x1a2c

    if-gt v1, v2, :cond_2

    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v2

    invoke-virtual {v0, v2}, Ljava/util/TreeSet;->add(Ljava/lang/Object;)Z

    add-int/lit8 v1, v1, 0x1

    goto :goto_2

    .line 189
    :cond_2
    invoke-virtual {v0}, Ljava/util/TreeSet;->size()I

    move-result v1

    new-array v1, v1, [I

    .line 190
    nop

    .line 191
    invoke-virtual {v0}, Ljava/util/TreeSet;->iterator()Ljava/util/Iterator;

    move-result-object v0

    const/4 v2, 0x0

    :goto_3
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v3

    if-eqz v3, :cond_3

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v3

    check-cast v3, Ljava/lang/Integer;

    invoke-virtual {v3}, Ljava/lang/Integer;->intValue()I

    move-result v3

    add-int/lit8 v4, v2, 0x1

    aput v3, v1, v2

    move v2, v4

    goto :goto_3

    .line 192
    :cond_3
    return-object v1
.end method

.method private configure()V
    .locals 4

    .line 790
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    const/high16 v1, -0x1000000

    invoke-virtual {v0, v1}, Landroid/webkit/WebView;->setBackgroundColor(I)V

    .line 791
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    const/4 v1, 0x2

    invoke-virtual {v0, v1}, Landroid/webkit/WebView;->setOverScrollMode(I)V

    .line 792
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    new-instance v1, Lcom/taomee/mole/MainActivity$JsBridge;

    const/4 v2, 0x0

    invoke-direct {v1, p0, v2}, Lcom/taomee/mole/MainActivity$JsBridge;-><init>(Lcom/taomee/mole/MainActivity;Lcom/taomee/mole/MainActivity$1;)V

    const-string v2, "MoleBridge"

    invoke-virtual {v0, v1, v2}, Landroid/webkit/WebView;->addJavascriptInterface(Ljava/lang/Object;Ljava/lang/String;)V

    .line 794
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->getSettings()Landroid/webkit/WebSettings;

    move-result-object v0

    .line 795
    const/4 v1, 0x1

    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setJavaScriptEnabled(Z)V

    .line 796
    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setDomStorageEnabled(Z)V

    .line 797
    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setDatabaseEnabled(Z)V

    .line 798
    const/4 v2, 0x0

    invoke-virtual {v0, v2}, Landroid/webkit/WebSettings;->setMediaPlaybackRequiresUserGesture(Z)V

    .line 799
    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setUseWideViewPort(Z)V

    .line 800
    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setLoadWithOverviewMode(Z)V

    .line 801
    invoke-virtual {v0, v2}, Landroid/webkit/WebSettings;->setSupportZoom(Z)V

    .line 802
    invoke-virtual {v0, v2}, Landroid/webkit/WebSettings;->setBuiltInZoomControls(Z)V

    .line 803
    invoke-virtual {v0, v2}, Landroid/webkit/WebSettings;->setDisplayZoomControls(Z)V

    .line 804
    const/4 v3, -0x1

    invoke-virtual {v0, v3}, Landroid/webkit/WebSettings;->setCacheMode(I)V

    .line 805
    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setAllowFileAccess(Z)V

    .line 806
    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setJavaScriptCanOpenWindowsAutomatically(Z)V

    .line 807
    invoke-virtual {v0, v2}, Landroid/webkit/WebSettings;->setMixedContentMode(I)V

    .line 809
    :try_start_0
    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setAllowUniversalAccessFromFileURLs(Z)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 811
    goto :goto_0

    .line 810
    :catchall_0
    move-exception v1

    .line 814
    :goto_0
    :try_start_1
    invoke-virtual {v0}, Landroid/webkit/WebSettings;->getUserAgentString()Ljava/lang/String;

    move-result-object v1

    const-string v2, "; wv"

    const-string v3, ""

    invoke-virtual {v1, v2, v3}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setUserAgentString(Ljava/lang/String;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 816
    goto :goto_1

    .line 815
    :catchall_1
    move-exception v1

    .line 819
    :goto_1
    const/16 v1, 0x64

    :try_start_2
    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setTextZoom(I)V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    .line 821
    goto :goto_2

    .line 820
    :catchall_2
    move-exception v1

    .line 822
    :goto_2
    # ===== FIX(T1) 彻底关闭 WebView 自身的缩放 =====
    # 现象（群友反馈第 3 条）：「部分触控逻辑和鼠标逻辑完全混乱」——
    #   点 A 出 B、拖拽跳位；而且只要不小心双指过一下，之后整块画布的命中区
    #   就会整体偏移，不会自己恢复，只能退出重进。
    # 根因：页面 viewport 里的 user-scalable=no 自 Chrome 32 起对「捏合缩放」
    #   已不再强制生效，Android WebView 依然会做 visual viewport zoom。
    #   一旦被缩放，getBoundingClientRect() 返回的是**布局坐标**，
    #   而真实触点落在被放大的**视觉层**上 —— Ruffle 据此换算出的舞台坐标
    #   就整体错位，于是「点哪儿都不对」。这与 Ruffle 的输入映射无关，
    #   是壳层没把浏览器手势关掉。
    # 修法：三个开关全关。这里是唯一能真正禁掉捏合缩放的地方，
    #   页面侧（shell.html 第 4 段）只能做兜底复位。
    #   setDisplayZoomControls 需要 API 11，本包 minSdk 21，无需版本判断。
    #   不影响帧率、画质、画幅，只关输入层的缩放手势。
    const/4 v1, 0x0

    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setSupportZoom(Z)V

    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setBuiltInZoomControls(Z)V

    invoke-virtual {v0, v1}, Landroid/webkit/WebSettings;->setDisplayZoomControls(Z)V

    invoke-virtual {v0}, Landroid/webkit/WebSettings;->getUserAgentString()Ljava/lang/String;

    move-result-object v0

    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->ua:Ljava/lang/String;

    .line 823
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "UA = "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->ua:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "MoleShell"

    invoke-static {v1, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 825
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    new-instance v1, Lcom/taomee/mole/MainActivity$5;

    invoke-direct {v1, p0}, Lcom/taomee/mole/MainActivity$5;-><init>(Lcom/taomee/mole/MainActivity;)V

    invoke-virtual {v0, v1}, Landroid/webkit/WebView;->setWebChromeClient(Landroid/webkit/WebChromeClient;)V

    .line 838
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    new-instance v1, Lcom/taomee/mole/MainActivity$6;

    invoke-direct {v1, p0}, Lcom/taomee/mole/MainActivity$6;-><init>(Lcom/taomee/mole/MainActivity;)V

    invoke-virtual {v0, v1}, Landroid/webkit/WebView;->setWebViewClient(Landroid/webkit/WebViewClient;)V

    .line 898
    return-void
.end method

.method private static corsHeaders()Ljava/util/Map;
    .locals 3
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "()",
            "Ljava/util/Map<",
            "Ljava/lang/String;",
            "Ljava/lang/String;",
            ">;"
        }
    .end annotation

    .line 1306
    new-instance v0, Ljava/util/HashMap;

    invoke-direct {v0}, Ljava/util/HashMap;-><init>()V

    .line 1307
    const-string v1, "Access-Control-Allow-Origin"

    const-string v2, "*"

    invoke-interface {v0, v1, v2}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1308
    const-string v1, "Access-Control-Allow-Headers"

    invoke-interface {v0, v1, v2}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1309
    const-string v1, "Access-Control-Allow-Methods"

    const-string v2, "GET,POST,OPTIONS"

    invoke-interface {v0, v1, v2}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1310
    return-object v0
.end method

.method private evaluateLoadLevel()V
    .locals 12

    .line 582
    const-string v0, "mole_shell"

    const/4 v1, 0x0

    invoke-virtual {p0, v0, v1}, Lcom/taomee/mole/MainActivity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v0

    .line 583
    const-string v2, "boot_crashes_v4"

    invoke-interface {v0, v2, v1}, Landroid/content/SharedPreferences;->getInt(Ljava/lang/String;I)I

    move-result v3

    .line 584
    const-string v4, "boot_good_runs_v4"

    invoke-interface {v0, v4, v1}, Landroid/content/SharedPreferences;->getInt(Ljava/lang/String;I)I

    move-result v5

    .line 587
    nop

    .line 588
    sget v6, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v7, 0x1e

    if-lt v6, v7, :cond_0

    .line 589
    invoke-static {p0}, Lcom/taomee/mole/CrashProbe;->recentCrashStreak(Landroid/content/Context;)I

    move-result v6

    goto :goto_0

    .line 588
    :cond_0
    const/4 v6, -0x1

    .line 591
    :goto_0
    const-string v7, "boot_running_v1"

    const-string v8, "MoleShell"

    const/4 v9, 0x1

    if-ltz v6, :cond_3

    .line 598
    sget v10, Lcom/taomee/mole/MainActivity;->MAX_LEVEL:I

    invoke-static {v6, v10}, Ljava/lang/Math;->min(II)I

    move-result v10

    sget v11, Lcom/taomee/mole/MainActivity;->MAX_LEVEL:I

    invoke-static {v3, v11}, Ljava/lang/Math;->min(II)I

    move-result v11

    invoke-static {v10, v11}, Ljava/lang/Math;->max(II)I

    move-result v10

    .line 599
    if-nez v6, :cond_2

    .line 600
    add-int/lit8 v5, v5, 0x1

    .line 604
    const/4 v11, 0x2

    if-lt v5, v11, :cond_1

    if-lez v10, :cond_1

    .line 605
    add-int/lit8 v10, v10, -0x1

    .line 606
    nop

    .line 607
    const-string v5, "\u8fde\u7eed 2 \u6b21\u5e73\u7a33\u542f\u52a8 \u2192 \u753b\u8d28\u56de\u5347\u4e00\u6863"

    invoke-static {v8, v5}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    goto :goto_1

    .line 612
    :cond_1
    move v1, v5

    goto :goto_1

    .line 610
    :cond_2
    nop

    .line 612
    :goto_1
    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    const-string v11, "\u4e0a\u6b21\u9000\u51fa\u8fde\u7eed\u5d29\u6e83 "

    invoke-virtual {v5, v11}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v5

    const-string v6, " \u6b21\uff0c\u4e0a\u6b21\u6863 "

    invoke-virtual {v5, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v3

    const-string v5, " \u2192 \u672c\u6b21\u6863 "

    invoke-virtual {v3, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, v10}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-static {v8, v3}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    move v5, v1

    goto :goto_4

    .line 615
    :cond_3
    invoke-interface {v0, v7, v1}, Landroid/content/SharedPreferences;->getBoolean(Ljava/lang/String;Z)Z

    move-result v6

    .line 616
    if-eqz v6, :cond_4

    add-int/2addr v3, v9

    sget v1, Lcom/taomee/mole/MainActivity;->MAX_LEVEL:I

    invoke-static {v3, v1}, Ljava/lang/Math;->min(II)I

    move-result v1

    goto :goto_2

    :cond_4
    sub-int/2addr v3, v9

    invoke-static {v3, v1}, Ljava/lang/Math;->max(II)I

    move-result v1

    :goto_2
    move v10, v1

    .line 617
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u4e0a\u6b21 "

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    if-eqz v6, :cond_5

    const-string v3, "\u5f02\u5e38\u7ed3\u675f \u2192 \u52a0\u91cd"

    goto :goto_3

    :cond_5
    const-string v3, "\u6b63\u5e38\u7ed3\u675f \u2192 \u8870\u51cf"

    :goto_3
    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    const-string v3, "\uff08\u6807\u8bb0\u6cd5\uff09"

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v8, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 620
    :goto_4
    iput v10, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    .line 621
    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    invoke-interface {v0, v2, v10}, Landroid/content/SharedPreferences$Editor;->putInt(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    .line 622
    invoke-interface {v0, v4, v5}, Landroid/content/SharedPreferences$Editor;->putInt(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    .line 623
    invoke-interface {v0, v7, v9}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V

    .line 624
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u8d1f\u8f7d\u6863\u4f4d="

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget v1, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " \u2192 \u9884\u7b97 "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->pixelBudget()I

    move-result v1

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " px\uff0c\u540e\u7aef "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    .line 625
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->preferredRenderer()Ljava/lang/String;

    move-result-object v1

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    .line 624
    invoke-static {v8, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 628
    new-instance v0, Landroid/os/Handler;

    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getMainLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    new-instance v1, Lcom/taomee/mole/MainActivity$4;

    invoke-direct {v1, p0}, Lcom/taomee/mole/MainActivity$4;-><init>(Lcom/taomee/mole/MainActivity;)V

    const-wide/32 v2, 0x493e0

    invoke-virtual {v0, v1, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

    .line 638
    return-void
.end method

.method private static firstExisting([Ljava/lang/String;)Ljava/lang/String;
    .locals 8

    .line 1016
    array-length v0, p0

    const/4 v1, 0x0

    :goto_0
    if-ge v1, v0, :cond_1

    aget-object v2, p0, v1

    .line 1018
    :try_start_0
    new-instance v3, Ljava/io/File;

    invoke-direct {v3, v2}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    .line 1019
    invoke-virtual {v3}, Ljava/io/File;->isFile()Z

    move-result v4

    if-eqz v4, :cond_0

    invoke-virtual {v3}, Ljava/io/File;->canRead()Z

    move-result v4

    if-eqz v4, :cond_0

    invoke-virtual {v3}, Ljava/io/File;->length()J

    move-result-wide v3
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    const-wide/16 v5, 0x0

    cmp-long v7, v3, v5

    if-lez v7, :cond_0

    return-object v2

    .line 1021
    :cond_0
    goto :goto_1

    .line 1020
    :catchall_0
    move-exception v2

    .line 1016
    :goto_1
    add-int/lit8 v1, v1, 0x1

    goto :goto_0

    .line 1023
    :cond_1
    const/4 p0, 0x0

    return-object p0
.end method

.method private fontResponse(Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
    .locals 12

    .line 1039
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->resolveFonts()V

    .line 1040
    invoke-direct {p0, p1}, Lcom/taomee/mole/MainActivity;->isLatinName(Ljava/lang/String;)Z

    move-result v0

    .line 1041
    if-eqz v0, :cond_0

    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->latinFontPath:Ljava/lang/String;

    goto :goto_0

    :cond_0
    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->cjkFontPath:Ljava/lang/String;

    .line 1042
    :goto_0
    if-nez v1, :cond_2

    if-eqz v0, :cond_1

    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->cjkFontPath:Ljava/lang/String;

    goto :goto_1

    :cond_1
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->latinFontPath:Ljava/lang/String;

    :goto_1
    move-object v1, v0

    .line 1043
    :cond_2
    const/4 v0, 0x0

    const-string v2, "MoleShell"

    if-nez v1, :cond_3

    .line 1044
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u5b57\u4f53\u4e0b\u53d1\u5931\u8d25\uff1a"

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v1, " \u2014\u2014 \u65e0\u53ef\u7528\u7684\u7cfb\u7edf\u5b57\u4f53"

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v2, p1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 1045
    return-object v0

    .line 1048
    :cond_3
    :try_start_0
    new-instance v9, Ljava/io/FileInputStream;

    invoke-direct {v9, v1}, Ljava/io/FileInputStream;-><init>(Ljava/lang/String;)V

    .line 1049
    new-instance v8, Ljava/util/HashMap;

    invoke-direct {v8}, Ljava/util/HashMap;-><init>()V

    .line 1050
    const-string v3, "Access-Control-Allow-Origin"

    const-string v4, "*"

    invoke-interface {v8, v3, v4}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1051
    const-string v3, "Cache-Control"

    const-string v4, "public, max-age=31536000"

    invoke-interface {v8, v3, v4}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1052
    sget-object v3, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p1, v3}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v3

    const-string v4, ".ttc"

    invoke-virtual {v3, v4}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v3

    if-eqz v3, :cond_4

    const-string v3, "font/collection"

    goto :goto_2

    :cond_4
    const-string v3, "font/ttf"

    :goto_2
    move-object v4, v3

    .line 1053
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "\u4e0b\u53d1\u5b57\u4f53 "

    invoke-virtual {v3, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v3, " \u2190 "

    invoke-virtual {p1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v3, "\uff08"

    invoke-virtual {p1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    new-instance v3, Ljava/io/File;

    invoke-direct {v3, v1}, Ljava/io/File;-><init>(Ljava/lang/String;)V

    invoke-virtual {v3}, Ljava/io/File;->length()J

    move-result-wide v5

    const-wide/16 v10, 0x400

    div-long/2addr v5, v10

    invoke-virtual {p1, v5, v6}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v3, " KB\uff09"

    invoke-virtual {p1, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v2, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 1054
    new-instance p1, Landroid/webkit/WebResourceResponse;

    const-string v7, "OK"

    const/4 v5, 0x0

    const/16 v6, 0xc8

    move-object v3, p1

    invoke-direct/range {v3 .. v9}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/util/Map;Ljava/io/InputStream;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-object p1

    .line 1055
    :catchall_0
    move-exception p1

    .line 1056
    new-instance v3, Ljava/lang/StringBuilder;

    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V

    const-string v4, "\u5b57\u4f53\u8bfb\u53d6\u5931\u8d25\uff1a"

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v3

    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v2, v1, p1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 1057
    return-object v0
.end method

.method private goImmersive()V
    .locals 3

    .line 1372
    :try_start_0
    sget v0, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v1, 0x1e

    if-lt v0, v1, :cond_1

    .line 1373
    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getWindow()Landroid/view/Window;

    move-result-object v0

    invoke-virtual {v0}, Landroid/view/Window;->getInsetsController()Landroid/view/WindowInsetsController;

    move-result-object v0

    .line 1374
    if-eqz v0, :cond_0

    .line 1375
    invoke-static {}, Landroid/view/WindowInsets$Type;->systemBars()I

    move-result v1

    invoke-interface {v0, v1}, Landroid/view/WindowInsetsController;->hide(I)V

    .line 1376
    const/4 v1, 0x2

    invoke-interface {v0, v1}, Landroid/view/WindowInsetsController;->setSystemBarsBehavior(I)V

    .line 1379
    :cond_0
    goto :goto_0

    .line 1380
    :cond_1
    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getWindow()Landroid/view/Window;

    move-result-object v0

    invoke-virtual {v0}, Landroid/view/Window;->getDecorView()Landroid/view/View;

    move-result-object v0

    const/16 v1, 0x1706

    invoke-virtual {v0, v1}, Landroid/view/View;->setSystemUiVisibility(I)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 1390
    :goto_0
    goto :goto_1

    .line 1388
    :catchall_0
    move-exception v0

    .line 1389
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u6c89\u6d78\u5f0f\u5931\u8d25\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "MoleShell"

    invoke-static {v1, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 1391
    :goto_1
    return-void
.end method

.method private graphicsMb()I
    .locals 3

    .line 503
    const/4 v0, -0x1

    :try_start_0
    sget v1, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v2, 0x17

    if-ge v1, v2, :cond_0

    return v0

    .line 504
    :cond_0
    const-string v1, "activity"

    .line 505
    invoke-virtual {p0, v1}, Lcom/taomee/mole/MainActivity;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v1

    check-cast v1, Landroid/app/ActivityManager;

    .line 506
    if-nez v1, :cond_1

    return v0

    .line 507
    :cond_1
    nop

    .line 508
    invoke-static {}, Landroid/os/Process;->myPid()I

    move-result v2

    filled-new-array {v2}, [I

    move-result-object v2

    invoke-virtual {v1, v2}, Landroid/app/ActivityManager;->getProcessMemoryInfo([I)[Landroid/os/Debug$MemoryInfo;

    move-result-object v1

    .line 509
    if-eqz v1, :cond_4

    array-length v2, v1

    if-nez v2, :cond_2

    goto :goto_0

    .line 510
    :cond_2
    const/4 v2, 0x0

    aget-object v1, v1, v2

    const-string v2, "summary.graphics"

    invoke-virtual {v1, v2}, Landroid/os/Debug$MemoryInfo;->getMemoryStat(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v1

    .line 511
    if-nez v1, :cond_3

    return v0

    .line 512
    :cond_3
    invoke-virtual {v1}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result v1

    div-int/lit16 v1, v1, 0x400
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return v1

    .line 509
    :cond_4
    :goto_0
    return v0

    .line 513
    :catchall_0
    move-exception v1

    .line 514
    return v0
.end method

.method private static guessMime(Ljava/lang/String;)Ljava/lang/String;
    .locals 2

    .line 1352
    sget-object v0, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    .line 1353
    const/16 v0, 0x3f

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v0

    .line 1354
    if-ltz v0, :cond_0

    const/4 v1, 0x0

    invoke-virtual {p0, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    .line 1355
    :cond_0
    const-string v0, ".swf"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_1

    const-string p0, "application/x-shockwave-flash"

    return-object p0

    .line 1356
    :cond_1
    const-string v0, ".js"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_2

    const-string p0, "application/javascript"

    return-object p0

    .line 1357
    :cond_2
    const-string v0, ".json"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_3

    const-string p0, "application/json"

    return-object p0

    .line 1358
    :cond_3
    const-string v0, ".xml"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_4

    const-string p0, "text/xml"

    return-object p0

    .line 1359
    :cond_4
    const-string v0, ".css"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_5

    const-string p0, "text/css"

    return-object p0

    .line 1360
    :cond_5
    const-string v0, ".html"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_c

    const-string v0, ".shtml"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_c

    const-string v0, ".htm"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_6

    goto :goto_1

    .line 1361
    :cond_6
    const-string v0, ".png"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_7

    const-string p0, "image/png"

    return-object p0

    .line 1362
    :cond_7
    const-string v0, ".jpg"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_b

    const-string v0, ".jpeg"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_8

    goto :goto_0

    .line 1363
    :cond_8
    const-string v0, ".gif"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_9

    const-string p0, "image/gif"

    return-object p0

    .line 1364
    :cond_9
    const-string v0, ".mp3"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_a

    const-string p0, "audio/mpeg"

    return-object p0

    .line 1365
    :cond_a
    const-string p0, "application/octet-stream"

    return-object p0

    .line 1362
    :cond_b
    :goto_0
    const-string p0, "image/jpeg"

    return-object p0

    .line 1360
    :cond_c
    :goto_1
    const-string p0, "text/html"

    return-object p0
.end method

.method private static isBinary(Ljava/lang/String;)Z
    .locals 1

    .line 1331
    const-string v0, "image/"

    invoke-virtual {p0, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, "octet-stream"

    invoke-virtual {p0, v0}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    move-result p0

    if-eqz p0, :cond_0

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    goto :goto_1

    :cond_1
    :goto_0
    const/4 p0, 0x1

    :goto_1
    return p0
.end method

.method private isLatinName(Ljava/lang/String;)Z
    .locals 5

    .line 1027
    sget-object v0, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p1, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p1

    .line 1028
    const/16 v0, 0x2e

    invoke-virtual {p1, v0}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v0

    .line 1029
    const/4 v1, 0x0

    if-lez v0, :cond_0

    invoke-virtual {p1, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p1

    .line 1030
    :cond_0
    const-string v0, "_"

    const-string v2, ""

    invoke-virtual {p1, v0, v2}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p1

    const-string v0, "-"

    invoke-virtual {p1, v0, v2}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p1

    const-string v0, " "

    invoke-virtual {p1, v0, v2}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object p1

    .line 1031
    sget-object v0, Lcom/taomee/mole/MainActivity;->LATIN_NAMES:[Ljava/lang/String;

    array-length v2, v0

    const/4 v3, 0x0

    :goto_0
    if-ge v3, v2, :cond_2

    aget-object v4, v0, v3

    .line 1032
    invoke-virtual {p1, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v4

    if-eqz v4, :cond_1

    const/4 p1, 0x1

    return p1

    .line 1031
    :cond_1
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 1034
    :cond_2
    return v1
.end method

.method private static isTaomeeHost(Ljava/lang/String;)Z
    .locals 1

    .line 1128
    sget-object v0, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, v0}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    .line 1129
    const-string v0, "61.com"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, ".61.com"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_1

    .line 1130
    const-string v0, "taomee.com"

    invoke-virtual {p0, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    const-string v0, ".taomee.com"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_1

    .line 1131
    const-string v0, ".51mole.com"

    invoke-virtual {p0, v0}, Ljava/lang/String;->endsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_0

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    goto :goto_1

    :cond_1
    :goto_0
    const/4 p0, 0x1

    .line 1129
    :goto_1
    return p0
.end method

.method private learnMissingProxy(Ljava/lang/String;I)V
    .locals 4

    .line 940
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, ":"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    .line 942
    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    monitor-enter v1

    .line 943
    :try_start_0
    iget-object v2, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    invoke-virtual {v2, v0}, Ljava/util/LinkedHashSet;->contains(Ljava/lang/Object;)Z

    move-result v2

    .line 944
    xor-int/lit8 v2, v2, 0x1

    if-eqz v2, :cond_0

    iget-object v3, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    invoke-virtual {v3, v0}, Ljava/util/LinkedHashSet;->add(Ljava/lang/Object;)Z

    .line 945
    :cond_0
    monitor-exit v1
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_1

    .line 946
    if-nez v2, :cond_1

    return-void

    .line 947
    :cond_1
    const-string v0, "MoleShell"

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u8865\u5f55\u670d\u52a1\u5668\u7aef\u53e3\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-static {p1}, Lcom/taomee/mole/MainActivity;->mask(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v1, ":"

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string p2, "\uff08\u6e90\u81ea Ruffle \u7684\u7f3a\u5931\u4ee3\u7406\u544a\u8b66\uff09"

    invoke-virtual {p1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 949
    :try_start_1
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    .line 950
    iget-object p2, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    invoke-virtual {p2}, Ljava/util/LinkedHashSet;->iterator()Ljava/util/Iterator;

    move-result-object p2

    :goto_0
    invoke-interface {p2}, Ljava/util/Iterator;->hasNext()Z

    move-result v0

    if-eqz v0, :cond_3

    invoke-interface {p2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/String;

    .line 951
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->length()I

    move-result v1

    if-lez v1, :cond_2

    const/16 v1, 0x2c

    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 952
    :cond_2
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 953
    goto :goto_0

    .line 954
    :cond_3
    const-string p2, "mole_shell"

    const/4 v0, 0x0

    invoke-virtual {p0, p2, v0}, Lcom/taomee/mole/MainActivity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object p2

    invoke-interface {p2}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object p2

    const-string v0, "socket_targets_v2"

    .line 955
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-interface {p2, v0, p1}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    move-result-object p1

    invoke-interface {p1}, Landroid/content/SharedPreferences$Editor;->apply()V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    .line 958
    goto :goto_1

    .line 956
    :catchall_0
    move-exception p1

    .line 957
    const-string p2, "MoleShell"

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u4fdd\u5b58\u670d\u52a1\u5668\u5217\u8868\u5931\u8d25\uff1a"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {p2, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 959
    :goto_1
    new-instance p1, Lcom/taomee/mole/MainActivity$7;

    invoke-direct {p1, p0}, Lcom/taomee/mole/MainActivity$7;-><init>(Lcom/taomee/mole/MainActivity;)V

    invoke-virtual {p0, p1}, Lcom/taomee/mole/MainActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 972
    return-void

    .line 945
    :catchall_1
    move-exception p1

    :try_start_2
    monitor-exit v1
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_1

    throw p1
.end method

.method private loadTargets()V
    .locals 12

    .line 903
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    invoke-virtual {v0}, Ljava/util/LinkedHashSet;->clear()V

    .line 904
    sget-object v0, Lcom/taomee/mole/MainActivity;->SEED_HOSTS_ENC:[Ljava/lang/String;

    array-length v1, v0

    const/4 v2, 0x0

    const/4 v3, 0x0

    :goto_0
    if-ge v3, v1, :cond_1

    aget-object v4, v0, v3

    .line 905
    invoke-static {v4}, Lcom/taomee/mole/MainActivity;->unmaskStr(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v4

    .line 906
    sget-object v5, Lcom/taomee/mole/MainActivity;->SEED_PORTS:[I

    array-length v6, v5

    const/4 v7, 0x0

    :goto_1
    if-ge v7, v6, :cond_0

    aget v8, v5, v7

    iget-object v9, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    new-instance v10, Ljava/lang/StringBuilder;

    invoke-direct {v10}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v10, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v10

    const-string v11, ":"

    invoke-virtual {v10, v11}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v10

    invoke-virtual {v10, v8}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v8

    invoke-virtual {v8}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v8

    invoke-virtual {v9, v8}, Ljava/util/LinkedHashSet;->add(Ljava/lang/Object;)Z

    add-int/lit8 v7, v7, 0x1

    goto :goto_1

    .line 904
    :cond_0
    add-int/lit8 v3, v3, 0x1

    goto :goto_0

    .line 909
    :cond_1
    :try_start_0
    const-string v0, "mole_shell"

    invoke-virtual {p0, v0, v2}, Lcom/taomee/mole/MainActivity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v0

    const-string v1, "socket_targets_v2"

    const-string v3, ""

    invoke-interface {v0, v1, v3}, Landroid/content/SharedPreferences;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    .line 910
    if-eqz v0, :cond_3

    invoke-virtual {v0}, Ljava/lang/String;->isEmpty()Z

    move-result v1

    if-nez v1, :cond_3

    .line 911
    const-string v1, ","

    invoke-virtual {v0, v1}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v0

    array-length v1, v0

    :goto_2
    if-ge v2, v1, :cond_3

    aget-object v3, v0, v2

    .line 912
    invoke-virtual {v3}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v3

    .line 913
    invoke-virtual {v3}, Ljava/lang/String;->isEmpty()Z

    move-result v4

    if-nez v4, :cond_2

    const/16 v4, 0x3a

    invoke-virtual {v3, v4}, Ljava/lang/String;->indexOf(I)I

    move-result v4

    if-lez v4, :cond_2

    iget-object v4, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    invoke-virtual {v4, v3}, Ljava/util/LinkedHashSet;->add(Ljava/lang/Object;)Z
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 911
    :cond_2
    add-int/lit8 v2, v2, 0x1

    goto :goto_2

    .line 918
    :cond_3
    goto :goto_3

    .line 916
    :catchall_0
    move-exception v0

    .line 917
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u8bfb\u53d6\u5df2\u5b58\u670d\u52a1\u5668\u5217\u8868\u5931\u8d25\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "MoleShell"

    invoke-static {v1, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 919
    :goto_3
    return-void
.end method

.method private markCleanExit()V
    .locals 3

    .line 643
    :try_start_0
    const-string v0, "mole_shell"

    const/4 v1, 0x0

    invoke-virtual {p0, v0, v1}, Lcom/taomee/mole/MainActivity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    const-string v2, "boot_running_v1"

    .line 644
    invoke-interface {v0, v2, v1}, Landroid/content/SharedPreferences$Editor;->putBoolean(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 646
    goto :goto_0

    .line 645
    :catchall_0
    move-exception v0

    .line 647
    :goto_0
    return-void
.end method

.method static mask(Ljava/lang/String;)Ljava/lang/String;
    .locals 3

    .line 976
    if-nez p0, :cond_0

    const-string p0, "?"

    return-object p0

    .line 977
    :cond_0
    const/16 v0, 0x2e

    invoke-virtual {p0, v0}, Ljava/lang/String;->indexOf(I)I

    move-result v0

    .line 978
    if-lez v0, :cond_1

    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const/4 v2, 0x0

    invoke-virtual {p0, v2, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object p0

    invoke-virtual {v1, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    const-string v0, ".***.***.***"

    invoke-virtual {p0, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p0

    invoke-virtual {p0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    goto :goto_0

    :cond_1
    const-string p0, "***"

    :goto_0
    return-object p0
.end method

.method private pixelBudget()I
    .locals 2

    .line 287
    iget v0, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    const/4 v1, 0x0

    invoke-static {v0, v1}, Ljava/lang/Math;->max(II)I

    move-result v0

    sget v1, Lcom/taomee/mole/MainActivity;->MAX_LEVEL:I

    invoke-static {v0, v1}, Ljava/lang/Math;->min(II)I

    move-result v0

    .line 288
    sget-object v1, Lcom/taomee/mole/MainActivity;->PIXEL_BUDGETS:[I

    aget v0, v1, v0

    return v0
.end method

.method private preferredRenderer()Ljava/lang/String;
    .locals 1

    .line 577
    const-string v0, "wgpu-webgl"

    return-object v0
.end method

.method private raiseLoadLevel(I)V
    .locals 3

    .line 527
    const/4 v0, 0x0

    invoke-static {p1, v0}, Ljava/lang/Math;->max(II)I

    move-result p1

    sget v1, Lcom/taomee/mole/MainActivity;->MAX_LEVEL:I

    invoke-static {p1, v1}, Ljava/lang/Math;->min(II)I

    move-result p1

    .line 528
    iget v1, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    if-gt p1, v1, :cond_0

    return-void

    .line 529
    :cond_0
    iput p1, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    .line 530
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->pixelBudget()I

    move-result p1

    .line 532
    :try_start_0
    const-string v1, "mole_shell"

    invoke-virtual {p0, v1, v0}, Lcom/taomee/mole/MainActivity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    const-string v1, "boot_crashes_v4"

    iget v2, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    .line 533
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences$Editor;->putInt(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;

    move-result-object v0

    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 535
    goto :goto_0

    .line 534
    :catchall_0
    move-exception v0

    .line 536
    :goto_0
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u8d1f\u8f7d\u6863\u4f4d \u2192 "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget v1, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, "\uff08\u9884\u7b97 "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " px\uff09"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "MoleShell"

    invoke-static {v1, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 538
    new-instance v0, Lcom/taomee/mole/MainActivity$3;

    invoke-direct {v0, p0, p1}, Lcom/taomee/mole/MainActivity$3;-><init>(Lcom/taomee/mole/MainActivity;I)V

    invoke-virtual {p0, v0}, Lcom/taomee/mole/MainActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 551
    return-void
.end method

.method private static readAll(Ljava/io/InputStream;)[B
    .locals 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 1335
    new-instance v0, Ljava/io/ByteArrayOutputStream;

    const/high16 v1, 0x10000

    invoke-direct {v0, v1}, Ljava/io/ByteArrayOutputStream;-><init>(I)V

    .line 1336
    const/16 v1, 0x4000

    new-array v1, v1, [B

    .line 1338
    :goto_0
    invoke-virtual {p0, v1}, Ljava/io/InputStream;->read([B)I

    move-result v2

    if-lez v2, :cond_0

    const/4 v3, 0x0

    invoke-virtual {v0, v1, v3, v2}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    goto :goto_0

    .line 1339
    :cond_0
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object p0

    return-object p0
.end method

.method private static readCap(Ljava/io/InputStream;I)[B
    .locals 5
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/IOException;
        }
    .end annotation

    .line 1319
    new-instance v0, Ljava/io/ByteArrayOutputStream;

    const/high16 v1, 0x10000

    invoke-static {p1, v1}, Ljava/lang/Math;->min(II)I

    move-result v1

    invoke-direct {v0, v1}, Ljava/io/ByteArrayOutputStream;-><init>(I)V

    .line 1320
    const/16 v1, 0x4000

    new-array v2, v1, [B

    .line 1321
    :goto_0
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v3

    if-ge v3, p1, :cond_1

    .line 1322
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->size()I

    move-result v3

    sub-int v3, p1, v3

    invoke-static {v1, v3}, Ljava/lang/Math;->min(II)I

    move-result v3

    .line 1323
    const/4 v4, 0x0

    invoke-virtual {p0, v2, v4, v3}, Ljava/io/InputStream;->read([BII)I

    move-result v3

    .line 1324
    if-gtz v3, :cond_0

    goto :goto_1

    .line 1325
    :cond_0
    invoke-virtual {v0, v2, v4, v3}, Ljava/io/ByteArrayOutputStream;->write([BII)V

    .line 1326
    goto :goto_0

    .line 1327
    :cond_1
    :goto_1
    invoke-virtual {v0}, Ljava/io/ByteArrayOutputStream;->toByteArray()[B

    move-result-object p0

    return-object p0
.end method

.method private releaseTextures(Z)V
    .locals 9

    .line 447
    invoke-static {}, Landroid/os/SystemClock;->elapsedRealtime()J

    move-result-wide v0

    .line 448
    iget-boolean v2, p0, Lcom/taomee/mole/MainActivity;->releasing:Z

    if-eqz v2, :cond_0

    return-void

    .line 449
    :cond_0
    if-eqz p1, :cond_1

    const-wide/16 v2, 0x3a98

    goto :goto_0

    :cond_1
    const-wide/32 v2, 0x1d4c0

    .line 450
    :goto_0
    iget-wide v4, p0, Lcom/taomee/mole/MainActivity;->lastReleaseAt:J

    sub-long v4, v0, v4

    const-string v6, ""

    const-string v7, "MoleShell"

    cmp-long v8, v4, v2

    if-gez v8, :cond_3

    .line 451
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u91ca\u653e\u51b7\u5374\u4e2d\uff08\u8ddd\u4e0a\u6b21 "

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    iget-wide v3, p0, Lcom/taomee/mole/MainActivity;->lastReleaseAt:J

    sub-long/2addr v0, v3

    const-wide/16 v3, 0x3e8

    div-long/2addr v0, v3

    invoke-virtual {v2, v0, v1}, Ljava/lang/StringBuilder;->append(J)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, "s"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    .line 452
    if-eqz p1, :cond_2

    const-string v6, "\uff0cpanic \u9632\u6296"

    :cond_2
    invoke-virtual {v0, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, "\uff09\uff0c\u8df3\u8fc7"

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 451
    invoke-static {v7, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 453
    return-void

    .line 455
    :cond_3
    if-nez p1, :cond_4

    iget v2, p0, Lcom/taomee/mole/MainActivity;->releaseCount:I

    const/16 v3, 0xa

    if-lt v2, v3, :cond_4

    .line 456
    const-string p1, "\u4e3b\u52a8\u91ca\u653e\u5df2\u8fbe 10 \u6b21\u4e0a\u9650"

    invoke-static {v7, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 457
    return-void

    .line 459
    :cond_4
    if-eqz p1, :cond_5

    const/4 v2, 0x0

    iput v2, p0, Lcom/taomee/mole/MainActivity;->releaseCount:I

    .line 460
    :cond_5
    const/4 v2, 0x1

    iput-boolean v2, p0, Lcom/taomee/mole/MainActivity;->releasing:Z

    .line 461
    iget v3, p0, Lcom/taomee/mole/MainActivity;->releaseCount:I

    add-int/2addr v3, v2

    iput v3, p0, Lcom/taomee/mole/MainActivity;->releaseCount:I

    .line 462
    iput-wide v0, p0, Lcom/taomee/mole/MainActivity;->lastReleaseAt:J

    .line 465
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u7b2c "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget v1, p0, Lcom/taomee/mole/MainActivity;->releaseCount:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " \u6b21\u4e3b\u52a8\u91ca\u653e"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    .line 466
    if-eqz p1, :cond_6

    const-string v6, "\uff08panic \u5f3a\u5236\uff09"

    :cond_6
    invoke-virtual {v0, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v0, "\uff1a\u7a7a\u767d\u9875\u4e2d\u8f6c"

    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 465
    invoke-static {v7, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 467
    new-instance p1, Lcom/taomee/mole/MainActivity$2;

    invoke-direct {p1, p0}, Lcom/taomee/mole/MainActivity$2;-><init>(Lcom/taomee/mole/MainActivity;)V

    invoke-virtual {p0, p1}, Lcom/taomee/mole/MainActivity;->runOnUiThread(Ljava/lang/Runnable;)V

    .line 494
    return-void
.end method

.method private resolveFonts()V
    .locals 2

    .line 1005
    iget-boolean v0, p0, Lcom/taomee/mole/MainActivity;->fontsResolved:Z

    if-eqz v0, :cond_0

    return-void

    .line 1006
    :cond_0
    const/4 v0, 0x1

    iput-boolean v0, p0, Lcom/taomee/mole/MainActivity;->fontsResolved:Z

    .line 1007
    sget-object v0, Lcom/taomee/mole/MainActivity;->CJK_FONT_CANDIDATES:[Ljava/lang/String;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->firstExisting([Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->cjkFontPath:Ljava/lang/String;

    .line 1008
    sget-object v0, Lcom/taomee/mole/MainActivity;->LATIN_FONT_CANDIDATES:[Ljava/lang/String;

    invoke-static {v0}, Lcom/taomee/mole/MainActivity;->firstExisting([Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->latinFontPath:Ljava/lang/String;

    .line 1009
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "CJK \u5b57\u4f53 = "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->cjkFontPath:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, " / \u62c9\u4e01\u5b57\u4f53 = "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->latinFontPath:Ljava/lang/String;

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "MoleShell"

    invoke-static {v1, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 1010
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->cjkFontPath:Ljava/lang/String;

    if-nez v0, :cond_1

    .line 1011
    const-string v0, "\u8bbe\u5907\u4e0a\u6ca1\u627e\u5230\u4efb\u4f55 CJK \u5b57\u4f53 \u2014\u2014 \u4e2d\u6587\u4f1a\u7f3a\u5931\uff0c\u9700\u8981\u6539\u4e3a\u968f\u5305\u5185\u7f6e\u5b57\u4f53"

    invoke-static {v1, v0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I

    .line 1013
    :cond_1
    return-void
.end method

.method private static safeReason(Ljava/net/HttpURLConnection;)Ljava/lang/String;
    .locals 1

    .line 1344
    const-string v0, "OK"

    :try_start_0
    invoke-virtual {p0}, Ljava/net/HttpURLConnection;->getResponseMessage()Ljava/lang/String;

    move-result-object p0
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 1345
    if-nez p0, :cond_0

    goto :goto_0

    :cond_0
    move-object v0, p0

    :goto_0
    return-object v0

    .line 1346
    :catchall_0
    move-exception p0

    .line 1347
    return-object v0
.end method

.method private shellResponse()Landroid/webkit/WebResourceResponse;
    .locals 10

    .line 1066
    const-string v0, "\'"

    const-string v1, "MoleShell"

    :try_start_0
    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getAssets()Landroid/content/res/AssetManager;

    move-result-object v2

    const-string v3, "ruffle/shell.html"

    invoke-virtual {v2, v3}, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;

    move-result-object v2

    .line 1067
    invoke-static {v2}, Lcom/taomee/mole/MainActivity;->readAll(Ljava/io/InputStream;)[B

    move-result-object v3

    .line 1068
    invoke-virtual {v2}, Ljava/io/InputStream;->close()V

    .line 1069
    new-instance v2, Ljava/lang/String;

    sget-object v4, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    invoke-direct {v2, v3, v4}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    .line 1071
    new-instance v3, Ljava/lang/StringBuilder;

    const-string v4, "["

    invoke-direct {v3, v4}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 1072
    const/4 v4, 0x0

    :goto_0
    sget-object v5, Lcom/taomee/mole/MainActivity;->FONT_SOURCES:[Ljava/lang/String;

    array-length v5, v5

    if-ge v4, v5, :cond_1

    .line 1073
    if-lez v4, :cond_0

    const/16 v5, 0x2c

    invoke-virtual {v3, v5}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 1074
    :cond_0
    const/16 v5, 0x27

    invoke-virtual {v3, v5}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v6

    sget-object v7, Lcom/taomee/mole/MainActivity;->FONT_SOURCES:[Ljava/lang/String;

    aget-object v7, v7, v4

    invoke-virtual {v6, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v6

    invoke-virtual {v6, v5}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 1072
    add-int/lit8 v4, v4, 0x1

    goto :goto_0

    .line 1076
    :cond_1
    const/16 v4, 0x5d

    invoke-virtual {v3, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 1078
    const-string v4, "__FONT_SOURCES__"

    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v4, v3}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v2

    const-string v3, "__SOCKET_PROXY__"

    .line 1079
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->socketProxyJs()Ljava/lang/String;

    move-result-object v4

    invoke-virtual {v2, v3, v4}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v2

    const-string v3, "__PIXEL_BUDGET__"

    .line 1080
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->pixelBudget()I

    move-result v4

    invoke-static {v4}, Ljava/lang/String;->valueOf(I)Ljava/lang/String;

    move-result-object v4

    invoke-virtual {v2, v3, v4}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v2

    const-string v3, "__RENDERER__"

    new-instance v4, Ljava/lang/StringBuilder;

    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v4, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    .line 1081
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->preferredRenderer()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-virtual {v2, v3, v0}, Ljava/lang/String;->replace(Ljava/lang/CharSequence;Ljava/lang/CharSequence;)Ljava/lang/String;

    move-result-object v0

    .line 1083
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u4e0b\u53d1\u7a7a\u58f3\u9875\uff08\u5b57\u4f53\u6e90 "

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    sget-object v3, Lcom/taomee/mole/MainActivity;->FONT_SOURCES:[Ljava/lang/String;

    array-length v3, v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v3, " \u4e2a\uff0csocketProxy "

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    iget-object v3, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    .line 1084
    invoke-virtual {v3}, Ljava/util/LinkedHashSet;->size()I

    move-result v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v3, " \u6761\uff0c\u6e32\u67d3\u9884\u7b97 "

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    .line 1085
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->pixelBudget()I

    move-result v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v3, " px\uff0c\u540e\u7aef "

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->preferredRenderer()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v3, "\uff09"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    .line 1083
    invoke-static {v1, v2}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 1086
    new-instance v8, Ljava/util/HashMap;

    invoke-direct {v8}, Ljava/util/HashMap;-><init>()V

    .line 1087
    const-string v2, "Cache-Control"

    const-string v3, "no-store"

    invoke-interface {v8, v2, v3}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1088
    new-instance v2, Landroid/webkit/WebResourceResponse;

    const-string v4, "text/html"

    const-string v5, "UTF-8"

    const-string v7, "OK"

    new-instance v9, Ljava/io/ByteArrayInputStream;

    sget-object v3, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    .line 1089
    invoke-virtual {v0, v3}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    move-result-object v0

    invoke-direct {v9, v0}, Ljava/io/ByteArrayInputStream;-><init>([B)V

    const/16 v6, 0xc8

    move-object v3, v2

    invoke-direct/range {v3 .. v9}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/util/Map;Ljava/io/InputStream;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 1088
    return-object v2

    .line 1090
    :catchall_0
    move-exception v0

    .line 1091
    const-string v2, "\u58f3\u9875\u4e0b\u53d1\u5931\u8d25"

    invoke-static {v1, v2, v0}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 1092
    const/4 v0, 0x0

    return-object v0
.end method

.method private socketProxyJs()Ljava/lang/String;
    .locals 8

    .line 983
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->bridge:Lcom/taomee/mole/SocketBridge;

    const/4 v1, 0x0

    if-nez v0, :cond_0

    const/4 v0, 0x0

    goto :goto_0

    :cond_0
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->bridge:Lcom/taomee/mole/SocketBridge;

    invoke-virtual {v0}, Lcom/taomee/mole/SocketBridge;->getPort()I

    move-result v0

    .line 984
    :goto_0
    new-instance v2, Ljava/lang/StringBuilder;

    const-string v3, "["

    invoke-direct {v2, v3}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 985
    if-lez v0, :cond_3

    .line 986
    nop

    .line 987
    iget-object v3, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    invoke-virtual {v3}, Ljava/util/LinkedHashSet;->iterator()Ljava/util/Iterator;

    move-result-object v3

    const/4 v4, 0x1

    :goto_1
    invoke-interface {v3}, Ljava/util/Iterator;->hasNext()Z

    move-result v5

    if-eqz v5, :cond_3

    invoke-interface {v3}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Ljava/lang/String;

    .line 988
    const/16 v6, 0x3a

    invoke-virtual {v5, v6}, Ljava/lang/String;->lastIndexOf(I)I

    move-result v6

    .line 989
    if-gtz v6, :cond_1

    goto :goto_1

    .line 990
    :cond_1
    invoke-virtual {v5, v1, v6}, Ljava/lang/String;->substring(II)Ljava/lang/String;

    move-result-object v7

    .line 991
    add-int/lit8 v6, v6, 0x1

    invoke-virtual {v5, v6}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object v5

    .line 992
    if-nez v4, :cond_2

    const/16 v4, 0x2c

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 993
    :cond_2
    nop

    .line 994
    const-string v4, "{host:\'"

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v6, "\',port:"

    invoke-virtual {v4, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    .line 995
    const-string v6, ",proxyUrl:\'ws://127.0.0.1:"

    invoke-virtual {v4, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v4

    .line 996
    const-string v6, "/?host="

    invoke-virtual {v4, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v6, "&port="

    invoke-virtual {v4, v6}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v4

    const-string v5, "\'}"

    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 997
    const/4 v4, 0x0

    goto :goto_1

    .line 999
    :cond_3
    const/16 v0, 0x5d

    invoke-virtual {v2, v0}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    return-object v0
.end method

.method private startGpuWatch()V
    .locals 4

    .line 400
    :try_start_0
    new-instance v0, Landroid/os/HandlerThread;

    const-string v1, "mole-gpu-watch"

    invoke-direct {v0, v1}, Landroid/os/HandlerThread;-><init>(Ljava/lang/String;)V

    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->gpuThread:Landroid/os/HandlerThread;

    .line 401
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->gpuThread:Landroid/os/HandlerThread;

    invoke-virtual {v0}, Landroid/os/HandlerThread;->start()V

    .line 402
    new-instance v0, Landroid/os/Handler;

    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->gpuThread:Landroid/os/HandlerThread;

    invoke-virtual {v1}, Landroid/os/HandlerThread;->getLooper()Landroid/os/Looper;

    move-result-object v1

    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V

    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->gpuHandler:Landroid/os/Handler;

    .line 403
    const/4 v0, 0x1

    iput-boolean v0, p0, Lcom/taomee/mole/MainActivity;->gpuWatchOn:Z

    .line 404
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->gpuHandler:Landroid/os/Handler;

    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->gpuWatch:Ljava/lang/Runnable;

    const-wide/16 v2, 0x1f40

    invoke-virtual {v0, v1, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 407
    goto :goto_0

    .line 405
    :catchall_0
    move-exception v0

    .line 406
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "GPU \u770b\u62a4\u542f\u52a8\u5931\u8d25\uff08\u4e0d\u5f71\u54cd\u6e38\u620f\uff09\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "MoleShell"

    invoke-static {v1, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 408
    :goto_0
    return-void
.end method

.method private stopGpuWatch()V
    .locals 1

    .line 411
    const/4 v0, 0x0

    iput-boolean v0, p0, Lcom/taomee/mole/MainActivity;->gpuWatchOn:Z

    .line 413
    :try_start_0
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->gpuThread:Landroid/os/HandlerThread;

    if-eqz v0, :cond_0

    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->gpuThread:Landroid/os/HandlerThread;

    invoke-virtual {v0}, Landroid/os/HandlerThread;->quitSafely()Z
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 415
    :cond_0
    goto :goto_0

    .line 414
    :catchall_0
    move-exception v0

    .line 416
    :goto_0
    const/4 v0, 0x0

    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->gpuThread:Landroid/os/HandlerThread;

    .line 417
    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->gpuHandler:Landroid/os/Handler;

    .line 418
    return-void
.end method

.method private static unmaskStr(Ljava/lang/String;)Ljava/lang/String;
    .locals 4

    .line 923
    const/4 v0, 0x0

    invoke-static {p0, v0}, Landroid/util/Base64;->decode(Ljava/lang/String;I)[B

    move-result-object p0

    .line 924
    new-instance v1, Ljava/lang/StringBuilder;

    array-length v2, p0

    invoke-direct {v1, v2}, Ljava/lang/StringBuilder;-><init>(I)V

    .line 925
    array-length v2, p0

    :goto_0
    if-ge v0, v2, :cond_0

    aget-byte v3, p0, v0

    and-int/lit16 v3, v3, 0xff

    xor-int/lit8 v3, v3, 0x5a

    int-to-char v3, v3

    invoke-virtual {v1, v3}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    add-int/lit8 v0, v0, 0x1

    goto :goto_0

    .line 926
    :cond_0
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0
.end method

.method private upstream(Landroid/webkit/WebResourceRequest;)Landroid/webkit/WebResourceResponse;
    .locals 21

    .line 1166
    move-object/from16 v1, p0

    const-string v2, " "

    const-string v3, "range"

    invoke-interface/range {p1 .. p1}, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;

    move-result-object v0

    invoke-virtual {v0}, Landroid/net/Uri;->toString()Ljava/lang/String;

    move-result-object v4

    .line 1170
    nop

    .line 1172
    const/4 v5, 0x1

    const/4 v6, 0x0

    :try_start_0
    invoke-interface/range {p1 .. p1}, Landroid/webkit/WebResourceRequest;->getRequestHeaders()Ljava/util/Map;

    move-result-object v0

    .line 1173
    if-eqz v0, :cond_1

    .line 1174
    invoke-interface {v0}, Ljava/util/Map;->keySet()Ljava/util/Set;

    move-result-object v0

    invoke-interface {v0}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    move-result-object v0

    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    move-result v7

    if-eqz v7, :cond_1

    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v7

    check-cast v7, Ljava/lang/String;

    .line 1175
    if-eqz v7, :cond_0

    invoke-virtual {v7, v3}, Ljava/lang/String;->equalsIgnoreCase(Ljava/lang/String;)Z

    move-result v7
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    if-eqz v7, :cond_0

    .line 1176
    nop

    .line 1177
    const/4 v0, 0x1

    goto :goto_1

    .line 1179
    :cond_0
    goto :goto_0

    .line 1182
    :cond_1
    const/4 v0, 0x0

    :goto_1
    goto :goto_2

    .line 1181
    :catchall_0
    move-exception v0

    const/4 v0, 0x0

    .line 1183
    :goto_2
    if-nez v0, :cond_2

    invoke-static {v4}, Lcom/taomee/mole/HttpCache;->cacheable(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_2

    iget-object v0, v1, Lcom/taomee/mole/MainActivity;->cache:Lcom/taomee/mole/HttpCache;

    if-eqz v0, :cond_2

    const/4 v7, 0x1

    goto :goto_3

    :cond_2
    const/4 v7, 0x0

    .line 1186
    :goto_3
    const-string v8, "public, max-age=604800"

    const-string v9, "MoleShell"

    const-string v10, "Cache-Control"

    if-eqz v7, :cond_3

    .line 1187
    iget-object v0, v1, Lcom/taomee/mole/MainActivity;->cache:Lcom/taomee/mole/HttpCache;

    invoke-virtual {v0, v4}, Lcom/taomee/mole/HttpCache;->hit(Ljava/lang/String;)Ljava/io/File;

    move-result-object v0

    .line 1188
    if-eqz v0, :cond_3

    .line 1190
    :try_start_1
    invoke-static {}, Lcom/taomee/mole/MainActivity;->corsHeaders()Ljava/util/Map;

    move-result-object v15

    .line 1191
    invoke-interface {v15, v10, v8}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1192
    new-instance v18, Landroid/webkit/WebResourceResponse;

    invoke-static {v4}, Lcom/taomee/mole/MainActivity;->guessMime(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v12

    const-string v16, "OK"

    new-instance v14, Ljava/io/FileInputStream;

    invoke-direct {v14, v0}, Ljava/io/FileInputStream;-><init>(Ljava/io/File;)V

    const/4 v13, 0x0

    const/16 v0, 0xc8

    move-object/from16 v11, v18

    move-object/from16 v17, v14

    move v14, v0

    move-object v0, v15

    move-object/from16 v15, v16

    move-object/from16 v16, v0

    invoke-direct/range {v11 .. v17}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/util/Map;Ljava/io/InputStream;)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    return-object v18

    .line 1194
    :catchall_1
    move-exception v0

    .line 1195
    new-instance v11, Ljava/lang/StringBuilder;

    invoke-direct {v11}, Ljava/lang/StringBuilder;-><init>()V

    const-string v12, "\u7f13\u5b58\u547d\u4e2d\u4f46\u8bfb\u53d6\u5931\u8d25\uff0c\u8f6c\u56de\u7f51\u7edc\uff1a"

    invoke-virtual {v11, v12}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v11

    invoke-virtual {v11, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v9, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 1200
    :cond_3
    nop

    .line 1202
    const/4 v11, 0x0

    :try_start_2
    new-instance v0, Ljava/net/URL;

    invoke-direct {v0, v4}, Ljava/net/URL;-><init>(Ljava/lang/String;)V

    invoke-virtual {v0}, Ljava/net/URL;->openConnection()Ljava/net/URLConnection;

    move-result-object v0

    move-object v12, v0

    check-cast v12, Ljava/net/HttpURLConnection;
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_a

    .line 1203
    :try_start_3
    const-string v0, "GET"

    invoke-virtual {v12, v0}, Ljava/net/HttpURLConnection;->setRequestMethod(Ljava/lang/String;)V

    .line 1204
    const/16 v0, 0x3a98

    invoke-virtual {v12, v0}, Ljava/net/HttpURLConnection;->setConnectTimeout(I)V

    .line 1205
    const/16 v0, 0x61a8

    invoke-virtual {v12, v0}, Ljava/net/HttpURLConnection;->setReadTimeout(I)V

    .line 1206
    invoke-virtual {v12, v5}, Ljava/net/HttpURLConnection;->setInstanceFollowRedirects(Z)V

    .line 1207
    const-string v0, "User-Agent"

    iget-object v5, v1, Lcom/taomee/mole/MainActivity;->ua:Ljava/lang/String;

    invoke-virtual {v12, v0, v5}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 1208
    const-string v0, "Referer"

    new-instance v5, Ljava/lang/StringBuilder;

    invoke-direct {v5}, Ljava/lang/StringBuilder;-><init>()V

    const-string v13, "http://"

    invoke-virtual {v5, v13}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-interface/range {p1 .. p1}, Landroid/webkit/WebResourceRequest;->getUrl()Landroid/net/Uri;

    move-result-object v13

    invoke-virtual {v13}, Landroid/net/Uri;->getHost()Ljava/lang/String;

    move-result-object v13

    invoke-virtual {v5, v13}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    const-string v13, "/"

    invoke-virtual {v5, v13}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v5

    invoke-virtual {v5}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v12, v0, v5}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 1209
    const-string v0, "Accept"

    const-string v5, "*/*"

    invoke-virtual {v12, v0, v5}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 1210
    const-string v0, "Accept-Encoding"

    const-string v5, "identity"

    invoke-virtual {v12, v0, v5}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V

    .line 1212
    invoke-interface/range {p1 .. p1}, Landroid/webkit/WebResourceRequest;->getRequestHeaders()Ljava/util/Map;

    move-result-object v0
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_9

    .line 1213
    if-eqz v0, :cond_7

    .line 1214
    :try_start_4
    invoke-interface {v0}, Ljava/util/Map;->entrySet()Ljava/util/Set;

    move-result-object v0

    invoke-interface {v0}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    move-result-object v5

    :goto_4
    invoke-interface {v5}, Ljava/util/Iterator;->hasNext()Z

    move-result v0

    if-eqz v0, :cond_7

    invoke-interface {v5}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/util/Map$Entry;

    .line 1215
    invoke-interface {v0}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    move-result-object v13

    check-cast v13, Ljava/lang/String;

    .line 1216
    if-nez v13, :cond_4

    goto :goto_4

    .line 1217
    :cond_4
    sget-object v14, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {v13, v14}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object v14

    .line 1218
    const-string v15, "accept"

    invoke-virtual {v14, v15}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v15

    if-nez v15, :cond_5

    const-string v15, "accept-language"

    invoke-virtual {v14, v15}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v15

    if-nez v15, :cond_5

    const-string v15, "x-requested-with"

    .line 1219
    invoke-virtual {v14, v15}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v15

    if-nez v15, :cond_5

    invoke-virtual {v14, v3}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v14
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_3

    if-eqz v14, :cond_6

    .line 1221
    :cond_5
    :try_start_5
    invoke-interface {v0}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/String;

    invoke-virtual {v12, v13, v0}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_2

    .line 1223
    goto :goto_5

    .line 1222
    :catchall_2
    move-exception v0

    .line 1225
    :cond_6
    :goto_5
    goto :goto_4

    .line 1290
    :catchall_3
    move-exception v0

    goto/16 :goto_d

    .line 1228
    :cond_7
    nop

    .line 1230
    :try_start_6
    invoke-static {}, Landroid/webkit/CookieManager;->getInstance()Landroid/webkit/CookieManager;

    move-result-object v0

    invoke-virtual {v0, v4}, Landroid/webkit/CookieManager;->getCookie(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_4

    .line 1232
    goto :goto_6

    .line 1231
    :catchall_4
    move-exception v0

    move-object v0, v11

    .line 1233
    :goto_6
    if-eqz v0, :cond_8

    :try_start_7
    invoke-virtual {v0}, Ljava/lang/String;->isEmpty()Z

    move-result v3

    if-nez v3, :cond_8

    const-string v3, "Cookie"

    invoke-virtual {v12, v3, v0}, Ljava/net/HttpURLConnection;->setRequestProperty(Ljava/lang/String;Ljava/lang/String;)V
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_3

    .line 1235
    :cond_8
    :try_start_8
    invoke-virtual {v12}, Ljava/net/HttpURLConnection;->getResponseCode()I

    move-result v3

    .line 1236
    invoke-static {v4}, Lcom/taomee/mole/MainActivity;->guessMime(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v0

    .line 1237
    invoke-virtual {v12}, Ljava/net/HttpURLConnection;->getContentType()Ljava/lang/String;

    move-result-object v5
    :try_end_8
    .catchall {:try_start_8 .. :try_end_8} :catchall_9

    .line 1238
    if-eqz v5, :cond_9

    :try_start_9
    invoke-virtual {v5}, Ljava/lang/String;->isEmpty()Z

    move-result v13

    if-nez v13, :cond_9

    const-string v0, ";"

    invoke-virtual {v5, v0}, Ljava/lang/String;->split(Ljava/lang/String;)[Ljava/lang/String;

    move-result-object v0

    aget-object v0, v0, v6

    invoke-virtual {v0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v0
    :try_end_9
    .catchall {:try_start_9 .. :try_end_9} :catchall_3

    move-object v14, v0

    goto :goto_7

    .line 1240
    :cond_9
    move-object v14, v0

    :goto_7
    :try_start_a
    invoke-virtual {v12}, Ljava/net/HttpURLConnection;->getHeaderFields()Ljava/util/Map;

    move-result-object v0

    .line 1241
    const-string v5, "Set-Cookie"

    invoke-interface {v0, v5}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v5

    check-cast v5, Ljava/util/List;
    :try_end_a
    .catchall {:try_start_a .. :try_end_a} :catchall_9

    .line 1242
    if-nez v5, :cond_a

    :try_start_b
    const-string v5, "set-cookie"

    invoke-interface {v0, v5}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    move-result-object v0

    move-object v5, v0

    check-cast v5, Ljava/util/List;

    .line 1243
    :cond_a
    if-eqz v5, :cond_b

    .line 1244
    invoke-interface {v5}, Ljava/util/List;->iterator()Ljava/util/Iterator;

    move-result-object v5

    :goto_8
    invoke-interface {v5}, Ljava/util/Iterator;->hasNext()Z

    move-result v0

    if-eqz v0, :cond_b

    invoke-interface {v5}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    move-result-object v0

    check-cast v0, Ljava/lang/String;
    :try_end_b
    .catchall {:try_start_b .. :try_end_b} :catchall_3

    .line 1246
    :try_start_c
    invoke-static {}, Landroid/webkit/CookieManager;->getInstance()Landroid/webkit/CookieManager;

    move-result-object v6

    invoke-virtual {v6, v4, v0}, Landroid/webkit/CookieManager;->setCookie(Ljava/lang/String;Ljava/lang/String;)V
    :try_end_c
    .catchall {:try_start_c .. :try_end_c} :catchall_5

    .line 1248
    goto :goto_9

    .line 1247
    :catchall_5
    move-exception v0

    .line 1249
    :goto_9
    goto :goto_8

    .line 1252
    :cond_b
    const/16 v0, 0x190

    if-lt v3, v0, :cond_c

    :try_start_d
    invoke-virtual {v12}, Ljava/net/HttpURLConnection;->getErrorStream()Ljava/io/InputStream;

    move-result-object v0
    :try_end_d
    .catchall {:try_start_d .. :try_end_d} :catchall_3

    goto :goto_a

    :cond_c
    :try_start_e
    invoke-virtual {v12}, Ljava/net/HttpURLConnection;->getInputStream()Ljava/io/InputStream;

    move-result-object v0

    :goto_a
    move-object v5, v0

    .line 1253
    if-nez v5, :cond_d

    return-object v11

    .line 1255
    :cond_d
    invoke-static {}, Lcom/taomee/mole/MainActivity;->corsHeaders()Ljava/util/Map;

    move-result-object v6
    :try_end_e
    .catchall {:try_start_e .. :try_end_e} :catchall_9

    .line 1256
    nop

    .line 1258
    :try_start_f
    invoke-virtual {v12}, Ljava/net/HttpURLConnection;->getContentLength()I

    move-result v0
    :try_end_f
    .catchall {:try_start_f .. :try_end_f} :catchall_6

    move-object/from16 v20, v12

    int-to-long v11, v0

    .line 1260
    goto :goto_b

    .line 1259
    :catchall_6
    move-exception v0

    move-object/from16 v20, v12

    const-wide/16 v11, -0x1

    .line 1263
    :goto_b
    const/16 v0, 0xc8

    if-eqz v7, :cond_11

    if-ne v3, v0, :cond_11

    const-wide/16 v15, 0x0

    cmp-long v7, v11, v15

    if-ltz v7, :cond_e

    const-wide/32 v15, 0x600000

    cmp-long v7, v11, v15

    if-gtz v7, :cond_11

    .line 1264
    :cond_e
    const/high16 v0, 0x600000

    :try_start_10
    invoke-static {v5, v0}, Lcom/taomee/mole/MainActivity;->readCap(Ljava/io/InputStream;I)[B

    move-result-object v2

    .line 1265
    array-length v7, v2

    if-lez v7, :cond_10

    array-length v7, v2
    :try_end_10
    .catchall {:try_start_10 .. :try_end_10} :catchall_8

    if-ge v7, v0, :cond_10

    .line 1267
    :try_start_11
    invoke-virtual {v5}, Ljava/io/InputStream;->close()V
    :try_end_11
    .catchall {:try_start_11 .. :try_end_11} :catchall_7

    .line 1269
    goto :goto_c

    .line 1268
    :catchall_7
    move-exception v0

    .line 1270
    :goto_c
    :try_start_12
    iget-object v0, v1, Lcom/taomee/mole/MainActivity;->cache:Lcom/taomee/mole/HttpCache;

    invoke-virtual {v0, v4, v2}, Lcom/taomee/mole/HttpCache;->store(Ljava/lang/String;[B)V

    .line 1271
    invoke-interface {v6, v10, v8}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1272
    invoke-static {v14}, Lcom/taomee/mole/MainActivity;->isBinary(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_f

    .line 1273
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v5, "\u4ee3\u53d6\u5e76\u7f13\u5b58 "

    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    array-length v5, v2

    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v5, "B "

    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-static {v4}, Lcom/taomee/mole/MainActivity;->basename(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v5

    invoke-virtual {v0, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v9, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 1275
    :cond_f
    new-instance v0, Landroid/webkit/WebResourceResponse;

    invoke-static/range {v20 .. v20}, Lcom/taomee/mole/MainActivity;->safeReason(Ljava/net/HttpURLConnection;)Ljava/lang/String;

    move-result-object v17

    new-instance v5, Ljava/io/ByteArrayInputStream;

    invoke-direct {v5, v2}, Ljava/io/ByteArrayInputStream;-><init>([B)V

    const/4 v15, 0x0

    move-object v13, v0

    move/from16 v16, v3

    move-object/from16 v18, v6

    move-object/from16 v19, v5

    invoke-direct/range {v13 .. v19}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/util/Map;Ljava/io/InputStream;)V

    return-object v0

    .line 1279
    :cond_10
    invoke-interface {v6, v10, v8}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1280
    new-instance v0, Landroid/webkit/WebResourceResponse;

    invoke-static/range {v20 .. v20}, Lcom/taomee/mole/MainActivity;->safeReason(Ljava/net/HttpURLConnection;)Ljava/lang/String;

    move-result-object v17

    new-instance v7, Ljava/io/SequenceInputStream;

    new-instance v8, Ljava/io/ByteArrayInputStream;

    invoke-direct {v8, v2}, Ljava/io/ByteArrayInputStream;-><init>([B)V

    invoke-direct {v7, v8, v5}, Ljava/io/SequenceInputStream;-><init>(Ljava/io/InputStream;Ljava/io/InputStream;)V

    const/4 v15, 0x0

    move-object v13, v0

    move/from16 v16, v3

    move-object/from16 v18, v6

    move-object/from16 v19, v7

    invoke-direct/range {v13 .. v19}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/util/Map;Ljava/io/InputStream;)V

    return-object v0

    .line 1285
    :cond_11
    const-string v7, "no-store"

    invoke-interface {v6, v10, v7}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1286
    if-lt v3, v0, :cond_12

    const/16 v0, 0x12c

    if-ge v3, v0, :cond_12

    invoke-static {v14}, Lcom/taomee/mole/MainActivity;->isBinary(Ljava/lang/String;)Z

    move-result v0

    if-nez v0, :cond_12

    .line 1287
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v7, "\u4ee3\u53d6 "

    invoke-virtual {v0, v7}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v3}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v14}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v9, v0}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 1289
    :cond_12
    new-instance v0, Landroid/webkit/WebResourceResponse;

    invoke-static/range {v20 .. v20}, Lcom/taomee/mole/MainActivity;->safeReason(Ljava/net/HttpURLConnection;)Ljava/lang/String;

    move-result-object v17

    const/4 v15, 0x0

    move-object v13, v0

    move/from16 v16, v3

    move-object/from16 v18, v6

    move-object/from16 v19, v5

    invoke-direct/range {v13 .. v19}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/util/Map;Ljava/io/InputStream;)V
    :try_end_12
    .catchall {:try_start_12 .. :try_end_12} :catchall_8

    return-object v0

    .line 1290
    :catchall_8
    move-exception v0

    move-object/from16 v12, v20

    goto :goto_d

    :catchall_9
    move-exception v0

    move-object/from16 v20, v12

    goto :goto_d

    :catchall_a
    move-exception v0

    const/4 v12, 0x0

    .line 1291
    :goto_d
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u4ee3\u53d6\u5931\u8d25\uff0c\u4ea4\u56de WebView \u539f\u751f\u5904\u7406\uff1a"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, v4}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v3, " ("

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v2, ")"

    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    invoke-static {v9, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 1292
    if-eqz v12, :cond_13

    .line 1294
    :try_start_13
    invoke-virtual {v12}, Ljava/net/HttpURLConnection;->disconnect()V
    :try_end_13
    .catchall {:try_start_13 .. :try_end_13} :catchall_b

    .line 1296
    goto :goto_e

    .line 1295
    :catchall_b
    move-exception v0

    .line 1298
    :cond_13
    :goto_e
    const/4 v2, 0x0

    return-object v2
.end method

.method private wasmResponse(Ljava/lang/String;)Landroid/webkit/WebResourceResponse;
    .locals 9

    .line 1115
    const-string v0, "MoleShell"

    :try_start_0
    new-instance v7, Ljava/util/zip/GZIPInputStream;

    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getAssets()Landroid/content/res/AssetManager;

    move-result-object v1

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "ruffle/"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    const-string v3, ".gz"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    invoke-virtual {v1, v2}, Landroid/content/res/AssetManager;->open(Ljava/lang/String;)Ljava/io/InputStream;

    move-result-object v1

    invoke-direct {v7, v1}, Ljava/util/zip/GZIPInputStream;-><init>(Ljava/io/InputStream;)V

    .line 1116
    new-instance v6, Ljava/util/HashMap;

    invoke-direct {v6}, Ljava/util/HashMap;-><init>()V

    .line 1117
    const-string v1, "Access-Control-Allow-Origin"

    const-string v2, "*"

    invoke-interface {v6, v1, v2}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1118
    const-string v1, "Cache-Control"

    const-string v2, "no-store"

    invoke-interface {v6, v1, v2}, Ljava/util/Map;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 1119
    new-instance v1, Ljava/lang/StringBuilder;

    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "\u4e0b\u53d1 wasm\uff1a"

    invoke-virtual {v1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v1

    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v1

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 1120
    new-instance v8, Landroid/webkit/WebResourceResponse;

    const-string v2, "application/wasm"

    const-string v5, "OK"

    const/4 v3, 0x0

    const/16 v4, 0xc8

    move-object v1, v8

    invoke-direct/range {v1 .. v7}, Landroid/webkit/WebResourceResponse;-><init>(Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;Ljava/util/Map;Ljava/io/InputStream;)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    return-object v8

    .line 1121
    :catchall_0
    move-exception v1

    .line 1122
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "wasm \u4e0b\u53d1\u5931\u8d25\uff1a"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v2, " \u2014\u2014 Ruffle \u8bf7\u6c42\u7684 wasm \u540d\u4e0e assets \u4e0d\u5339\u914d"

    invoke-virtual {p1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1, v1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 1123
    const/4 p1, 0x0

    return-object p1
.end method


# virtual methods
.method public onBackPressed()V
    .locals 1

    .line 782
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    if-eqz v0, :cond_0

    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->canGoBack()Z

    move-result v0

    if-eqz v0, :cond_0

    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->goBack()V

    goto :goto_0

    .line 783
    :cond_0
    invoke-super {p0}, Landroid/app/Activity;->onBackPressed()V

    .line 784
    :goto_0
    return-void
.end method

.method public onConfigurationChanged(Landroid/content/res/Configuration;)V
    .locals 3

    .line 770
    invoke-super {p0, p1}, Landroid/app/Activity;->onConfigurationChanged(Landroid/content/res/Configuration;)V

    .line 771
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->goImmersive()V

    .line 772
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    if-eqz v0, :cond_0

    .line 773
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    const-string v1, "(function(){try{window.dispatchEvent(new Event(\'resize\'));}catch(e){}})();"

    const/4 v2, 0x0

    invoke-virtual {v0, v1, v2}, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String;Landroid/webkit/ValueCallback;)V

    .line 776
    :cond_0
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "\u7a97\u53e3\u53d8\u5316 \u2192 "

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget v1, p1, Landroid/content/res/Configuration;->screenWidthDp:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, "x"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget v1, p1, Landroid/content/res/Configuration;->screenHeightDp:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, "dp / orientation="

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget p1, p1, Landroid/content/res/Configuration;->orientation:I

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    const-string v0, "MoleShell"

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 778
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .locals 4

    .line 654
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V

    .line 655
    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getWindow()Landroid/view/Window;

    move-result-object p1

    const/16 v0, 0x80

    invoke-virtual {p1, v0}, Landroid/view/Window;->addFlags(I)V

    .line 660
    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getResources()Landroid/content/res/Resources;

    move-result-object p1

    invoke-virtual {p1}, Landroid/content/res/Resources;->getConfiguration()Landroid/content/res/Configuration;

    move-result-object p1

    iget p1, p1, Landroid/content/res/Configuration;->smallestScreenWidthDp:I

    .line 661
    const/16 v0, 0x258

    const/4 v1, 0x1

    if-lt p1, v0, :cond_0

    const/4 v0, 0x1

    goto :goto_0

    :cond_0
    const/4 v0, 0x0

    .line 662
    :goto_0
    if-eqz v0, :cond_1

    .line 663
    const/16 v2, 0xa

    goto :goto_1

    .line 664
    :cond_1
    const/4 v2, 0x6

    .line 662
    :goto_1
    invoke-virtual {p0, v2}, Lcom/taomee/mole/MainActivity;->setRequestedOrientation(I)V

    .line 665
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u5c4f\u5e55\uff1asmallestWidthDp="

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v2, " \u2192 "

    invoke-virtual {p1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    .line 666
    if-eqz v0, :cond_2

    const-string v0, "\u8ddf\u968f\u4f20\u611f\u5668\uff08\u5e73\u677f/\u684c\u9762\uff09"

    goto :goto_2

    :cond_2
    const-string v0, "\u9501\u5b9a\u6a2a\u5c4f\uff08\u624b\u673a\uff09"

    :goto_2
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    .line 665
    const-string v0, "MoleShell"

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 669
    new-instance p1, Lcom/taomee/mole/SocketBridge;

    invoke-direct {p1}, Lcom/taomee/mole/SocketBridge;-><init>()V

    iput-object p1, p0, Lcom/taomee/mole/MainActivity;->bridge:Lcom/taomee/mole/SocketBridge;

    .line 670
    iget-object p1, p0, Lcom/taomee/mole/MainActivity;->bridge:Lcom/taomee/mole/SocketBridge;

    invoke-virtual {p1}, Lcom/taomee/mole/SocketBridge;->start()V

    .line 675
    :try_start_0
    new-instance p1, Lcom/taomee/mole/HttpCache;

    invoke-virtual {p0}, Lcom/taomee/mole/MainActivity;->getCacheDir()Ljava/io/File;

    move-result-object v2

    invoke-direct {p1, v2}, Lcom/taomee/mole/HttpCache;-><init>(Ljava/io/File;)V

    iput-object p1, p0, Lcom/taomee/mole/MainActivity;->cache:Lcom/taomee/mole/HttpCache;
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 678
    goto :goto_3

    .line 676
    :catchall_0
    move-exception p1

    .line 677
    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "\u78c1\u76d8\u7f13\u5b58\u521d\u59cb\u5316\u5931\u8d25\uff0c\u9000\u5316\u4e3a\u76f4\u8fde\uff1a"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/Object;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 680
    :goto_3
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->loadTargets()V

    .line 682
    new-instance p1, Ljava/lang/StringBuilder;

    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V

    const-string v2, "socketProxy \u76ee\u6807\u5df2\u5c31\u7eea\uff0c\u5171 "

    invoke-virtual {p1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    iget-object v2, p0, Lcom/taomee/mole/MainActivity;->targets:Ljava/util/LinkedHashSet;

    invoke-virtual {v2}, Ljava/util/LinkedHashSet;->size()I

    move-result v2

    invoke-virtual {p1, v2}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object p1

    const-string v2, " \u6761"

    invoke-virtual {p1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object p1

    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p1

    invoke-static {v0, p1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    .line 685
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->evaluateLoadLevel()V

    .line 690
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->startGpuWatch()V

    .line 692
    new-instance p1, Landroid/widget/FrameLayout;

    invoke-direct {p1, p0}, Landroid/widget/FrameLayout;-><init>(Landroid/content/Context;)V

    .line 693
    const/high16 v0, -0x1000000

    invoke-virtual {p1, v0}, Landroid/widget/FrameLayout;->setBackgroundColor(I)V

    .line 695
    new-instance v0, Landroid/webkit/WebView;

    invoke-direct {v0, p0}, Landroid/webkit/WebView;-><init>(Landroid/content/Context;)V

    iput-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    .line 696
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    new-instance v2, Landroid/widget/FrameLayout$LayoutParams;

    const/4 v3, -0x1

    invoke-direct {v2, v3, v3}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V

    invoke-virtual {p1, v0, v2}, Landroid/widget/FrameLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

    .line 698
    invoke-virtual {p0, p1}, Lcom/taomee/mole/MainActivity;->setContentView(Landroid/view/View;)V

    .line 701
    :try_start_1
    invoke-static {v1}, Landroid/webkit/WebView;->setWebContentsDebuggingEnabled(Z)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_1

    .line 703
    goto :goto_4

    .line 702
    :catchall_1
    move-exception p1

    .line 705
    :goto_4
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->configure()V

    .line 706
    iget-object p1, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    const-string v0, "http://mole.61.com/__mole_shell__"

    invoke-virtual {p1, v0}, Landroid/webkit/WebView;->loadUrl(Ljava/lang/String;)V

    .line 707
    return-void
.end method

.method protected onDestroy()V
    .locals 2

    .line 749
    const/4 v0, 0x0

    iput-boolean v0, p0, Lcom/taomee/mole/MainActivity;->gpuWatchOn:Z

    .line 750
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->stopGpuWatch()V

    .line 751
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->markCleanExit()V

    .line 752
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->bridge:Lcom/taomee/mole/SocketBridge;

    if-eqz v0, :cond_0

    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->bridge:Lcom/taomee/mole/SocketBridge;

    invoke-virtual {v0}, Lcom/taomee/mole/SocketBridge;->stop()V

    .line 753
    :cond_0
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    if-eqz v0, :cond_2

    .line 754
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->getParent()Landroid/view/ViewParent;

    move-result-object v0

    check-cast v0, Landroid/view/ViewGroup;

    .line 755
    if-eqz v0, :cond_1

    iget-object v1, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0, v1}, Landroid/view/ViewGroup;->removeView(Landroid/view/View;)V

    .line 756
    :cond_1
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    const-string v1, "about:blank"

    invoke-virtual {v0, v1}, Landroid/webkit/WebView;->loadUrl(Ljava/lang/String;)V

    .line 757
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->destroy()V

    .line 759
    :cond_2
    invoke-super {p0}, Landroid/app/Activity;->onDestroy()V

    .line 760
    return-void
.end method

.method protected onPause()V
    .locals 3

    .line 719
    invoke-super {p0}, Landroid/app/Activity;->onPause()V

    .line 722
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    const-string v1, "(function(){try{var n=document.querySelectorAll(\'ruffle-player,ruffle-object,ruffle-embed\');for(var i=0;i<n.length;i++){try{n[i].pause&&n[i].pause();}catch(e){}}window.dispatchEvent(new Event(\'blur\'));}catch(e){}})();"

    const/4 v2, 0x0

    invoke-virtual {v0, v1, v2}, Landroid/webkit/WebView;->evaluateJavascript(Ljava/lang/String;Landroid/webkit/ValueCallback;)V

    .line 723
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->onPause()V

    .line 724
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->pauseTimers()V

    .line 725
    return-void
.end method

.method protected onResume()V
    .locals 1

    .line 711
    invoke-super {p0}, Landroid/app/Activity;->onResume()V

    .line 712
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->onResume()V

    .line 713
    iget-object v0, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    invoke-virtual {v0}, Landroid/webkit/WebView;->resumeTimers()V

    .line 714
    invoke-direct {p0}, Lcom/taomee/mole/MainActivity;->goImmersive()V

    .line 715
    return-void
.end method

.method public onTrimMemory(I)V
    .locals 2

    .line 734
    invoke-super {p0, p1}, Landroid/app/Activity;->onTrimMemory(I)V

    .line 735
    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    const-string v1, "onTrimMemory("

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    const-string v1, ") \u8d1f\u8f7d\u6863="

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v0

    iget v1, p0, Lcom/taomee/mole/MainActivity;->loadLevel:I

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    move-result-object v0

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v0

    const-string v1, "MoleShell"

    invoke-static {v1, v0}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I

    .line 736
    const/16 v0, 0x50

    if-lt p1, v0, :cond_0

    iget-object p1, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    if-eqz p1, :cond_0

    .line 738
    :try_start_0
    iget-object p1, p0, Lcom/taomee/mole/MainActivity;->web:Landroid/webkit/WebView;

    const/4 v0, 0x0

    invoke-virtual {p1, v0}, Landroid/webkit/WebView;->clearCache(Z)V

    .line 739
    const-string p1, "\u5df2\u91ca\u653e WebView HTTP \u7f13\u5b58\uff08\u8f6c\u540e\u53f0\uff09"

    invoke-static {v1, p1}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/String;)I
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_0

    .line 741
    goto :goto_0

    .line 740
    :catchall_0
    move-exception p1

    .line 743
    :cond_0
    :goto_0
    return-void
.end method
