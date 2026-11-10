import { common } from '@kit.AbilityKit';
import { CLUES, ENDINGS, SCENES, STORY_EVENTS } from '../data/StoryCatalog';
import {
  applyChoice,
  createInitialState,
  finalizeDeduction,
  findClue,
  findEnding,
  findScene,
  getChoiceBlockedReason,
  getCurrentEvent,
  getEvidenceScore,
  getPhaseLabel,
  getProgressPercent,
  getSceneProgress,
  isChoiceAvailable,
  isSceneComplete,
  isSceneUnlocked,
  selectScene,
  startNewGame
} from '../domain/GameEngine';
import {
  ChoiceDef,
  ClueDef,
  ENDING_TRUTH,
  EndingDef,
  GameState,
  JournalEntry,
  PHASE_DEDUCTION,
  PHASE_ENDING,
  SCENE_BELL_TOWER,
  SCENE_LAB,
  SCENE_LIBRARY,
  SceneDef,
  StoryEventDef
} from '../models/GameModels';
import { GameRepository } from '../services/GameRepository';

interface NavItem {
  tab: number;
  label: string;
  mark: string;
}

interface SuspectOption {
  id: string;
  name: string;
  role: string;
}

interface MotiveOption {
  id: string;
  title: string;
  detail: string;
}

const NAV_ITEMS: NavItem[] = [
  { tab: 0, label: '调查', mark: '01' },
  { tab: 1, label: '线索', mark: '02' },
  { tab: 2, label: '档案', mark: '03' },
  { tab: 3, label: '推理', mark: '04' }
];

const SUSPECT_OPTIONS: SuspectOption[] = [
  { id: 'zhou_lan', name: '周岚', role: '实验教学助教' },
  { id: 'lin_che', name: '林澈', role: '校园广播站成员' },
  { id: 'xu_heng', name: '顾衡', role: '图书馆值夜员' }
];

const MOTIVE_OPTIONS: MotiveOption[] = [
  { id: 'coverup', title: '保护事故证据', detail: '掩盖系统性问题，却同时阻止数据被销毁。' },
  { id: 'steal_device', title: '转移实验设备', detail: '利用停电把高价值设备带离校园。' },
  { id: 'publicity', title: '制造校园话题', detail: '策划一场失踪事件吸引公众注意。' }
];

@Entry
@Component
struct Index {
  @State gameState: GameState = createInitialState();
  @State screen: string = 'loading';
  @State activeTab: number = 0;
  @State hasSave: boolean = false;
  @State saveIndicator: string = '正在读取本地档案';
  @State saveBusy: boolean = false;
  @State selectedClueId: string = '';
  @State selectedSuspect: string = '';
  @State selectedMotive: string = '';
  @State toastText: string = '';
  @State showToast: boolean = false;
  @State showResetDialog: boolean = false;
  @State contentPulse: number = 1;

  private repository: GameRepository = new GameRepository();

  aboutToAppear(): void {
    this.initialize();
  }

  private async initialize(): Promise<void> {
    try {
      const hostContext = this.getUIContext().getHostContext();
      if (hostContext === undefined) {
        throw new Error('Unable to obtain UI ability context');
      }
      const context = hostContext as common.UIAbilityContext;
      await this.repository.initialize(context);
      const savedState = await this.repository.load();
      if (savedState !== null) {
        this.gameState = savedState;
        this.hasSave = true;
        this.saveIndicator = savedState.lastSavedAt > 0 ?
          `上次存档 ${this.formatClock(savedState.lastSavedAt)}` : '发现未完成档案';
        if (savedState.phase === PHASE_DEDUCTION || savedState.phase === PHASE_ENDING) {
          this.activeTab = 3;
        }
      } else {
        this.gameState = createInitialState();
        this.hasSave = false;
        this.saveIndicator = '自动存档已开启';
      }
      this.screen = 'cover';
    } catch (error) {
      this.gameState = createInitialState();
      this.screen = 'cover';
      this.saveIndicator = '本地存储初始化失败';
      this.notify('本地存储暂不可用，当前进度仅保留在内存中。');
    }
  }

  private async persistState(): Promise<void> {
    this.saveBusy = true;
    try {
      this.gameState.lastSavedAt = Date.now();
      await this.repository.save(this.gameState);
      this.hasSave = true;
      this.saveIndicator = `已存档 ${this.formatClock(this.gameState.lastSavedAt)}`;
    } catch (error) {
      this.saveIndicator = '存档失败 · 请稍后重试';
      this.notify('本次操作已生效，但写入本地存档失败。');
    } finally {
      this.saveBusy = false;
    }
  }

  private openCase(): void {
    this.screen = 'game';
    this.activeTab = this.gameState.phase === PHASE_ENDING ? 3 : 0;
  }

  private async beginNewGame(): Promise<void> {
    this.gameState = startNewGame(this.gameState);
    this.selectedSuspect = '';
    this.selectedMotive = '';
    this.selectedClueId = '';
    this.activeTab = 0;
    this.showResetDialog = false;
    this.screen = 'game';
    await this.persistState();
    this.notify('新案卷已建立，调查从旧图书馆开始。');
  }

  private async handleChoice(choiceId: string): Promise<void> {
    const result = applyChoice(this.gameState, choiceId);
    if (!result.accepted) {
      this.notify(result.message);
      return;
    }
    this.gameState = result.state;
    this.pulseContent();
    if (this.gameState.phase === PHASE_DEDUCTION) {
      this.activeTab = 3;
      this.selectedSuspect = '';
      this.selectedMotive = '';
    }
    await this.persistState();
    this.notify(result.message);
  }

  private async handleSceneSelect(sceneId: string): Promise<void> {
    const result = selectScene(this.gameState, sceneId);
    if (!result.accepted) {
      this.notify(result.message);
      return;
    }
    this.gameState = result.state;
    this.activeTab = 0;
    await this.persistState();
  }

  private async submitDeduction(): Promise<void> {
    const result = finalizeDeduction(this.gameState, this.selectedSuspect, this.selectedMotive);
    if (!result.accepted) {
      this.notify(result.message);
      return;
    }
    this.gameState = result.state;
    await this.persistState();
    this.notify(result.message);
  }

  private pulseContent(): void {
    this.contentPulse = 1.015;
    setTimeout(() => {
      this.contentPulse = 1;
    }, 180);
  }

  private notify(message: string): void {
    this.toastText = message;
    this.showToast = true;
    setTimeout(() => {
      this.showToast = false;
    }, 2200);
  }

