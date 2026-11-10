import {
  ChoiceDef,
  ClueDef,
  ENDING_ECHO,
  ENDING_TRUTH,
  EndingDef,
  SCENE_BELL_TOWER,
  SCENE_LAB,
  SCENE_LIBRARY,
  SceneDef,
  StoryEventDef
} from '../models/GameModels';

function choice(
  id: string,
  label: string,
  hint: string,
  tone: string,
  nextNodeId: string,
  addClueId: string,
  addFlag: string,
  trustDelta: number,
  pressureDelta: number,
  journalText: string,
  requiredClues: string[] = [],
  requiredFlags: string[] = [],
  blockedReason: string = '',
  requiredAnyClues: string[] = []
): ChoiceDef {
  return {
    id: id,
    label: label,
    hint: hint,
    tone: tone,
    nextNodeId: nextNodeId,
    requiredClues: requiredClues,
    requiredAnyClues: requiredAnyClues,
    requiredFlags: requiredFlags,
    blockedReason: blockedReason,
    addClueId: addClueId,
    addFlag: addFlag,
    trustDelta: trustDelta,
    pressureDelta: pressureDelta,
    journalText: journalText
  };
}

export const CLUES: ClueDef[] = [
  {
    id: 'clue_loan_log',
    title: '被撕掉的值班借阅卡',
    source: '旧图书馆 · 借阅台',
    summary: '林晚在闭馆后调阅过《地下动力系统维护手册》。',
    detail: '借阅卡上的归还时间被涂改。残留压痕显示，真正归还时间比保安记录晚了 43 分钟。',
    tag: '时间线',
    keyEvidence: true
  },
  {
    id: 'clue_experiment_report',
    title: '未公开的实验事故书',
    source: '旧图书馆 · 密封档案柜',
    summary: '三年前的高压实验事故曾被人为压低等级。',
    detail: '事故编号 QL-17 与钟楼主线路同一天失效。签字人一栏只剩一个被刮花的“周”字。',
    tag: '动机',
    keyEvidence: true
  },
  {
    id: 'clue_guard_log',
    title: '保安巡楼记录',
    source: '旧图书馆 · 值夜员',
    summary: '23:47 后有人用教工权限解除了钟楼门禁。',
    detail: '记录显示异常授权发生前 12 秒，实验楼同时出现一次高负载。两条时间线并不独立。',
    tag: '门禁',
    keyEvidence: true
  },
  {
    id: 'clue_duty_roster',
    title: '双人值守表',
    source: '北区实验楼 · 值班室',
    summary: '名单上唯一没有签名的人，是助教周岚。',
    detail: '纸背留有铅笔压痕：“如果监控恢复，先删掉 23:42 之后的片段。”',
    tag: '人物',
    keyEvidence: true
  },
  {
    id: 'clue_badge',
    title: '短路的值班门禁卡',
    source: '北区实验楼 · 门禁读卡器',
    summary: '卡片在钟楼电梯口留下了最后一次读取记录。',
    detail: '芯片烧毁前的缓存只保留了一个姓名缩写：Z.L.。', 
    tag: '门禁',
    keyEvidence: true
  },
  {
    id: 'clue_service_key',
    title: '检修通道钥匙',
    source: '实验楼 · 维修箱',
    summary: '钥匙环上沾有钟楼铜钟特有的蓝绿色锈迹。',
    detail: '有人在最近一周内往返过实验楼与钟楼，但维修系统里没有对应的工单。',
    tag: '物证',
    keyEvidence: false
  },
  {
    id: 'clue_recorder',
    title: '循环录音的采访笔',
    source: '北区实验楼 · 声学实验室',
    summary: '录音末尾有林晚与另一人的争吵，以及一次刻意制造的断电。',
    detail: '另一人的声音经过变调，但口音和停顿方式与周岚一致。林晚说：“我要把原始数据带走。”',
    tag: '声音',
    keyEvidence: true
  },
  {
    id: 'clue_audio_clip',
    title: '缺失前四分钟的录音片段',
    source: '北区实验楼 · 声学实验室',
    summary: '录音从争执中途开始，只能确认“数据”与“钟楼”两个词。',
    detail: '快速跳读保住了文件，却抹去了最关键的上下文。它可以备用，但不足以单独证明动机。',
    tag: '声音',
    keyEvidence: false
  },
  {
    id: 'clue_power_trace',
    title: '异常负荷曲线',
    source: '北区实验楼 · 动力柜',
    summary: '停电不是事故，而是有人手动切换到了备用线路。',
    detail: '切换指令来自钟楼地下的旧终端。其数字签名使用已离职教工的通用账号。',
    tag: '技术',
    keyEvidence: true
  },
  {
    id: 'clue_tower_power',
    title: '钟楼与实验楼的并联电路',
    source: '北区实验楼 · 配电图',
    summary: '两栋楼共享一条封存在墙内的旧动力线。',
    detail: '林晚当天在图书馆借阅的，正是这条线路的维护手册。有人用停电掩盖了设备转移。',
    tag: '因果',
    keyEvidence: true
  },
  {
    id: 'clue_manual_switch',
    title: '被烧黑的手动闸刀',
    source: '北区实验楼 · 总闸',
    summary: '闸刀上留有新鲜的手套纤维。',
    detail: '它证明有人主动操作过线路，却无法说明操作者是谁。适合辅助推断，不能单独结案。',
    tag: '物证',
    keyEvidence: false
  },
  {
    id: 'clue_clock_dust',
    title: '钟楼铜屑上的门禁残码',
    source: '停摆钟楼 · 铁门',
    summary: '铜屑中嵌着与值班卡一致的芯片碎屑。',
    detail: '门禁残码指向实验楼 3F 的声学实验室，而不是校园外的人员。',
    tag: '门禁',
    keyEvidence: true
  },
  {
    id: 'clue_window_thread',
    title: '窗外攀爬留下的纤维',
    source: '停摆钟楼 · 外墙',
    summary: '纤维与林晚当天穿的雨衣材质一致。',
    detail: '门被反锁并不是囚禁证据。林晚曾为了避开监控，从检修梯进入钟楼。',
    tag: '路径',
    keyEvidence: false
  },
  {
    id: 'clue_keycard',
    title: '备用门禁卡',
    source: '停摆钟楼 · 雨棚',
    summary: '卡片编号属于周岚，边缘有被匆忙折断的痕迹。',
    detail: '周岚把自己的卡塞进排水槽，试图让追寻者误以为林晚被人带走。',
    tag: '人物',
    keyEvidence: true
  },
  {
    id: 'clue_footprint',
    title: '两个人的湿脚印',
    source: '停摆钟楼 · 楼梯间',
    summary: '脚印并非追逐，而是一前一后主动上楼。',
    detail: '大号鞋印在每一个转角等待小号鞋印，符合两人共同搬运设备时的节奏。',
    tag: '现场',
    keyEvidence: true
  },
  {
    id: 'clue_gear_scratch',
    title: '黄铜齿轮上的新刻痕',
    source: '停摆钟楼 · 机械室',
    summary: '刻痕组成了实验楼旧终端编号。',
    detail: '齿轮没有损坏，刻痕是林晚留下的定位标记。她希望后来的人找到地下配电室。',
    tag: '暗号',
    keyEvidence: true
  },
  {
    id: 'clue_burn_trace',
    title: '熔断后的接线痕迹',
    source: '停摆钟楼 · 机械室',
    summary: '电缆被人为短接，但操作顺序专业。',
    detail: '短接没有造成火情，只让钟楼暂时离网。痕迹可证明预谋，却无法直接证明行动者身份。',
    tag: '技术',
    keyEvidence: false
  },
  {
    id: 'clue_confession',
    title: '林晚的完整留言',
    source: '停摆钟楼 · 声墙',
    summary: '林晚主动请求周岚帮助她藏身并转移实验数据。',
    detail: '留言明确说明：这不是绑架，而是一场为了避开利益相关者、保护事故证据的自发行动。',
    tag: '证词',
    keyEvidence: true
  },
  {
    id: 'clue_silence',
    title: '墙内刻意留出的静默',
    source: '停摆钟楼 · 声墙',
    summary: '隔音棉后方有空腔，足以容纳一人和一台便携设备。',
    detail: '空间里留着饮用水与充电线。有人提前准备了长期停留条件，但动机仍不完整。',
    tag: '现场',
    keyEvidence: false
  },
  {
    id: 'clue_thermal',
    title: '尚未冷却的服务器',
    source: '停摆钟楼 · 旧控制室',
    summary: '事故原始数据正在离线归档，林晚并未被控制。',
    detail: '服务器日志显示归档任务由林晚本人发起。她安全、清醒，并在主动完成证据保全。',
    tag: '关键',
    keyEvidence: true
  },
  {
    id: 'clue_signal',
    title: '三短一长的敲击信号',
    source: '停摆钟楼 · 旧控制室',
    summary: '林晚用校内记者约定的敲击码回应调查者。',
    detail: '她确认自己安全，并请求先完成数据备份，再公开真相。',
    tag: '证词',
    keyEvidence: false
  }
];

