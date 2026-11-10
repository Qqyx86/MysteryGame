import { CLUES, ENDINGS, SCENES, STORY_EVENTS } from '../data/StoryCatalog';
import {
  ActionResult,
  ChoiceDef,
  ClueDef,
  DeductionResult,
  ENDING_ECHO,
  ENDING_TRUTH,
  EndingDef,
  GameState,
  JournalEntry,
  PHASE_DEDUCTION,
  PHASE_ENDING,
  PHASE_INVESTIGATING,
  SAVE_VERSION,
  SCENE_BELL_TOWER,
  SCENE_LAB,
  SCENE_LIBRARY,
  SceneCursor,
  SceneDef,
  SceneProgress,
  StoryEventDef
} from '../models/GameModels';

const SUSPECT_ZHOU: string = 'zhou_lan';
const MOTIVE_COVERUP: string = 'coverup';

function unique(values: string[]): string[] {
  const result: string[] = [];
  for (let index = 0; index < values.length; index++) {
    const value = values[index];
    if (value.length > 0 && result.indexOf(value) < 0) {
      result.push(value);
    }
  }
  return result;
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}

function safeTime(value: number): number {
  if (!Number.isFinite(value) || value <= 0) {
    return Date.now();
  }
  return value;
}

function initialCursors(): SceneCursor[] {
  return [
    { sceneId: SCENE_LIBRARY, nodeId: 'E01_CASE_BRIEF', completed: false },
    { sceneId: SCENE_LAB, nodeId: 'E05_LAB_GATE', completed: false },
    { sceneId: SCENE_BELL_TOWER, nodeId: 'E09_BELL_GATE', completed: false }
  ];
}

export function createInitialState(): GameState {
  const now = Date.now();
  return {
    saveVersion: SAVE_VERSION,
    phase: PHASE_INVESTIGATING,
    activeSceneId: SCENE_LIBRARY,
    sceneCursors: initialCursors(),
    discoveredClues: [],
    flags: [],
    visitedEvents: [],
    journal: [],
    trust: 1,
    pressure: 0,
    suspect: '',
    motive: '',
    endingId: '',
    bestEndingId: '',
    startedAt: now,
    lastSavedAt: 0
  };
}

export function startNewGame(previous: GameState | null = null): GameState {
  const next = createInitialState();
  if (previous !== null && previous.bestEndingId.length > 0) {
    next.bestEndingId = previous.bestEndingId;
  }
  return next;
}

export function cloneState(state: GameState): GameState {
  const cursors: SceneCursor[] = [];
  for (let index = 0; index < state.sceneCursors.length; index++) {
    const cursor = state.sceneCursors[index];
    cursors.push({
      sceneId: cursor.sceneId,
      nodeId: cursor.nodeId,
      completed: cursor.completed
    });
  }

  const journal: JournalEntry[] = [];
  for (let index = 0; index < state.journal.length; index++) {
    const entry = state.journal[index];
    journal.push({
      eventId: entry.eventId,
      eventTitle: entry.eventTitle,
      choiceLabel: entry.choiceLabel,
      note: entry.note,
      time: entry.time
    });
  }

  return {
    saveVersion: state.saveVersion,
    phase: state.phase,
    activeSceneId: state.activeSceneId,
    sceneCursors: cursors,
    discoveredClues: state.discoveredClues.slice(),
    flags: state.flags.slice(),
    visitedEvents: state.visitedEvents.slice(),
    journal: journal,
    trust: state.trust,
    pressure: state.pressure,
    suspect: state.suspect,
    motive: state.motive,
    endingId: state.endingId,
    bestEndingId: state.bestEndingId,
    startedAt: state.startedAt,
    lastSavedAt: state.lastSavedAt
  };
}

export function findScene(sceneId: string): SceneDef | null {
  for (let index = 0; index < SCENES.length; index++) {
    if (SCENES[index].id === sceneId) {
      return SCENES[index];
    }
  }
  return null;
}

export function findEvent(eventId: string): StoryEventDef | null {
  for (let index = 0; index < STORY_EVENTS.length; index++) {
    if (STORY_EVENTS[index].id === eventId) {
      return STORY_EVENTS[index];
    }
  }
  return null;
}

export function findClue(clueId: string): ClueDef | null {
  for (let index = 0; index < CLUES.length; index++) {
    if (CLUES[index].id === clueId) {
      return CLUES[index];
    }
  }
  return null;
}

export function findEnding(endingId: string): EndingDef | null {
  for (let index = 0; index < ENDINGS.length; index++) {
    if (ENDINGS[index].id === endingId) {
      return ENDINGS[index];
    }
  }
  return null;
}