  private formatClock(timestamp: number): string {
    if (timestamp <= 0) {
      return '--:--';
    }
    const date = new Date(timestamp);
    const hour = date.getHours() < 10 ? `0${date.getHours()}` : `${date.getHours()}`;
    const minute = date.getMinutes() < 10 ? `0${date.getMinutes()}` : `${date.getMinutes()}`;
    return `${hour}:${minute}`;
  }

  private activeScene(): SceneDef {
    const scene = findScene(this.gameState.activeSceneId);
    return scene === null ? SCENES[0] : scene;
  }

  private currentEvent(): StoryEventDef {
    const event = getCurrentEvent(this.gameState);
    return event === null ? STORY_EVENTS[0] : event;
  }

  private hasCurrentEvent(): boolean {
    return getCurrentEvent(this.gameState) !== null;
  }

  private selectedClue(): ClueDef {
    const clue = findClue(this.selectedClueId);
    return clue === null ? CLUES[0] : clue;
  }

  private selectedEnding(): EndingDef {
    const ending = findEnding(this.gameState.endingId);
    return ending === null ? ENDINGS[1] : ending;
  }

  private nextSceneId(): string {
    if (isSceneComplete(this.gameState, SCENE_LIBRARY) && !isSceneComplete(this.gameState, SCENE_LAB)) {
      return SCENE_LAB;
    }
    if (isSceneComplete(this.gameState, SCENE_LAB) && !isSceneComplete(this.gameState, SCENE_BELL_TOWER)) {
      return SCENE_BELL_TOWER;
    }
    return '';
  }

  private nextSceneTitle(): string {
    const scene = findScene(this.nextSceneId());
    return scene === null ? '' : scene.title;
  }

  private completedSceneCount(): number {
    let count = 0;
    for (let index = 0; index < SCENES.length; index++) {
      if (isSceneComplete(this.gameState, SCENES[index].id)) {
        count++;
      }
    }
    return count;
  }

  private choiceAccent(tone: string): string {
    if (tone === 'risk') {
      return '#D77A72';
    }
    if (tone === 'soft') {
      return '#66B6B0';
    }
    return '#D9A65A';
  }

  private choiceFill(tone: string): string {
    if (tone === 'risk') {
      return '#21181A';
    }
    if (tone === 'soft') {
      return '#142224';
    }
    return '#211D17';
  }

  private choiceLead(tone: string): string {
    if (tone === 'risk') {
      return '高风险';
    }
    if (tone === 'soft') {
      return '人物';
    }
    return '推进';
  }

  private sceneStatus(sceneId: string): string {
    if (!isSceneUnlocked(this.gameState, sceneId)) {
      return '未解锁';
    }
    if (isSceneComplete(this.gameState, sceneId)) {
      return '已完成';
    }
    if (sceneId === this.gameState.activeSceneId) {
      return '调查中';
    }
    return '可进入';
  }

  private recentJournal(): JournalEntry[] {
    return this.gameState.journal.slice(0, 4);
  }

  @Builder
  private atmosphericBackground() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width(300)
        .height(300)
        .borderRadius(150)
        .backgroundColor('#293849')
        .opacity(0.34)
        .blur(34)
        .position({ x: -120, y: 70 })

      Column()
        .width(230)
        .height(230)
        .borderRadius(115)
        .backgroundColor('#5F4931')
        .opacity(0.22)
        .blur(40)
        .position({ x: 235, y: 430 })

