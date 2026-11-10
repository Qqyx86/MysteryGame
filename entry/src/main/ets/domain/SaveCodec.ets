import { GameState, SAVE_VERSION } from '../models/GameModels';
import { normalizeState } from './GameEngine';

export function encodeSave(state: GameState): string {
  return JSON.stringify(state);
}

export function decodeSave(rawValue: string): GameState | null {
  if (rawValue.length === 0) {
    return null;
  }
  try {
    const parsed = JSON.parse(rawValue) as GameState;
    if (parsed === null || parsed.saveVersion !== SAVE_VERSION) {
      return null;
    }
    return normalizeState(parsed);
  } catch (error) {
    return null;
  }
}