export const SCENES: SceneDef[] = [
  {
    id: SCENE_LIBRARY,
    index: '01',
    title: '旧图书馆',
    subtitle: '被雨声封存的借阅记录',
    description: '闭馆后的借阅台、密封档案柜与失眠的值夜员。',
    atmosphere: '雨 / 18°C / 纸页受潮',
    accent: '#D9A65A'
  },
  {
    id: SCENE_LAB,
    index: '02',
    title: '北区实验楼',
    subtitle: '仍在运行的错误答案',
    description: '声学实验室、动力柜和一段被剪短的录音。',
    atmosphere: '断电 / 21°C / 电流噪声',
    accent: '#66B6B0'
  },
  {
    id: SCENE_BELL_TOWER,
    index: '03',
    title: '停摆钟楼',
    subtitle: '没有人听见的最后一声',
    description: '反锁的铁门、积灰的齿轮与墙后的微弱呼吸。',
    atmosphere: '浓雾 / 16°C / 无信号',
    accent: '#C87171'
  }
];

export const STORY_EVENTS: StoryEventDef[] = [
  {
    id: 'E01_CASE_BRIEF',
    sceneId: SCENE_LIBRARY,
    title: '失踪发生在第 13 声钟响前',
    eyebrow: '档案 017 / 接受委托',
    location: '旧图书馆 · 西侧阅览室',
    narrative: '10 月 17 日 23:47，校报记者林晚在停摆钟楼附近失去踪迹。她的最后一条消息只留下四个字：“别信记录。”',
    speaker: '林澈 / 校园广播站',
    dialogue: '“我知道你们调查社专门翻旧案。今晚的钟楼没有响，可我的录音里却多了一声钟。”',
    choices: [
      choice('accept_case', '接受委托', '从借阅台开始重建林晚的行动路线', 'primary', 'E02_LIBRARY_DESK', '', 'case_accepted', 1, 0, '决定查明林晚失踪的真相。')
    ]
  },
  {
    id: 'E02_LIBRARY_DESK',
    sceneId: SCENE_LIBRARY,
    title: '借阅台上的 43 分钟',
    eyebrow: '现场记录 / 时间线',
    location: '旧图书馆 · 借阅台',
    narrative: '台面残留着半干的水痕。系统显示林晚 22:19 归还了书，但书箱底部的借阅卡记录却是 23:02。',
    speaker: '调查社 / 行动建议',
    dialogue: '记录可能被改过。先确认她读了什么，再决定是否惊动值夜员。',
    choices: [
      choice('inspect_loan', '翻查借阅卡', '获取被涂改的归还时间', 'primary', 'E03_SEALED_ARCHIVE', 'clue_loan_log', 'loan_checked', 1, 0, '从借阅卡中还原出 43 分钟的时间差。'),
      choice('skip_borrow_record', '直接寻找档案柜', '节省时间，但会失去借阅记录', 'risk', 'E03_SEALED_ARCHIVE', '', 'skipped_borrow_record', -1, 1, '没有核查借阅卡，时间线出现缺口。')
    ]
  },
  {
    id: 'E03_SEALED_ARCHIVE',
    sceneId: SCENE_LIBRARY,
    title: '贴着封条的档案柜',
    eyebrow: '关键选择 / 物证',
    location: '旧图书馆 · 密闭书库',
    narrative: '档案柜上贴着三年前的事故封条，锁芯旁却有一道新刮痕。借阅卡刚好能穿过柜门缝隙。',
    speaker: '系统提示',
    dialogue: '完整开启不会触发警报；强行撬动会留下可追踪的声音与破坏痕迹。',
    choices: [
      choice('open_with_card', '用借阅卡无损开启', '需要：被撕掉的值班借阅卡', 'primary', 'E04_LIBRARIAN', 'clue_experiment_report', 'opened_archive_cleanly', 1, 0, '无损打开密封档案柜，找到未公开事故书。', ['clue_loan_log'], [], '还没有可用于安全开锁的借阅记录。'),
      choice('force_open_archive', '强行撬开档案柜', '可获得物证，但会提高警觉度', 'risk', 'E04_LIBRARIAN', 'clue_experiment_report', 'archive_forced', -1, 2, '强行打开档案柜，留下明显破坏痕迹。')
    ]
  },
  {
    id: 'E04_LIBRARIAN',
    sceneId: SCENE_LIBRARY,
    title: '值夜员没有看钟',
    eyebrow: '人物对话 / 可信度',
    location: '旧图书馆 · 值班室',
    narrative: '值夜员反复擦着同一只杯口。他承认 23:47 有人用教工权限解除了钟楼门禁，但不愿说出签字人。',
    speaker: '值夜员 / 顾衡',
    dialogue: '“我只负责钥匙。你们查得太深，明早丢的就不只是记录。”',
    choices: [
      choice('support_guard', '承诺保护证人', '换取巡楼记录与稳定信任', 'soft', '', 'clue_guard_log', 'guard_ally', 2, 0, '选择保护值夜员，获得完整巡楼记录。'),
      choice('pressure_guard', '拿破坏记录施压', '可获得值守表，但证人会保持沉默', 'risk', '', 'clue_duty_roster', 'guard_intimidated', -2, 2, '用档案柜破坏记录施压，得知周岚未签署值守表。')
    ]
  },
  {
    id: 'E05_LAB_GATE',
    sceneId: SCENE_LAB,
    title: '门禁只认识半个人',
    eyebrow: '新场景 / 权限检查',
    location: '北区实验楼 · 一层门厅',
    narrative: '实验楼的电子门禁在停电后进入只读模式。读卡器反复识别到一张在系统里“已注销”的卡片。',
    speaker: '门禁语音',
    dialogue: '“检测到残留授权。是否显示最后一次离线记录？”',
    choices: [
      choice('trace_badge', '追踪离线门禁记录', '借助图书馆查到的借阅线索', 'primary', 'E06_RECORDER', 'clue_badge', 'badge_traced', 1, 0, '沿借阅系统找到最后一次门禁读取记录。', ['clue_loan_log'], [], '缺少能把借阅记录与门禁时间对应起来的凭据。'),
      choice('enter_service_hall', '从检修通道绕入', '不依赖门禁，但会承受更多压力', 'risk', 'E06_RECORDER', 'clue_service_key', 'used_service_hall', 0, 1, '从检修通道进入实验楼，发现沾有钟楼铜锈的钥匙。')
    ]
  },
  {
    id: 'E06_RECORDER',
    sceneId: SCENE_LAB,
    title: '录音笔在倒着呼吸',
    eyebrow: '证据收集 / 声音',
    location: '北区实验楼 · 声学实验室',
    narrative: '采访笔被压在隔音棉下，指示灯每隔七秒闪一次。文件仍有完整副本，但快速跳读会覆盖早期音频。',
    speaker: '林澈 / 无线耳机',
    dialogue: '“林晚习惯先录环境声。别跳过开头，真正的争执一定藏在前面。”',
    choices: [
      choice('listen_complete_audio', '从头听完完整录音', '保留上下文，理解停电为何发生', 'primary', 'E07_ASSISTANT', 'clue_recorder', 'heard_full_audio', 1, 0, '完整听取采访笔录音，确认林晚与周岚发生争执。'),
      choice('skip_to_last_minute', '只提取最后一分钟', '快速获得片段，但上下文缺失', 'risk', 'E07_ASSISTANT', 'clue_audio_clip', 'audio_partial', 0, 1, '快速提取末段录音，只得到“数据”和“钟楼”两个关键词。')
    ]
  },
  {
    id: 'E07_ASSISTANT',
    sceneId: SCENE_LAB,
    title: '助教不肯看那扇门',
    eyebrow: '人物对话 / 动机',
    location: '北区实验楼 · 机房外走廊',
    narrative: '助教周岚站在走廊尽头，手套沾着新鲜铜屑。她听见录音中的自己的名字时，只把目光移向动力柜。',
    speaker: '周岚 / 实验教学助教',
    dialogue: '“林晚不是被谁带走的。如果你们真的听完录音，就该知道我在阻止更糟的事。”',
    choices: [
      choice('show_full_audio', '播放完整录音并等待解释', '需要：循环录音的采访笔', 'soft', 'E08_POWER_ROOM', 'clue_power_trace', 'assistant_cooperated', 2, 0, '用完整录音换来周岚的有限合作与异常负荷记录。', ['clue_recorder'], [], '录音上下文不完整，周岚拒绝说明线路细节。'),
      choice('bluff_with_partial_audio', '用残缺片段诈问', '可能得到值班表，但会激化矛盾', 'risk', 'E08_POWER_ROOM', 'clue_duty_roster', 'assistant_hostile', -2, 2, '用残缺录音诈问周岚，确认值守表缺签名但失去合作。')
    ]
  },
  {
    id: 'E08_POWER_ROOM',
    sceneId: SCENE_LAB,
    title: '停电是一条被选中的路',
    eyebrow: '技术验证 / 因果',
    location: '北区实验楼 · 地下动力室',
    narrative: '负荷曲线在 23:42 突然归零，又在四分钟后恢复到 97%。这不是事故，更像有人把一条旧线路从校园电网里藏了起来。',
    speaker: '周岚',
    dialogue: '“你们看见的是黑掉的一栋楼。我看见的是有人终于把证据从错误的人手里拿走。”',
    choices: [
      choice('compare_power_graphs', '对比钟楼与实验楼线路', '需要：异常负荷曲线或完整录音', 'primary', '', 'clue_tower_power', 'solved_power_route', 1, 0, '比对线路图，确认钟楼与实验楼共用旧动力线。', ['clue_power_trace', 'clue_recorder'], [], '手上还没有足够的技术记录支撑线路推断。'),
      choice('cut_manual_switch', '短接总闸逼出备用线路', '会留下新的熔断痕迹', 'risk', '', 'clue_manual_switch', 'forced_power_switch', -1, 2, '强行短接总闸，确认备用线路位置。')
    ]
  },
  {
    id: 'E09_BELL_GATE',
    sceneId: SCENE_BELL_TOWER,
    title: '钟楼不接受任何解释',
    eyebrow: '终场景 / 门禁',
    location: '停摆钟楼 · 铁门',
    narrative: '铁门从内部反锁，锁孔里塞着半截门禁芯片。楼内没有灯光，只有风穿过铜钟时发出的低频回声。',
    speaker: '天气广播',
    dialogue: '浓雾预警持续，钟楼外墙湿滑。任何未经授权的攀爬都会触发校园警报。',
    choices: [
      choice('open_with_badge', '用并联电路时间窗读卡', '需要：完整录音与线路图', 'primary', 'E10_WET_FOOTPRINTS', 'clue_clock_dust', 'entered_tower_cleanly', 1, 0, '利用门禁断电时间窗进入钟楼，收集铜屑残码。', ['clue_recorder', 'clue_tower_power'], [], '门禁时间窗与线路证据还不完整。'),
      choice('climb_outer_pipe', '沿外墙检修梯攀爬', '能进入钟楼，但会留下高风险痕迹', 'risk', 'E10_WET_FOOTPRINTS', 'clue_window_thread', 'climbed_tower', 0, 2, '从外墙检修梯进入钟楼，确认林晚雨衣纤维。')
    ]
  },
  {
    id: 'E10_WET_FOOTPRINTS',
    sceneId: SCENE_BELL_TOWER,
    title: '脚印没有互相追赶',
    eyebrow: '现场勘察 / 路线',
    location: '停摆钟楼 · 旋梯',
    narrative: '楼梯上的两组湿脚印保持着一臂距离。如果一个人挟持另一个人，脚印不会在每次转角都停下来等待。',
    speaker: '调查记录',
    dialogue: '先判断“是否被带走”，再决定是否追向那道一闪而过的影子。',
    choices: [
      choice('chase_shadow', '追上雨幕中的影子', '可能抢到物证，也可能丢掉现场证据', 'risk', 'E11_CLOCK_GEAR', 'clue_keycard', 'shadow_chased', 0, 1, '追上雨幕中的身影，只捡到一张折断的备用门禁卡。'),
      choice('protect_footprints', '保留现场并观察等待', '获得更完整的行为证据', 'soft', 'E11_CLOCK_GEAR', 'clue_footprint', 'footprints_preserved', 1, 0, '没有追影子，完整记录两人共同上楼的行为节奏。')
    ]
  },
  {
    id: 'E11_CLOCK_GEAR',
    sceneId: SCENE_BELL_TOWER,
    title: '齿轮咬住了旧终端编号',
    eyebrow: '机械室 / 暗号',
    location: '停摆钟楼 · 机械室',
    narrative: '黄铜齿轮的齿根有一组新刻痕。它对应三年前那份未公开事故报告的编号，而不是钟表的维护日期。',
    speaker: '林晚 / 预先留下的语音',
    dialogue: '“如果你找到这里，说明记录已经开始说真话。去控制室，不要相信门外的脚步声。”',
    choices: [
      choice('inspect_gear_marks', '按编号检查齿轮', '需要有效的进入路线证据', 'primary', 'E12_VOICE_WALL', 'clue_gear_scratch', 'gear_mark_solved', 1, 0, '解读齿轮刻痕，定位旧控制室。', [], [], '还没有确认一条可行且可回溯的进入路线。', ['clue_clock_dust', 'clue_window_thread']),
      choice('short_circuit_cable', '直接短接电缆恢复控制室', '会留下熔断痕迹，压力上升', 'risk', 'E12_VOICE_WALL', 'clue_burn_trace', 'cable_short_circuited', -1, 2, '短接电缆恢复旧控制室，留下熔断痕迹。')
    ]
  },
  {
    id: 'E12_VOICE_WALL',
    sceneId: SCENE_BELL_TOWER,
    title: '声音藏在墙的背面',
    eyebrow: '关键证词 / 选择',
    location: '停摆钟楼 · 声墙',
    narrative: '隔音棉后传来极轻的按键声。墙面上嵌着老式录音触点，只有持续供电时才会播放完整留言。',
    speaker: '林晚 / 录音',
    dialogue: '“我请求周岚帮我离开监控范围。不是绑架，是我要带走事故原始数据。”',
    choices: [
      choice('play_full_message', '修复触点并播放完整留言', '需要完整录音作为声纹索引', 'primary', 'E13_HIDDEN_DOOR', 'clue_confession', 'heard_confession', 2, 0, '修复录音触点，确认林晚主动请求周岚协助。', ['clue_recorder'], [], '录音缺少完整声纹索引，无法校验墙内留言。'),
      choice('trust_intuition', '依据现场静默判断', '可继续行动，但证词链不完整', 'soft', 'E13_HIDDEN_DOOR', 'clue_silence', 'followed_intuition', 0, 1, '根据现场空间判断林晚曾在此停留，但没有取得完整证词。')
    ]
  },
  {
    id: 'E13_HIDDEN_DOOR',
    sceneId: SCENE_BELL_TOWER,
    title: '门后没有呼救',
    eyebrow: '最后现场 / 安全确认',
    location: '停摆钟楼 · 旧控制室入口',
    narrative: '墙后是一扇没有把手的维护门。门缝透出屏幕微光，里面传来稳定而克制的敲击声。',
    speaker: '敲击信号',
    dialogue: '三短一长。那是林晚加入调查社时约定的信号，意思是“我安全，但先听我说完”。',
    choices: [
      choice('open_with_evidence', '用门禁卡打开维护门', '需要：钟楼门禁或机械证据', 'primary', 'E14_LAST_RESPONSE', 'clue_thermal', 'found_lin_wan', 1, 0, '打开维护门，确认林晚正在主动备份事故数据。', [], [], '无法稳定识别维护门锁结构，暂时不能安全开启。', ['clue_keycard', 'clue_gear_scratch']),
      choice('answer_knock_code', '敲击同一段代码等待回应', '以尊重证人选择的方式进入', 'soft', 'E14_LAST_RESPONSE', 'clue_signal', 'answered_by_knock', 2, 0, '用调查社暗号回应敲击，林晚主动打开维护门。')
    ]
  },
  {
    id: 'E14_LAST_RESPONSE',
    sceneId: SCENE_BELL_TOWER,
    title: '证据已经安全，真相还在门外',
    eyebrow: '阶段完成 / 推理准备',
    location: '停摆钟楼 · 旧控制室',
    narrative: '林晚坐在离线服务器前，屏幕上显示事故数据 100% 归档。她没有受伤，只是担心数据再次被带离学校。',
    speaker: '林晚',
    dialogue: '“你可以现在就写新闻，但先告诉我：谁应该为这三年的沉默负责？”',
    choices: [
      choice('begin_final_deduction', '封存现场，开始最终推理', '根据证据链指出责任人与动机', 'primary', '', '', 'final_deduction_ready', 1, 0, '完成三处现场调查，进入最终推理。')
    ]
  }
];

export const ENDINGS: EndingDef[] = [
  {
    id: ENDING_TRUTH,
    title: '雾散之后',
    subtitle: '真相结局 / A 级档案',
    description: '你证明林晚是主动藏身，并确认周岚帮助她保护了被压制的事故数据。没有替任何人洗清责任，也没有把求助误判成犯罪。',
    meaning: '完整的证据链使失踪案转入实验事故调查。林晚公开了原始数据，周岚接受调查，校园动力系统开始全面检修。'
  },
  {
    id: ENDING_ECHO,
    title: '回声失踪',
    subtitle: '条件不足 / B 级档案',
    description: '你找到了林晚，却没能用足够证据解释这场行动。记录被仓促封存，钟楼重新上锁，雾中的回声仍被当成一桩未遂绑架案。',
    meaning: '林晚安全离开，但事故责任没有被完整追溯。证据缺口让真相再次回到沉默。你可以重开案件，尝试另一条调查路线。'
  }
];