      Column()
        .width(180)
        .height(180)
        .borderRadius(90)
        .backgroundColor('#244C4A')
        .opacity(0.18)
        .blur(32)
        .position({ x: 20, y: 690 })

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 165,
          colors: [['#0B0E13', 0.0], ['#101720', 0.55], ['#080A0E', 1.0]]
        })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private loadingView() {
    Column({ space: 20 }) {
      Text('MYS / 017')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .letterSpacing(3)
        .fontColor('#D9A65A')
      LoadingProgress()
        .width(36)
        .height(36)
        .color('#D9A65A')
      Text('正在打开案卷')
        .fontSize(14)
        .fontColor('#B7BBC3')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private coverView() {
    Column() {
      Row() {
        Text('CAMPUS ARCHIVE')
          .fontSize(11)
          .letterSpacing(2.4)
          .fontColor('#8E949E')
        Blank()
        Text('CASE 017')
          .fontSize(11)
          .letterSpacing(1.8)
          .fontColor('#D9A65A')
      }
      .width('100%')

      Blank()

      Column({ space: 18 }) {
        Text('雾校档案')
          .fontSize(44)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F3EFE8')
          .letterSpacing(2)
        Text('钟楼失声')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#D9A65A')
          .letterSpacing(5)

        Row({ space: 10 }) {
          Text('推理')
            .fontSize(11)
            .fontColor('#858C96')
            .letterSpacing(1.4)
          Text('决定')
            .fontSize(11)
            .fontColor('#858C96')
            .letterSpacing(1.4)
          Text('存档')
            .fontSize(11)
            .fontColor('#858C96')
            .letterSpacing(1.4)
        }

        Text('一桩没有目击者的校园失踪案。\n十四段现场记录，八条证据维度，一条必须被解释清楚的真相。')
          .fontSize(14)
          .lineHeight(24)
          .fontColor('#AEB3BC')
          .textAlign(TextAlign.Center)
          .margin({ top: 14 })
      }
      .width('100%')

      Blank()

      Column({ space: 12 }) {
        if (this.hasSave) {
          Button('继续调查', { type: ButtonType.Normal })
            .width('100%')
            .height(54)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#17130E')
            .backgroundColor('#D9A65A')
            .borderRadius(15)
            .onClick(() => this.openCase())

          Button('重新立案', { type: ButtonType.Normal })
            .width('100%')
            .height(48)
            .fontSize(14)
            .fontColor('#D8DDE3')
            .backgroundColor('#151B23')
            .border({ width: 1, color: '#303844' })
            .borderRadius(15)
            .onClick(() => {
              this.showResetDialog = true;
            })
        } else {
          Button('建立调查档案', { type: ButtonType.Normal })
            .width('100%')
            .height(54)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#17130E')
            .backgroundColor('#D9A65A')
            .borderRadius(15)
            .onClick(() => this.openCase())
        }

        Text(this.hasSave ? this.saveIndicator : '进度将在每次选择后自动保存')
          .fontSize(11)
          .fontColor('#747B85')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 28, right: 28, top: 30, bottom: 30 })
  }

  @Builder
  private topBar() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 3 }) {
          Text('雾校档案')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F2EEE7')
          Text(getPhaseLabel(this.gameState))
            .fontSize(11)
            .fontColor('#8F96A0')
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Column({ space: 4 }) {
          Text(this.saveBusy ? '正在归档' : 'AUTO SAVE')
            .fontSize(9)
            .letterSpacing(1.2)
            .fontColor(this.saveBusy ? '#D9A65A' : '#6E7782')
          Text(this.saveIndicator)
            .fontSize(10)
            .fontColor('#A5ACB5')
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')

      Row({ space: 10 }) {
        Stack({ alignContent: Alignment.Start }) {
          Column().width('100%').height(3).borderRadius(2).backgroundColor('#28303A')
          Column()
            .width(`${getProgressPercent(this.gameState)}%`)
            .height(3)
            .borderRadius(2)
            .backgroundColor('#D9A65A')
            .animation({ duration: 380, curve: Curve.EaseOut })
        }
        .layoutWeight(1)

        Text(`${getProgressPercent(this.gameState)}%`)
          .fontSize(10)
          .fontColor('#AEB4BD')
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 18, bottom: 15 })
    .backgroundColor('#C80B0F15')
    .border({ width: { bottom: 1 }, color: '#1E2630' })
  }

  @Builder
  private sceneCard(scene: SceneDef) {
    Column({ space: 8 }) {
      Row() {
        Text(scene.index)
          .fontSize(10)
          .fontColor(isSceneUnlocked(this.gameState, scene.id) ? scene.accent : '#5B626C')
        Blank()
        Text(this.sceneStatus(scene.id))
          .fontSize(9)
          .fontColor(scene.id === this.gameState.activeSceneId ? '#E8E2D8' : '#727A85')
      }
      .width('100%')

      Text(scene.title)
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(isSceneUnlocked(this.gameState, scene.id) ? '#E9E5DE' : '#6C727B')
        .maxLines(1)

      Text(`${getSceneProgress(this.gameState, scene.id).visited}/${getSceneProgress(this.gameState, scene.id).total}`)
        .width('100%')
        .fontSize(10)
        .fontColor('#7F8791')
    }
    .layoutWeight(1)
    .height(102)
    .padding(12)
    .justifyContent(FlexAlign.Center)
    .borderRadius(14)
    .border({
      width: scene.id === this.gameState.activeSceneId ? 1.5 : 1,
      color: scene.id === this.gameState.activeSceneId ? scene.accent : '#27303A'
    })
    .backgroundColor(scene.id === this.gameState.activeSceneId ? '#182029' : '#11161D')
    .opacity(isSceneUnlocked(this.gameState, scene.id) ? 1 : 0.5)
    .onClick(() => {
      if (isSceneUnlocked(this.gameState, scene.id)) {
        this.handleSceneSelect(scene.id);
      } else {
        this.notify('该现场尚未解锁，请先完成当前调查阶段。');
      }
    })
  }

  @Builder
  private choiceCard(choiceDef: ChoiceDef) {
    Column({ space: 7 }) {
      Row({ space: 8 }) {
        Text(this.choiceLead(choiceDef.tone))
          .fontSize(9)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.choiceAccent(choiceDef.tone))
          .letterSpacing(0.8)
        if (!isChoiceAvailable(this.gameState, choiceDef)) {
          Text('CONDITION')
            .fontSize(8)
            .fontColor('#737A84')
            .letterSpacing(1)
        }
        Blank()
        Text(isChoiceAvailable(this.gameState, choiceDef) ? '→' : 'LOCKED')
          .fontSize(9)
          .fontColor(this.choiceAccent(choiceDef.tone))
      }
      .width('100%')

      Text(choiceDef.label)
        .width('100%')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(isChoiceAvailable(this.gameState, choiceDef) ? '#EEE8DE' : '#6F7680')
        .textAlign(TextAlign.Start)

      Text(isChoiceAvailable(this.gameState, choiceDef) ?
        choiceDef.hint : getChoiceBlockedReason(this.gameState, choiceDef))
        .width('100%')
        .fontSize(11)
        .lineHeight(17)
        .fontColor(isChoiceAvailable(this.gameState, choiceDef) ? '#929AA4' : '#79736C')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 13, bottom: 13 })
    .borderRadius(14)
    .border({
      width: 1,
      color: isChoiceAvailable(this.gameState, choiceDef) ? this.choiceAccent(choiceDef.tone) : '#282F37'
    })
    .backgroundColor(isChoiceAvailable(this.gameState, choiceDef) ? this.choiceFill(choiceDef.tone) : '#11161C')
    .opacity(isChoiceAvailable(this.gameState, choiceDef) ? 1 : 0.72)
    .onClick(() => {
      if (isChoiceAvailable(this.gameState, choiceDef)) {
        this.handleChoice(choiceDef.id);
      } else {
        this.notify(getChoiceBlockedReason(this.gameState, choiceDef));
      }
    })
  }

  @Builder
  private sceneCompleteCard() {
    Column({ space: 16 }) {
      Text('STAGE ARCHIVED')
        .fontSize(10)
        .letterSpacing(2)
        .fontColor('#D9A65A')
      Text(`${this.activeScene().title}记录已归档`)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor('#EFE9DE')
      Text('这里还能继续回看线索，但下一段现场已经开放。')
        .fontSize(12)
        .fontColor('#8F97A1')
        .textAlign(TextAlign.Center)

      if (this.nextSceneId().length > 0) {
        Button(`前往 ${this.nextSceneTitle()}`, { type: ButtonType.Normal })
          .width('100%')
          .height(48)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#16120D')
          .backgroundColor('#D9A65A')
          .borderRadius(14)
          .onClick(() => this.handleSceneSelect(this.nextSceneId()))
      } else {
        Button('进入最终推理', { type: ButtonType.Normal })
          .width('100%')
          .height(48)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#16120D')
          .backgroundColor('#D9A65A')
          .borderRadius(14)
          .onClick(() => {
            this.activeTab = 3;
          })
      }
    }
    .width('100%')
    .padding(24)
    .borderRadius(20)
    .border({ width: 1, color: '#3B3428' })
    .backgroundColor('#171B20')
  }

  @Builder
  private eventCard() {
    Column({ space: 14 }) {
      Row() {
        Text(this.currentEvent().eyebrow)
          .fontSize(10)
          .letterSpacing(1.2)
          .fontColor(this.activeScene().accent)
        Blank()
        Text(this.activeScene().atmosphere)
          .fontSize(9)
          .fontColor('#6F7781')
      }
      .width('100%')

      Text(this.currentEvent().title)
        .width('100%')
        .fontSize(24)
        .lineHeight(31)
        .fontWeight(FontWeight.Bold)
        .fontColor('#F1ECE3')

      Row({ space: 7 }) {
        Text('◎')
          .fontSize(11)
          .fontColor(this.activeScene().accent)
        Text(this.currentEvent().location)
          .fontSize(10)
          .fontColor('#939BA5')
      }
      .width('100%')

      Text(this.currentEvent().narrative)
        .width('100%')
        .fontSize(13)
        .lineHeight(22)
        .fontColor('#B6BBC3')

      Column({ space: 7 }) {
        Text(this.currentEvent().speaker)
          .width('100%')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.activeScene().accent)
        Text(this.currentEvent().dialogue)
          .width('100%')
          .fontSize(13)
          .lineHeight(21)
          .fontColor('#D8D4CD')
      }
      .width('100%')
      .padding(14)
      .borderRadius(12)
      .backgroundColor('#101419')
      .border({ width: { left: 2 }, color: this.activeScene().accent })

      Text('你的记录')
        .width('100%')
        .fontSize(10)
        .letterSpacing(1.3)
        .fontColor('#757D87')
        .margin({ top: 2 })

      ForEach(this.currentEvent().choices, (choiceDef: ChoiceDef) => {
        this.choiceCard(choiceDef)
      }, (choiceDef: ChoiceDef) => choiceDef.id)
    }
    .width('100%')
    .padding(18)
    .borderRadius(22)
    .border({ width: 1, color: '#29313B' })
    .backgroundColor('#161B22')
    .shadow({ radius: 24, color: '#55000000', offsetX: 0, offsetY: 12 })
    .scale({ x: this.contentPulse, y: this.contentPulse })
    .animation({ duration: 180, curve: Curve.EaseOut })
  }

  @Builder
  private investigationView() {
    Scroll() {
      Column({ space: 18 }) {
        Row() {
          Column({ space: 5 }) {
            Text('ACTIVE CASE')
              .fontSize(9)
              .letterSpacing(2)
              .fontColor('#D9A65A')
            Text('选择现场，读取下一条记录')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#E8E4DC')
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Text(`${this.completedSceneCount()}/3`)
            .fontSize(12)
            .fontColor('#89919B')
        }
        .width('100%')

        Row({ space: 9 }) {
          ForEach(SCENES, (scene: SceneDef) => {
            this.sceneCard(scene)
          }, (scene: SceneDef) => scene.id)
        }
        .width('100%')

        if (this.gameState.phase === PHASE_ENDING || this.gameState.phase === PHASE_DEDUCTION) {
          Column({ space: 12 }) {
            Text(this.gameState.phase === PHASE_ENDING ? '档案已结案' : '现场调查已完成')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#EEE8DE')
            Text(this.gameState.phase === PHASE_ENDING ?
              '你可以在“推理”页查看结局、证据评分与另一条可能路线。' :
              '三处现场已经封存。请切换到“推理”页，选择责任人与行为动机。')
              .fontSize(12)
              .lineHeight(20)
              .fontColor('#929AA4')
              .textAlign(TextAlign.Center)
            Button('打开推理笔录', { type: ButtonType.Normal })
              .width('100%')
              .height(46)
              .fontColor('#17130E')
              .backgroundColor('#D9A65A')
              .borderRadius(14)
              .onClick(() => {
                this.activeTab = 3;
              })
          }
          .width('100%')
          .padding(22)
          .borderRadius(18)
          .backgroundColor('#151A20')
          .border({ width: 1, color: '#2F3741' })
        } else if (this.hasCurrentEvent()) {
          this.eventCard()
        } else {
          this.sceneCompleteCard()
        }

        Row() {
          Text('TIP')
            .fontSize(9)
            .letterSpacing(1.3)
            .fontColor('#D9A65A')
          Text('线索不是收集品。后续选择会根据已归档证据改变，也可能被锁住。')
            .fontSize(10)
            .lineHeight(16)
            .fontColor('#777F89')
            .layoutWeight(1)
        }
        .width('100%')
        .padding(14)
        .borderRadius(12)
        .backgroundColor('#10151B')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 22 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private clueCard(clue: ClueDef) {
    Column({ space: 8 }) {
      Row() {
        Text(this.gameState.discoveredClues.indexOf(clue.id) >= 0 ? clue.tag : 'UNREAD')
          .fontSize(9)
          .letterSpacing(0.6)
          .fontColor(this.gameState.discoveredClues.indexOf(clue.id) >= 0 ? '#D9A65A' : '#616872')
        Blank()
        if (clue.keyEvidence && this.gameState.discoveredClues.indexOf(clue.id) >= 0) {
          Text('KEY')
            .fontSize(8)
            .fontWeight(FontWeight.Bold)
            .fontColor('#17130E')
            .backgroundColor('#D9A65A')
            .borderRadius(4)
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
        }
      }
      .width('100%')

      Text(this.gameState.discoveredClues.indexOf(clue.id) >= 0 ? clue.title : '未归档线索')
        .width('100%')
        .fontSize(14)
        .lineHeight(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.gameState.discoveredClues.indexOf(clue.id) >= 0 ? '#ECE7DE' : '#626A74')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(this.gameState.discoveredClues.indexOf(clue.id) >= 0 ?
        clue.summary : '继续调查其他现场，满足条件后可读取。')
        .width('100%')
        .fontSize(10)
        .lineHeight(16)
        .fontColor(this.gameState.discoveredClues.indexOf(clue.id) >= 0 ? '#89919B' : '#555D67')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('48.4%')
    .height(150)
    .padding(13)
    .margin({ bottom: 11 })
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .borderRadius(15)
    .border({
      width: 1,
      color: this.gameState.discoveredClues.indexOf(clue.id) >= 0 ? '#343C46' : '#202730'
    })
    .backgroundColor(this.gameState.discoveredClues.indexOf(clue.id) >= 0 ? '#151B22' : '#0F141A')
    .onClick(() => {
      if (this.gameState.discoveredClues.indexOf(clue.id) >= 0) {
        this.selectedClueId = clue.id;
      } else {
        this.notify('这条线索尚未归档，继续调查可能会解锁它。');
      }
    })
  }

  @Builder
  private clueBoardView() {
    Scroll() {
      Column({ space: 18 }) {
        Row() {
          Column({ space: 5 }) {
            Text('EVIDENCE BOARD')
              .fontSize(9)
              .letterSpacing(2)
              .fontColor('#D9A65A')
            Text('线索板')
              .fontSize(25)
              .fontWeight(FontWeight.Bold)
              .fontColor('#EFEAE1')
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Column({ space: 2 }) {
            Text(`${this.gameState.discoveredClues.length}`)
              .fontSize(25)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D9A65A')
            Text(`/ ${CLUES.length}`)
              .fontSize(10)
              .fontColor('#848C96')
          }
        }
        .width('100%')

        Column({ space: 10 }) {
          Row() {
            Text('证据链完整度')
              .fontSize(11)
              .fontColor('#9AA1AA')
            Blank()
            Text(`${getEvidenceScore(this.gameState)} / 8`)
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor('#D9A65A')
          }
          .width('100%')
          Stack({ alignContent: Alignment.Start }) {
            Column().width('100%').height(5).borderRadius(3).backgroundColor('#29313A')
            Column()
              .width(`${Math.round((getEvidenceScore(this.gameState) / 8) * 100)}%`)
              .height(5)
              .borderRadius(3)
              .backgroundColor('#D9A65A')
              .animation({ duration: 350, curve: Curve.EaseOut })
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .borderRadius(15)
        .backgroundColor('#11171E')
        .border({ width: 1, color: '#252E38' })

        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.SpaceBetween,
          alignContent: FlexAlign.Start
        }) {
          ForEach(CLUES, (clue: ClueDef) => {
            this.clueCard(clue)
          }, (clue: ClueDef) => clue.id)
        }
        .width('100%')

        Text('点击已归档线索查看来源、摘要与推理意义。KEY 标记表示可直接参与最终证据链判定。')
          .width('100%')
          .fontSize(10)
          .lineHeight(17)
          .fontColor('#707883')
          .padding({ left: 2, right: 2 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private stageRow(scene: SceneDef) {
    Row({ space: 12 }) {
      Text(scene.index)
        .width(38)
        .height(38)
        .textAlign(TextAlign.Center)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(isSceneComplete(this.gameState, scene.id) ? '#17130E' : scene.accent)
        .backgroundColor(isSceneComplete(this.gameState, scene.id) ? scene.accent : '#151B22')
        .borderRadius(19)

      Column({ space: 5 }) {
        Row() {
          Text(scene.title)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(isSceneUnlocked(this.gameState, scene.id) ? '#E5E0D8' : '#666D77')
          Blank()
          Text(this.sceneStatus(scene.id))
            .fontSize(9)
            .fontColor(isSceneComplete(this.gameState, scene.id) ? scene.accent : '#7C8590')
        }
        .width('100%')
        Text(`${getSceneProgress(this.gameState, scene.id).visited} / ${getSceneProgress(this.gameState, scene.id).total} 个事件记录`)
          .fontSize(10)
          .fontColor('#79818B')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(13)
    .borderRadius(14)
    .backgroundColor('#11161C')
  }

  @Builder
  private archiveView() {
    Scroll() {
      Column({ space: 18 }) {
        Row() {
          Column({ space: 5 }) {
            Text('CASE FILE')
              .fontSize(9)
              .letterSpacing(2)
              .fontColor('#D9A65A')
            Text('调查档案')
              .fontSize(25)
              .fontWeight(FontWeight.Bold)
              .fontColor('#EFEAE1')
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Text(this.gameState.phase === PHASE_ENDING ? 'CLOSED' : 'OPEN')
            .fontSize(9)
            .letterSpacing(1.3)
            .fontColor(this.gameState.phase === PHASE_ENDING ? '#66B6B0' : '#D9A65A')
        }
        .width('100%')

        Row({ space: 9 }) {
          Column({ space: 4 }) {
            Text('PROGRESS').fontSize(8).letterSpacing(1).fontColor('#717984')
            Text(`${getProgressPercent(this.gameState)}%`)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#EBE6DD')
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start).padding(14)
          .borderRadius(14).backgroundColor('#141A21')

          Column({ space: 4 }) {
            Text('CLUES').fontSize(8).letterSpacing(1).fontColor('#717984')
            Text(`${this.gameState.discoveredClues.length}`)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#D9A65A')
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start).padding(14)
          .borderRadius(14).backgroundColor('#141A21')

          Column({ space: 4 }) {
            Text('EVIDENCE').fontSize(8).letterSpacing(1).fontColor('#717984')
            Text(`${getEvidenceScore(this.gameState)}/8`)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#66B6B0')
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start).padding(14)
          .borderRadius(14).backgroundColor('#141A21')
        }
        .width('100%')

        Column({ space: 10 }) {
          Text('阶段进度')
            .width('100%').fontSize(12).fontWeight(FontWeight.Medium).fontColor('#A6ADB6')
          ForEach(SCENES, (scene: SceneDef) => {
            this.stageRow(scene)
          }, (scene: SceneDef) => scene.id)
        }
        .width('100%').padding(16).borderRadius(18).backgroundColor('#151A20')
        .border({ width: 1, color: '#29323B' })

        Column({ space: 13 }) {
          Text('调查状态')
            .width('100%').fontSize(12).fontWeight(FontWeight.Medium).fontColor('#A6ADB6')

          Row() {
            Text('人物信任').fontSize(11).fontColor('#8C949E')
            Blank()
            Text(`${this.gameState.trust} / 5`).fontSize(11).fontColor('#66B6B0')
          }.width('100%')
          Stack({ alignContent: Alignment.Start }) {
            Column().width('100%').height(5).borderRadius(3).backgroundColor('#263039')
            Column()
              .width(`${Math.round((this.gameState.trust / 5) * 100)}%`)
              .height(5).borderRadius(3).backgroundColor('#66B6B0')
          }.width('100%')

          Row() {
            Text('现场压力').fontSize(11).fontColor('#8C949E')
            Blank()
            Text(`${this.gameState.pressure} / 5`).fontSize(11).fontColor('#D77A72')
          }.width('100%')
          Stack({ alignContent: Alignment.Start }) {
            Column().width('100%').height(5).borderRadius(3).backgroundColor('#263039')
            Column()
              .width(`${Math.round((this.gameState.pressure / 5) * 100)}%`)
              .height(5).borderRadius(3).backgroundColor('#D77A72')
          }.width('100%')
        }
        .width('100%').padding(16).borderRadius(18).backgroundColor('#151A20')
        .border({ width: 1, color: '#29323B' })

        Column({ space: 11 }) {
          Row() {
            Text('调查记录').fontSize(12).fontWeight(FontWeight.Medium).fontColor('#A6ADB6')
            Blank()
            Text(`${this.gameState.journal.length} 条`).fontSize(9).fontColor('#727A84')
          }.width('100%')

          if (this.gameState.journal.length === 0) {
            Text('尚未作出调查选择。').width('100%').fontSize(11).fontColor('#69717B')
          } else {
            ForEach(this.recentJournal(), (entry: JournalEntry) => {
              Row({ space: 10 }) {
                Text(this.formatClock(entry.time)).width(38).fontSize(9).fontColor('#707985')
                Column({ space: 3 }) {
                  Text(entry.choiceLabel)
                    .fontSize(11).fontWeight(FontWeight.Medium).fontColor('#DAD6CE')
                  Text(entry.note).fontSize(9).lineHeight(15).fontColor('#7E8791')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)
              }
              .width('100%').padding({ top: 7, bottom: 7 })
              .border({ width: { bottom: 1 }, color: '#252D36' })
            }, (entry: JournalEntry) => entry.eventId)
          }
        }
        .width('100%').padding(16).borderRadius(18).backgroundColor('#151A20')
        .border({ width: 1, color: '#29323B' })

        Column({ space: 10 }) {
          Row() {
            Text('本地存档').fontSize(12).fontWeight(FontWeight.Medium).fontColor('#A6ADB6')
            Blank()
            Text('Preferences v2').fontSize(9).fontColor('#66B6B0')
          }.width('100%')
          Text('每次现场选择后自动写入。关闭应用进程再打开，可从“继续调查”恢复当前事件、线索、状态与推理阶段。')
            .fontSize(10).lineHeight(17).fontColor('#77808A')
          Text(this.saveIndicator).fontSize(10).fontColor('#D9A65A')

          Button('清除进度并重新立案', { type: ButtonType.Normal })
            .width('100%').height(43).fontSize(12).fontColor('#D77A72')
            .backgroundColor('#1A1517').border({ width: 1, color: '#473033' })
            .borderRadius(12).margin({ top: 4 })
            .onClick(() => {
              this.showResetDialog = true;
            })
        }
        .width('100%').padding(16).alignItems(HorizontalAlign.Start)
        .borderRadius(18).backgroundColor('#151A20')
        .border({ width: 1, color: '#29323B' })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private suspectOption(option: SuspectOption) {
    Column({ space: 5 }) {
      Text(option.name)
        .width('100%').fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor(this.selectedSuspect === option.id ? '#17130E' : '#D9D5CD')
        .textAlign(TextAlign.Start)
      Text(option.role)
        .width('100%').fontSize(9)
        .fontColor(this.selectedSuspect === option.id ? '#4F4638' : '#737B85')
        .textAlign(TextAlign.Start)
    }
    .layoutWeight(1).height(72).padding(12).justifyContent(FlexAlign.Center)
    .borderRadius(13)
    .backgroundColor(this.selectedSuspect === option.id ? '#D9A65A' : '#141A21')
    .border({ width: 1, color: this.selectedSuspect === option.id ? '#D9A65A' : '#2A333C' })
    .onClick(() => {
      this.selectedSuspect = option.id;
    })
  }

  @Builder
  private motiveOption(option: MotiveOption) {
    Row({ space: 11 }) {
      Text(this.selectedMotive === option.id ? '●' : '○')
        .fontSize(14)
        .fontColor(this.selectedMotive === option.id ? '#D9A65A' : '#59616B')
      Column({ space: 4 }) {
        Text(option.title)
          .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#DDD8D0')
        Text(option.detail)
          .fontSize(9).lineHeight(15).fontColor('#7C848E')
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .width('100%').padding(13).borderRadius(13)
    .backgroundColor(this.selectedMotive === option.id ? '#1D1C18' : '#12171D')
    .border({ width: 1, color: this.selectedMotive === option.id ? '#5F5138' : '#262E37' })
    .onClick(() => {
      this.selectedMotive = option.id;
    })
  }

  @Builder
  private deductionLockedView() {
    Column({ space: 20 }) {
      Text('FINAL ANALYSIS').fontSize(9).letterSpacing(2).fontColor('#D9A65A')
      Text('最终推理尚未解锁')
        .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#EEE8DF')
      Text('你需要完成三处现场调查，并用真实线索支撑责任人与行为动机。')
        .fontSize(12).lineHeight(20).fontColor('#8E96A0').textAlign(TextAlign.Center)

      Column({ space: 14 }) {
        Row() {
          Text('已完成现场').fontSize(11).fontColor('#8A929C')
          Blank()
          Text(`${this.completedSceneCount()} / 3`)
            .fontSize(11).fontColor(this.completedSceneCount() === 3 ? '#66B6B0' : '#D9A65A')
        }.width('100%')
        Row() {
          Text('已归档线索').fontSize(11).fontColor('#8A929C')
          Blank()
          Text(`${this.gameState.discoveredClues.length} / 6 最低`)
            .fontSize(11).fontColor(this.gameState.discoveredClues.length >= 6 ? '#66B6B0' : '#D9A65A')
        }.width('100%')
        Row() {
          Text('证据链维度').fontSize(11).fontColor('#8A929C')
          Blank()
          Text(`${getEvidenceScore(this.gameState)} / 8`).fontSize(11).fontColor('#D9A65A')
        }.width('100%')
      }
      .width('100%').padding(18).borderRadius(16).backgroundColor('#141A21')
      .border({ width: 1, color: '#2A333D' })

      Button('返回现场调查', { type: ButtonType.Normal })
        .width('100%').height(48).fontColor('#17130E').backgroundColor('#D9A65A')
        .borderRadius(14)
        .onClick(() => {
          this.activeTab = 0;
        })
    }
    .width('100%').padding({ left: 20, right: 20, top: 32, bottom: 24 })
  }

  @Builder
  private deductionFormView() {
    Scroll() {
      Column({ space: 18 }) {
        Row() {
          Column({ space: 5 }) {
            Text('FINAL ANALYSIS').fontSize(9).letterSpacing(2).fontColor('#D9A65A')
            Text('最终推理').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#EFEAE1')
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Text(`${getEvidenceScore(this.gameState)}/8`)
            .fontSize(13).fontWeight(FontWeight.Medium).fontColor('#66B6B0')
        }.width('100%')

        Text('林晚安全，但真相仍需要一个能够被证据解释的判断。责任人与动机将共同决定结局。')
          .width('100%').fontSize(12).lineHeight(20).fontColor('#969EA8')

        Column({ space: 11 }) {
          Text('01 / 责任人')
            .width('100%').fontSize(11).letterSpacing(1).fontColor('#D9A65A')
          Row({ space: 8 }) {
            ForEach(SUSPECT_OPTIONS, (option: SuspectOption) => {
              this.suspectOption(option)
            }, (option: SuspectOption) => option.id)
          }.width('100%')
        }
        .width('100%').padding(16).borderRadius(17).backgroundColor('#151A20')
        .border({ width: 1, color: '#2A333D' })

        Column({ space: 10 }) {
          Text('02 / 行为动机')
            .width('100%').fontSize(11).letterSpacing(1).fontColor('#D9A65A')
          ForEach(MOTIVE_OPTIONS, (option: MotiveOption) => {
            this.motiveOption(option)
          }, (option: MotiveOption) => option.id)
        }
        .width('100%').padding(16).borderRadius(17).backgroundColor('#151A20')
        .border({ width: 1, color: '#2A333D' })

        Column({ space: 8 }) {
          Row() {
            Text('证据链检查').fontSize(11).fontWeight(FontWeight.Medium).fontColor('#B0B7C0')
            Blank()
            Text(`${getEvidenceScore(this.gameState)} / 8`).fontSize(10).fontColor('#66B6B0')
          }.width('100%')
          Text(getEvidenceScore(this.gameState) >= 6 ?
            '已形成可复核的多维证据链。提交后将根据全部条件生成结局。' :
            '证据维度仍然偏少。你仍可提交，但更可能进入条件不足的结局。')
            .fontSize(10).lineHeight(17).fontColor('#7C8590')
        }
        .width('100%').padding(15).borderRadius(14).backgroundColor('#10151B')

        Button('提交最终判断', { type: ButtonType.Normal })
          .width('100%').height(52).fontSize(15).fontWeight(FontWeight.Medium)
          .fontColor('#17130E').backgroundColor('#D9A65A').borderRadius(15)
          .enabled(this.selectedSuspect.length > 0 && this.selectedMotive.length > 0)
          .opacity(this.selectedSuspect.length > 0 && this.selectedMotive.length > 0 ? 1 : 0.48)
          .onClick(() => this.submitDeduction())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 18, bottom: 24 })
    }
    .width('100%').layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private endingView() {
    Scroll() {
      Column({ space: 18 }) {
        Column({ space: 8 }) {
          Text(this.gameState.endingId === ENDING_TRUTH ? 'A+' : 'B')
            .fontSize(62).fontWeight(FontWeight.Bold)
            .fontColor(this.gameState.endingId === ENDING_TRUTH ? '#D9A65A' : '#8E96A0')
          Text(this.selectedEnding().subtitle)
            .fontSize(10).letterSpacing(2)
            .fontColor(this.gameState.endingId === ENDING_TRUTH ? '#D9A65A' : '#8E96A0')
          Text(this.selectedEnding().title)
            .fontSize(31).fontWeight(FontWeight.Bold).fontColor('#F0EBE2')
          Text(this.gameState.endingId === ENDING_TRUTH ?
            '所有关键条件已对齐' : '部分证据条件未满足')
            .fontSize(11).fontColor('#7D8590')
        }.width('100%').padding({ top: 22, bottom: 10 })

        Text(this.selectedEnding().description)
          .width('100%').fontSize(13).lineHeight(22).fontColor('#B4BAC2')
          .padding(18).borderRadius(17).backgroundColor('#151B22')
          .border({
            width: 1,
            color: this.gameState.endingId === ENDING_TRUTH ? '#5A4B32' : '#3A424C'
          })

        Text(this.selectedEnding().meaning)
          .width('100%').fontSize(12).lineHeight(21).fontColor('#949CA6')
          .padding({ left: 18, right: 18 })
          .border({
            width: { left: 2 },
            color: this.gameState.endingId === ENDING_TRUTH ? '#D9A65A' : '#7A838E'
          })

        Row({ space: 9 }) {
          Column({ space: 4 }) {
            Text('EVIDENCE').fontSize(8).letterSpacing(1).fontColor('#737C86')
            Text(`${getEvidenceScore(this.gameState)}/8`)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#66B6B0')
          }.layoutWeight(1).alignItems(HorizontalAlign.Start).padding(14)
          .borderRadius(14).backgroundColor('#141A21')

          Column({ space: 4 }) {
            Text('CLUES').fontSize(8).letterSpacing(1).fontColor('#737C86')
            Text(`${this.gameState.discoveredClues.length}`)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#D9A65A')
          }.layoutWeight(1).alignItems(HorizontalAlign.Start).padding(14)
          .borderRadius(14).backgroundColor('#141A21')

          Column({ space: 4 }) {
            Text('TRUST').fontSize(8).letterSpacing(1).fontColor('#737C86')
            Text(`${this.gameState.trust}/5`)
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#D9A65A')
          }.layoutWeight(1).alignItems(HorizontalAlign.Start).padding(14)
          .borderRadius(14).backgroundColor('#141A21')
        }.width('100%')

        Column({ space: 10 }) {
          Row() {
            Text('关键证据回顾').fontSize(12).fontWeight(FontWeight.Medium).fontColor('#AFB6BF')
            Blank()
            Text(`${this.gameState.discoveredClues.length} 条`).fontSize(9).fontColor('#747D87')
          }.width('100%')
          Text(this.gameState.endingId === ENDING_TRUTH ?
            '借阅时间差、完整录音、并联电路、行为脚印、齿轮暗号与控制室安全状态共同解释了整场行动。' :
            '部分记录只证明了行动发生过，没有闭合责任人与动机。可以在重开后尝试保留更多现场证据。')
            .fontSize(10).lineHeight(17).fontColor('#7D8690')
        }
        .width('100%').padding(16).borderRadius(15).backgroundColor('#10151B')

        Button('重新调查', { type: ButtonType.Normal })
          .width('100%').height(50).fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor('#17130E').backgroundColor('#D9A65A').borderRadius(14)
          .onClick(() => {
            this.beginNewGame();
          })

        Button('回看案件档案', { type: ButtonType.Normal })
          .width('100%').height(45).fontSize(12).fontColor('#C2C7CD')
          .backgroundColor('#151B22').border({ width: 1, color: '#303943' }).borderRadius(14)
          .onClick(() => {
            this.activeTab = 2;
          })
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 10, bottom: 24 })
    }
    .width('100%').layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  private deductionView() {
    if (this.gameState.phase === PHASE_ENDING) {
      this.endingView()
    } else if (this.gameState.phase === PHASE_DEDUCTION) {
      this.deductionFormView()
    } else {
      this.deductionLockedView()
    }
  }

  @Builder
  private bottomNavigation() {
    Row() {
      ForEach(NAV_ITEMS, (item: NavItem) => {
        Column({ space: 5 }) {
          Text(item.mark)
            .fontSize(9).letterSpacing(0.6)
            .fontColor(this.activeTab === item.tab ? '#D9A65A' : '#626B76')
          Text(item.label)
            .fontSize(11)
            .fontWeight(this.activeTab === item.tab ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.activeTab === item.tab ? '#EEE9E0' : '#7D8690')
          Column()
            .width(this.activeTab === item.tab ? 18 : 0)
            .height(2).borderRadius(1).backgroundColor('#D9A65A')
            .animation({ duration: 220, curve: Curve.EaseOut })
        }
        .layoutWeight(1).height(68).justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.activeTab = item.tab;
        })
      }, (item: NavItem) => `${item.tab}`)
    }
    .width('100%').padding({ left: 8, right: 8, top: 2, bottom: 16 })
    .backgroundColor('#F20A0D12')
    .border({ width: { top: 1 }, color: '#202832' })
  }

  @Builder
  private gameView() {
    Column() {
      this.topBar()
      if (this.activeTab === 0) {
        this.investigationView()
      } else if (this.activeTab === 1) {
        this.clueBoardView()
      } else if (this.activeTab === 2) {
        this.archiveView()
      } else {
        this.deductionView()
      }
      this.bottomNavigation()
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private clueDetailOverlay() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%').height('100%').backgroundColor('#CC05070A')
        .onClick(() => {
          this.selectedClueId = '';
        })

      Column({ space: 14 }) {
        Row() {
          Text(this.selectedClue().source)
            .fontSize(10).fontColor('#D9A65A')
          Blank()
          Text('CLOSE  ×')
            .fontSize(10).letterSpacing(1).fontColor('#8A929C')
            .onClick(() => {
              this.selectedClueId = '';
            })
        }.width('100%')

        Text(this.selectedClue().title)
          .width('100%').fontSize(23).lineHeight(30)
          .fontWeight(FontWeight.Bold).fontColor('#EFEAE1')

        Row({ space: 8 }) {
          Text(this.selectedClue().tag)
            .fontSize(9).fontColor('#17130E').backgroundColor('#D9A65A')
            .borderRadius(5).padding({ left: 7, right: 7, top: 3, bottom: 3 })
          if (this.selectedClue().keyEvidence) {
            Text('KEY EVIDENCE').fontSize(8).letterSpacing(0.8).fontColor('#66B6B0')
          }
        }

        Text(this.selectedClue().summary)
          .width('100%').fontSize(13).lineHeight(21).fontColor('#C7C3BB')
        Text(this.selectedClue().detail)
          .width('100%').fontSize(12).lineHeight(21).fontColor('#959DA7')

        Column({ space: 6 }) {
          Text('推理意义').fontSize(10).letterSpacing(1).fontColor('#D9A65A')
          Text(this.selectedClue().keyEvidence ?
            '该线索可能参与最终证据链维度判定，请与时间线、录音或现场记录交叉核对。' :
            '该线索可以辅助理解现场，但单独不足以证明完整动机。')
            .fontSize(10).lineHeight(17).fontColor('#7B848E')
        }
        .width('100%').padding(13).borderRadius(12).backgroundColor('#10151B')

        Button('收好线索', { type: ButtonType.Normal })
          .width('100%').height(46).fontColor('#17130E').backgroundColor('#D9A65A')
          .borderRadius(13)
          .onClick(() => {
            this.selectedClueId = '';
          })
      }
      .width('100%').padding({ left: 20, right: 20, top: 20, bottom: 22 })
      .borderRadius({ topLeft: 24, topRight: 24 })
      .backgroundColor('#171C23')
      .border({ width: { top: 1 }, color: '#343D47' })
    }
    .width('100%').height('100%')
  }

  @Builder
  private resetOverlay() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%').height('100%').backgroundColor('#D905070A')
        .onClick(() => {
          this.showResetDialog = false;
        })

      Column({ space: 14 }) {
        Text('清除当前案卷？')
          .width('100%').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#F0EAE1')
        Text('当前事件、线索、状态和结局将被新案卷替代。已经解锁的真相结局记录会保留在本地。')
          .width('100%').fontSize(11).lineHeight(18).fontColor('#8D95A0')
        Row({ space: 10 }) {
          Button('取消', { type: ButtonType.Normal })
            .layoutWeight(1).height(44).fontColor('#C3C8CE').backgroundColor('#141A21')
            .border({ width: 1, color: '#2C353F' }).borderRadius(12)
            .onClick(() => {
              this.showResetDialog = false;
            })
          Button('确认重开', { type: ButtonType.Normal })
            .layoutWeight(1).height(44).fontColor('#F4EDE3').backgroundColor('#8C3D3D')
            .borderRadius(12)
            .onClick(() => {
              this.beginNewGame();
            })
        }.width('100%').margin({ top: 6 })
      }
      .width('84%').padding(20).borderRadius(20).backgroundColor('#191E25')
      .border({ width: 1, color: '#3A434D' })
      .shadow({ radius: 32, color: '#AA000000', offsetX: 0, offsetY: 16 })
    }
    .width('100%').height('100%')
  }

  @Builder
  private toastOverlay() {
    Column() {
      Text(this.toastText)
        .fontSize(11).lineHeight(17).fontColor('#EEE9E1').textAlign(TextAlign.Center)
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .borderRadius(12).backgroundColor('#E6242B33')
        .border({ width: 1, color: '#414B56' })
        .shadow({ radius: 20, color: '#66000000', offsetX: 0, offsetY: 8 })
    }
    .width('100%').height('100%').justifyContent(FlexAlign.End)
    .padding({ left: 20, right: 20, bottom: 92 })
    .hitTestBehavior(HitTestMode.Transparent)
    .opacity(this.showToast ? 1 : 0)
    .animation({ duration: 220, curve: Curve.EaseOut })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      this.atmosphericBackground()

      if (this.screen === 'loading') {
        this.loadingView()
      } else if (this.screen === 'cover') {
        this.coverView()
      } else {
        this.gameView()
      }

      if (this.selectedClueId.length > 0) {
        this.clueDetailOverlay()
      }
      if (this.showResetDialog) {
        this.resetOverlay()
      }
      if (this.showToast) {
        this.toastOverlay()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0A0D12')
  }
}