export function getSceneCursor(state: GameState, sceneId: string): SceneCursor | null {
  for (let index = 0; index < state.sceneCursors.length; index++) {
    if (state.sceneCursors[index].sceneId === sceneId) {
      return state.sceneCursors[index];
    }
  }
  return null;
}

export function getCurrentEvent(state: GameState): StoryEventDef | null {
  const cursor = getSceneCursor(state, state.activeSceneId);
  if (cursor === null || cursor.completed || cursor.nodeId.length === 0) {
    return null;
  }
  return findEvent(cursor.nodeId);
}

export function hasClue(state: GameState, clueId: string): boolean {
  return state.discoveredClues.indexOf(clueId) >= 0;
}

export function hasFlag(state: GameState, flag: string): boolean {
  return state.flags.indexOf(flag) >= 0;
}

export function isSceneComplete(state: GameState, sceneId: string): boolean {
  const cursor = getSceneCursor(state, sceneId);
  return cursor !== null && cursor.completed;
}

export function isSceneUnlocked(state: GameState, sceneId: string): boolean {
  if (sceneId === SCENE_LIBRARY) {
    return true;
  }
  if (sceneId === SCENE_LAB) {
    return isSceneComplete(state, SCENE_LIBRARY);
  }
  if (sceneId === SCENE_BELL_TOWER) {
    return isSceneComplete(state, SCENE_LAB);
  }
  return false;
}

export function selectScene(state: GameState, sceneId: string): ActionResult {
  if (!isSceneUnlocked(state, sceneId)) {
    return {
      accepted: false,
      state: state,
      message: '该现场尚未解锁，请先完成当前调查阶段。',
      addedClueId: ''
    };
  }

  const next = cloneState(state);
  next.activeSceneId = sceneId;
  return {
    accepted: true,
    state: next,
    message: '已切换调查现场。',
    addedClueId: ''
  };
}

function missingClueTitle(state: GameState, choiceDef: ChoiceDef): string {
  for (let index = 0; index < choiceDef.requiredClues.length; index++) {
    const clueId = choiceDef.requiredClues[index];
    if (!hasClue(state, clueId)) {
      const clue = findClue(clueId);
      if (clue !== null) {
        return clue.title;
      }
    }
  }
  return '';
}

export function isChoiceAvailable(state: GameState, choiceDef: ChoiceDef): boolean {
  for (let index = 0; index < choiceDef.requiredClues.length; index++) {
    if (!hasClue(state, choiceDef.requiredClues[index])) {
      return false;
    }
  }
  for (let index = 0; index < choiceDef.requiredFlags.length; index++) {
    if (!hasFlag(state, choiceDef.requiredFlags[index])) {
      return false;
    }
  }
  if (choiceDef.requiredAnyClues.length > 0) {
    let anyFound = false;
    for (let index = 0; index < choiceDef.requiredAnyClues.length; index++) {
      if (hasClue(state, choiceDef.requiredAnyClues[index])) {
        anyFound = true;
        break;
      }
    }
    if (!anyFound) {
      return false;
    }
  }
  return true;
}

export function getChoiceBlockedReason(state: GameState, choiceDef: ChoiceDef): string {
  if (isChoiceAvailable(state, choiceDef)) {
    return '';
  }
  const missingClue = missingClueTitle(state, choiceDef);
  if (missingClue.length > 0) {
    return `缺少线索：${missingClue}`;
  }
  if (choiceDef.requiredAnyClues.length > 0) {
    const alternativeTitles: string[] = [];
    for (let index = 0; index < choiceDef.requiredAnyClues.length; index++) {
      const clue = findClue(choiceDef.requiredAnyClues[index]);
      if (clue !== null) {
        alternativeTitles.push(clue.title);
      }
    }
    if (alternativeTitles.length > 0) {
      return `缺少任一可用线索：${alternativeTitles.join(' 或 ')}`;
    }
  }
  if (choiceDef.blockedReason.length > 0) {
    return choiceDef.blockedReason;
  }
  return '当前条件尚未满足。';
}

function appendUnique(target: string[], value: string): boolean {
  if (value.length === 0 || target.indexOf(value) >= 0) {
    return false;
  }
  target.push(value);
  return true;
}

