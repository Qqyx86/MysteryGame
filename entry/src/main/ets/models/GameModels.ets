export const SAVE_VERSION: number = 2;

export const PHASE_INVESTIGATING: string = 'investigating';
export const PHASE_DEDUCTION: string = 'deduction';
export const PHASE_ENDING: string = 'ending';

export const SCENE_LIBRARY: string = 'library';
export const SCENE_LAB: string = 'lab';
export const SCENE_BELL_TOWER: string = 'bell_tower';

export const ENDING_TRUTH: string = 'ending_truth';
export const ENDING_ECHO: string = 'ending_echo';

export interface SceneDef {
  id: string;
  index: string;
  title: string;
  subtitle: string;
  description: string;
  atmosphere: string;
  accent: string;
}

export interface ChoiceDef {
  id: string;
  label: string;
  hint: string;
  tone: string;
  nextNodeId: string;
  requiredClues: string[];
  requiredAnyClues: string[];
  requiredFlags: string[];
  blockedReason: string;
  addClueId: string;
  addFlag: string;
  trustDelta: number;
  pressureDelta: number;
  journalText: string;
}

export interface StoryEventDef {
  id: string;
  sceneId: string;
  title: string;
  eyebrow: string;
  location: string;
  narrative: string;
  speaker: string;
  dialogue: string;
  choices: ChoiceDef[];
}

export interface ClueDef {
  id: string;
  title: string;
  source: string;
  summary: string;
  detail: string;
  tag: string;
  keyEvidence: boolean;
}

export interface EndingDef {
  id: string;
  title: string;
  subtitle: string;
  description: string;
  meaning: string;
}

export interface SceneCursor {
  sceneId: string;
  nodeId: string;
  completed: boolean;
}

export interface JournalEntry {
  eventId: string;
  eventTitle: string;
  choiceLabel: string;
  note: string;
  time: number;
}

export interface GameState {
  saveVersion: number;
  phase: string;
  activeSceneId: string;
  sceneCursors: SceneCursor[];
  discoveredClues: string[];
  flags: string[];
  visitedEvents: string[];
  journal: JournalEntry[];
  trust: number;
  pressure: number;
  suspect: string;
  motive: string;
  endingId: string;
  bestEndingId: string;
  startedAt: number;
  lastSavedAt: number;
}

export interface ActionResult {
  accepted: boolean;
  state: GameState;
  message: string;
  addedClueId: string;
}

export interface DeductionResult {
  accepted: boolean;
  state: GameState;
  message: string;
  endingId: string;
  evidenceScore: number;
  grade: string;
}

export interface SceneProgress {
  visited: number;
  total: number;
  percent: number;
}
