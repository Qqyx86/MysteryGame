import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GameState } from '../models/GameModels';
import { decodeSave, encodeSave } from '../domain/SaveCodec';

const LOG_DOMAIN: number = 0x1201;
const LOG_TAG: string = 'MysteryGameRepository';
const STORE_NAME: string = 'mystery_case_store';
const SAVE_KEY: string = 'active_case_v2';

export class GameRepository {
  private store: preferences.Preferences | null = null;

  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.store !== null) {
      return;
    }
    try {
      this.store = await preferences.getPreferences(context, STORE_NAME);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Unable to open preferences: %{public}s', JSON.stringify(error));
      this.store = null;
    }
  }

  async load(): Promise<GameState | null> {
    if (this.store === null) {
      return null;
    }
    try {
      const rawValue = await this.store.get(SAVE_KEY, '') as string;
      return decodeSave(rawValue);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Unable to load save: %{public}s', JSON.stringify(error));
      return null;
    }
  }

  async save(state: GameState): Promise<void> {
    if (this.store === null) {
      throw new Error('Preferences store is not initialized');
    }
    try {
      await this.store.put(SAVE_KEY, encodeSave(state));
      await this.store.flush();
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Unable to save state: %{public}s', JSON.stringify(error));
      throw new Error('Unable to save the current case');
    }
  }

  async clear(): Promise<void> {
    if (this.store === null) {
      return;
    }
    try {
      await this.store.delete(SAVE_KEY);
      await this.store.flush();
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, 'Unable to clear save: %{public}s', JSON.stringify(error));
    }
  }
}