export function applyChoice(state: GameState, choiceId: string): ActionResult {
  if (state.phase !== PHASE_INVESTIGATING) {
    return {
      accepted: false,
      state: state,
      message: '案件已经进入最终阶段，不能再执行现场选择。',
      addedClueId: ''
    };
  }

  const event = getCurrentEvent(state);
  if (event === null) {
    return {
      accepted: false,
      state: state,
      message: '当前现场没有可执行的事件。',
      addedClueId: ''
    };
  }

  let selected: ChoiceDef | null = null;
  for (let index = 0; index < event.choices.length; index++) {
    if (event.choices[index].id === choiceId) {
      selected = event.choices[index];
      break;
    }
  }
  if (selected === null) {
    return {
      accepted: false,
      state: state,
      message: '选择不存在，操作已取消。',
      addedClueId: ''
    };
  }
  if (!isChoiceAvailable(state, selected)) {
    return {
      accepted: false,
      state: state,
      message: getChoiceBlockedReason(state, selected),
      addedClueId: ''
    };
  }

  const next = cloneState(state);
  appendUnique(next.visitedEvents, event.id);
  const addedClue = appendUnique(next.discoveredClues, selected.addClueId) ? selected.addClueId : '';
  appendUnique(next.flags, selected.addFlag);
  next.trust = clamp(next.trust + selected.trustDelta, 0, 5);
  next.pressure = clamp(next.pressure + selected.pressureDelta, 0, 5);

  const entry: JournalEntry = {
    eventId: event.id,
    eventTitle: event.title,
    choiceLabel: selected.label,
    note: selected.journalText,
    time: Date.now()
  };
  next.journal.unshift(entry);

  for (let index = 0; index < next.sceneCursors.length; index++) {
    const cursor = next.sceneCursors[index];
    if (cursor.sceneId === event.sceneId) {
      if (selected.nextNodeId.length === 0) {
        cursor.nodeId = '';
        cursor.completed = true;
      } else {
        cursor.nodeId = selected.nextNodeId;
      }
      break;
    }
  }

  if (isSceneComplete(next, SCENE_BELL_TOWER)) {
    next.phase = PHASE_DEDUCTION;
  }

  const clue = findClue(addedClue);
  let message = selected.journalText;
  if (clue !== null) {
    message = `归档新线索：${clue.title}`;
  }
  if (next.phase === PHASE_DEDUCTION) {
    message = '三处现场调查完成。证据已封存，请进入最终推理。';
  }

  return {
    accepted: true,
    state: next,
    message: message,
    addedClueId: addedClue
  };
}

export function getVisitedEventCount(state: GameState): number {
  return state.visitedEvents.length;
}

export function getProgressPercent(state: GameState): number {
  if (state.phase === PHASE_DEDUCTION) {
    return 92;
  }
  if (state.phase === PHASE_ENDING) {
    return 100;
  }
  const percent = Math.round((state.visitedEvents.length / STORY_EVENTS.length) * 88);
  return clamp(percent, 0, 88);
}

export function getSceneProgress(state: GameState, sceneId: string): SceneProgress {
  let total = 0;
  let visited = 0;
  for (let index = 0; index < STORY_EVENTS.length; index++) {
    if (STORY_EVENTS[index].sceneId === sceneId) {
      total++;
      if (state.visitedEvents.indexOf(STORY_EVENTS[index].id) >= 0) {
        visited++;
      }
    }
  }
  return {
    visited: visited,
    total: total,
    percent: total === 0 ? 0 : Math.round((visited / total) * 100)
  };
}

export function getPhaseLabel(state: GameState): string {
  if (state.phase === PHASE_ENDING) {
    return '档案已结案';
  }
  if (state.phase === PHASE_DEDUCTION) {
    return '最终推理';
  }
  if (state.activeSceneId === SCENE_LIBRARY) {
    return '第一章 · 失真的记录';
  }
  if (state.activeSceneId === SCENE_LAB) {
    return '第二章 · 被选中的停电';
  }
  return '第三章 · 钟楼下的回声';
}

export function getEvidenceScore(state: GameState): number {
  const evidenceGroups: string[][] = [
    ['clue_loan_log', 'clue_badge', 'clue_guard_log'],
    ['clue_recorder', 'clue_audio_clip', 'clue_confession'],
    ['clue_power_trace', 'clue_manual_switch'],
    ['clue_tower_power', 'clue_window_thread'],
    ['clue_keycard', 'clue_footprint'],
    ['clue_gear_scratch', 'clue_burn_trace'],
    ['clue_confession', 'clue_silence'],
    ['clue_thermal', 'clue_signal']
  ];
  let score = 0;
  for (let groupIndex = 0; groupIndex < evidenceGroups.length; groupIndex++) {
    const group = evidenceGroups[groupIndex];
    let found = false;
    for (let clueIndex = 0; clueIndex < group.length; clueIndex++) {
      if (hasClue(state, group[clueIndex])) {
        found = true;
        break;
      }
    }
    if (found) {
      score++;
    }
  }
  return score;
}

