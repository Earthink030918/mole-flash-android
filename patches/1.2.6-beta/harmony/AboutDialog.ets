// =====================================================================
// AboutDialog.ets —— 纯血鸿蒙（HarmonyOS NEXT / ArkWeb）侧的原生关于弹窗
// =====================================================================
// 状态：**参考实现，本轮未编译进 HAP。**
//   开发机上的 DevEco Studio 与 SDK 已删除，没有 hvigor / ets-loader，
//   打不出新的 .abc；本仓库里也没有 ArkTS 工程（只有 java / manifest / web）。
//   所以这一版只在网页侧把调用点写好（NativeBridge.showAbout(json)），
//   等 DevEco 回来说一声，把下面这三个片段贴进 EntryAbility 即可。
//
// 设计要点：
//   1. 用 CustomDialog 而不是 AlertDialog.show：
//      AlertDialog.show 的 message 只收 string | Resource，**没法只让一段变红**。
//      CustomDialog 是系统原生弹窗容器（独立窗口、系统返回键、系统字体缩放、
//      无障碍朗读都归系统管），内部用 Text 就能逐段上色。
//   2. 「装一次弹一次」记在 preferences（对应安卓的 SharedPreferences）：
//      存的是 BundleInfo.updateTime（安装戳），同一份安装里稳定、覆盖安装会变，
//      用户清 WebView 缓存 / localStorage 之后照样不重复骚扰。
//   4. 1.2.7-beta(r2) 同步：payload 多了 note / by / dismiss 三个字段，
//      正文末尾一行小字、右下角落款、以及「不再弹出」按钮；判定改安装戳。
//   3. 文案由网页侧通过 JSON 传进来，**不在 ArkTS 里再存一份** ——
//      改文案只改 shell.html 一处，两端不会漂。
//      收到畸形 JSON 时退回内置的一份最小文案，绝不因为解析失败就什么都不弹。
// =====================================================================

import { common, bundleManager } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';

const STORE_NAME: string = 'mole_shell';
// 1.2.7-beta(r2)：这个键存的不再是布尔值，而是「安装戳」（BundleInfo.updateTime）。
// 同一份安装里它不变，覆盖安装后系统会刷新它 —— 于是「装一次弹一次」。
const ABOUT_KEY: string = 'mole_about_stamp';

export interface AboutLine {
  t: string;
  red: boolean;
}

interface AboutPayload {
  title: string;
  lines: AboutLine[];
  ok: string;
  note?: string;      // 正文末尾那行小字
  by?: string;        // 右下角落款
  dismiss?: string;   // 「不再弹出」按钮文案
}

/** 解析失败时的兜底文案（与 shell.html 保持同义） */
const FALLBACK: AboutPayload = {
  title: '关于本作 · 先说三句心里话',
  lines: [
    { t: '谢谢你选择了我这么一个小小的开源项目～能在这里遇见你，真的很开心！♡', red: false },
    { t: '小提醒一下：本作并非摩尔庄园官方项目，仅为第三方爱好者移植，请不要和官方版本的《摩尔庄园》手游混淆哦！！！', red: true },
    { t: '欢迎来到我的小窝一起玩，QQ小窝的群号是：1125775110。本作目前还在开发阶段，遇到问题欢迎随时指出～另外郑重说一句：严禁倒卖，也严禁在二次修改时加入收费弹窗；如果发现任何以此盈利的行为，欢迎大家向我反馈！', red: false }
  ],
  ok: '我知道啦 ♡',
  note: '（每次安装只出现一次，点「不再弹出」就不再打扰你啦）',
  by: 'by 尘墨',
  dismiss: '不再弹出'
};

function parsePayload(json: string): AboutPayload {
  try {
    const o = JSON.parse(json) as AboutPayload;
    if (o && o.lines && o.lines.length > 0) {
      // 老 payload 没有 note / by / dismiss，缺哪补哪，绝不写 undefined 进 Text
      return {
        title: o.title ? o.title : FALLBACK.title,
        lines: o.lines,
        ok: o.ok ? o.ok : FALLBACK.ok,
        note: o.note ? o.note : FALLBACK.note,
        by: o.by ? o.by : FALLBACK.by,
        dismiss: o.dismiss ? o.dismiss : FALLBACK.dismiss
      };
    }
  } catch (e) {
    console.warn('[MoleShell] 关于弹窗 JSON 解析失败：' + e);
  }
  return FALLBACK;
}

// ---------------------------------------------------------------------
// 1) 弹窗本体
// ---------------------------------------------------------------------
@CustomDialog
export struct MoleAboutDialog {
  controller?: CustomDialogController;
  payload: AboutPayload = FALLBACK;

  build() {
    Column({ space: 14 }) {
      Text(this.payload.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1B1B1F')
        .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.payload.lines, (line: AboutLine) => {
            // 第二段（非官方声明）走红字，其余是正文色
            Text(line.t)
              .fontSize(15)
              .lineHeight(24)
              .fontColor(line.red ? '#E23A3A' : '#4A4A50')
              .fontWeight(line.red ? FontWeight.Medium : FontWeight.Normal)
              .width('100%')
          }, (line: AboutLine, i: number) => i.toString())
        }
        .width('100%')
      }
      .constraintSize({ maxHeight: '56%' })
      .scrollBar(BarState.Auto)

      Text(this.payload.note ? this.payload.note : '')
        .fontSize(12)
        .lineHeight(19)
        .fontColor('#8A8A90')
        .width('100%')

      Text(this.payload.by ? this.payload.by : '')
        .fontSize(12)
        .fontColor('#8A8A90')
        .width('100%')
        .textAlign(TextAlign.End)   // 右下角落款