export function finalizeDeduction(state: GameState, suspect: string, motive: string): DeductionResult {
  if (state.phase !== PHASE_DEDUCTION) {
    return {
      accepted: false,
      state: state,
      message: '尚未收集完现场记录，不能提交最终判断。',
      endingId: '',
      evidenceScore: getEvidenceScore(state),
      grade: ''
    };
  }
  if (suspect.length === 0 || motive.length === 0) {
    return {
      accepted: false,
      state: state,
      message: '请先选择责任人和行为动机。',
      endingId: '',
      evidenceScore: getEvidenceScore(state),
      grade: ''
    };
  }

  const score = getEvidenceScore(state);
  const isTruth = suspect === SUSPECT_ZHOU && motive === MOTIVE_COVERUP && score >= 6;
  const next = cloneState(state);
  next.suspect = suspect;
  next.motive = motive;
  next.endingId = isTruth ? ENDING_TRUTH : ENDING_ECHO;
  next.phase = PHASE_ENDING;
  if (isTruth) {
    next.bestEndingId = ENDING_TRUTH;
  }

  return {
    accepted: true,
    state: next,
    message: isTruth ? '证据链闭合，真相归档。' : '证据条件不足，案件以未完整档案结案。',
    endingId: next.endingId,
    evidenceScore: score,
    grade: isTruth ? (score >= 7 ? 'A+' : 'A') : 'B'
  };
}

export function normalizeState(candidate: GameState): GameState {
  const base = createInitialState();
  if (candidate === null || candidate === undefined) {
    return base;
  }

  if (candidate.saveVersion !== SAVE_VERSION) {
    return startNewGame(candidate);
  }

  base.activeSceneId = candidate.activeSceneId;
  if (findScene(base.activeSceneId) === null) {
    base.activeSceneId = SCENE_LIBRARY;
  }

  const phases = [PHASE_INVESTIGATING, PHASE_DEDUCTION, PHASE_ENDING];
  if (phases.indexOf(candidate.phase) >= 0) {
    base.phase = candidate.phase;
  }

  for (let cursorIndex = 0; cursorIndex < base.sceneCursors.length; cursorIndex++) {
    const defaultCursor = base.sceneCursors[cursorIndex];
    const saved = getSceneCursor(candidate, defaultCursor.sceneId);
    if (saved !== null) {
      const event = findEvent(saved.nodeId);
      if (event !== null && event.sceneId === defaultCursor.sceneId) {
        defaultCursor.nodeId = saved.nodeId;
        defaultCursor.completed = false;
      } else if (saved.completed) {
        defaultCursor.nodeId = '';
        defaultCursor.completed = true;
      }
    }
  }

  if (Array.isArray(candidate.discoveredClues)) {
    for (let index = 0; index < candidate.discoveredClues.length; index++) {
      if (findClue(candidate.discoveredClues[index]) !== null) {
        appendUnique(base.discoveredClues, candidate.discoveredClues[index]);
      }
    }
  }
  if (Array.isArray(candidate.flags)) {
    base.flags = unique(candidate.flags);
  }
  if (Array.isArray(candidate.visitedEvents)) {
    for (let index = 0; index < candidate.visitedEvents.length; index++) {
      if (findEvent(candidate.visitedEvents[index]) !== null) {
        appendUnique(base.visitedEvents, candidate.visitedEvents[index]);
      }
    }
  }
  if (Array.isArray(candidate.journal)) {
    base.journal = candidate.journal.slice(0, 30);
  }

  base.trust = clamp(Number.isFinite(candidate.trust) ? candidate.trust : 1, 0, 5);
  base.pressure = clamp(Number.isFinite(candidate.pressure) ? candidate.pressure : 0, 0, 5);
  base.suspect = candidate.suspect === undefined ? '' : candidate.suspect;
  base.motive = candidate.motive === undefined ? '' : candidate.motive;
  base.startedAt = safeTime(candidate.startedAt);
  base.lastSavedAt = candidate.lastSavedAt > 0 ? candidate.lastSavedAt : 0;
  base.endingId = findEnding(candidate.endingId) === null ? '' : candidate.endingId;
  base.bestEndingId = findEnding(candidate.bestEndingId) === null ? '' : candidate.bestEndingId;

  if (base.phase === PHASE_ENDING && base.endingId.length === 0) {
    base.phase = PHASE_INVESTIGATING;
  }
  return base;
}