      Row({ space: 10 }) {
        // 「不再弹出」在左、「我知道啦」在右 —— 与安卓 neutral/positive 的位置一致
        Button(this.payload.dismiss ? this.payload.dismiss : '不再弹出')
          .layoutWeight(1)
          .height(42)
          .fontSize(15)
          .backgroundColor('#F2ECE4')
          .fontColor('#5B4A3C')
          .onClick(() => {
            if (this.controller) {
              this.controller.close();
            }
          })
        Button(this.payload.ok)
          .layoutWeight(1)
          .height(42)
          .fontSize(15)
          .backgroundColor('#FFB347')
          .fontColor('#2A1A10')
          .onClick(() => {
            if (this.controller) {
              this.controller.close();
            }
          })
      }
      .width('100%')
    }
    .width('86%')
    .padding(20)
    .backgroundColor('#FFFDF9')
    .borderRadius(18)
  }
}

// ---------------------------------------------------------------------
// 2) 只弹一次的调度
// ---------------------------------------------------------------------
export class MoleAboutHelper {
  private static dialog: CustomDialogController | null = null;

  /** 安装戳：每次安装 / 覆盖安装系统都会刷新；同一份安装里不变。 */
  private static installStamp(): number {
    try {
      const info = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      return info.updateTime;
    } catch (e) {
      const err = e as BusinessError;
      console.warn('[MoleShell] 读取安装戳失败：' + err.code);
      return 0;       // 拿不到就当作没弹过，宁可多弹一次
    }
  }

  private static async seen(ctx: common.UIAbilityContext): Promise<boolean> {
    const stamp = MoleAboutHelper.installStamp();
    if (stamp <= 0) {
      return false;
    }
    try {
      const p = await preferences.getPreferences(ctx, STORE_NAME);
      return (p.getSync(ABOUT_KEY, 0) as number) === stamp;
    } catch (e) {
      const err = e as BusinessError;
      console.warn('[MoleShell] 读取关于弹窗安装戳失败：' + err.code);
      return false;   // 读不到就按「没弹过」处理，宁可多弹一次
    }
  }

  private static async mark(ctx: common.UIAbilityContext): Promise<void> {
    const stamp = MoleAboutHelper.installStamp();
    if (stamp <= 0) {
      return;         // 拿不到戳就不记，否则可能把「已弹过」记成一个永远不匹配的值
    }
    try {
      const p = await preferences.getPreferences(ctx, STORE_NAME);
      p.putSync(ABOUT_KEY, stamp);
      await p.flush();
    } catch (e) {
      const err = e as BusinessError;
      console.warn('[MoleShell] 写入关于弹窗安装戳失败：' + err.code);
    }
  }

  /**
   * @param ctx    EntryAbility 的 UIAbilityContext
   * @param json   来自网页的 payload；空串表示用兜底文案
   * @param force  true = 忽略「只弹一次」（崩溃页的「关于本作」按钮）
   */
  static async show(ctx: common.UIAbilityContext, json: string, force: boolean): Promise<void> {
    if (!force && await MoleAboutHelper.seen(ctx)) {
      return;
    }
    await MoleAboutHelper.mark(ctx);

    const payload = (json && json.length > 0) ? parsePayload(json) : FALLBACK;

    if (MoleAboutHelper.dialog) {
      // 已经有一个实例（用户连点两次），先关掉再开，避免叠窗
      try {
        MoleAboutHelper.dialog.close();
      } catch (e) {
        // 关不掉也无所谓，下面重新建一个
      }
      MoleAboutHelper.dialog = null;
    }

    MoleAboutHelper.dialog = new CustomDialogController({
      builder: MoleAboutDialog({ payload: payload }),
      autoCancel: true,       // 点遮罩关闭：这是「看一遍就好」的声明，不是阻断式流程
      alignment: DialogAlignment.Center,
      customStyle: true,      // 用我们自己给的圆角卡片，别套系统默认白底
    });
    MoleAboutHelper.dialog.open();
  }
}

// ---------------------------------------------------------------------
// 3) 挂到 ArkWeb 的 JS 桥上
//    网页侧调用：NativeBridge.showAbout(JSON.stringify({title, lines, ok}))
//
//    注册（EntryAbility.onWindowStageCreate 里，controller 关联之后）：
//      this.webController.registerJavaScriptProxy(
//        new MoleNativeBridge(this.context), 'NativeBridge', ['showAbout']);
//      this.webController.refresh();
//
//    注意：ArkWeb 的 JS 代理方法在网页侧返回 Promise，网页那层已经
//    只做 fire-and-forget（try/catch 吞掉返回值），不依赖回调。
// ---------------------------------------------------------------------
export class MoleNativeBridge {
  private ctx: common.UIAbilityContext;

  constructor(ctx: common.UIAbilityContext) {
    this.ctx = ctx;
  }

  showAbout(json: string): void {
    console.info('[MoleShell] [js] 关于本作弹窗，force=false');
    MoleAboutHelper.show(this.ctx, json, false).catch((e: BusinessError) => {
      console.warn('[MoleShell] 关于弹窗失败：' + e.code);
    });
  }

  /** 崩溃页的「关于本作」按钮走这条：强制再弹一次 */
  showAboutForce(json: string): void {
    console.info('[MoleShell] [js] 关于本作弹窗，force=true');
    MoleAboutHelper.show(this.ctx, json, true).catch((e: BusinessError) => {
      console.warn('[MoleShell] 关于弹窗失败：' + e.code);
    });
  }
}
