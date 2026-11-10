import { describe, it, expect } from '@ohos/hypium';
import { CLUES, ENDINGS, SCENES, STORY_EVENTS } from '../main/ets/data/StoryCatalog';
import {
  applyChoice,
  createInitialState,
  finalizeDeduction,
  getCurrentEvent,
  getEvidenceScore,
  getProgressPercent,
  getSceneCursor,
  isChoiceAvailable,
  isSceneUnlocked,
  selectScene
} from '../main/ets/domain/GameEngine';
import { decodeSave, encodeSave } from '../main/ets/domain/SaveCodec';
import {
  ENDING_ECHO,
  ENDING_TRUTH,
  GameState,
  PHASE_DEDUCTION,
  SCENE_BELL_TOWER,
  SCENE_LAB,
  SCENE_LIBRARY,
  StoryEventDef
} from '../main/ets/models/GameModels';

function choose(state: GameState, choiceId: string): GameState {
  const result = applyChoice(state, choiceId);
  expect(result.accepted).assertTrue();
  return result.state;
}

function completeCaseWithBestEvidence(): GameState {
  let state = createInitialState();
  state = choose(state, 'accept_case');
  state = choose(state, 'inspect_loan');
  state = choose(state, 'open_with_card');
  state = choose(state, 'support_guard');

  const labSelection = selectScene(state, SCENE_LAB);
  expect(labSelection.accepted).assertTrue();
  state = labSelection.state;
  state = choose(state, 'trace_badge');
  state = choose(state, 'listen_complete_audio');
  state = choose(state, 'show_full_audio');
  state = choose(state, 'compare_power_graphs');

  const bellSelection = selectScene(state, SCENE_BELL_TOWER);
  expect(bellSelection.accepted).assertTrue();
  state = bellSelection.state;
  state = choose(state, 'open_with_badge');
  state = choose(state, 'protect_footprints');
  state = choose(state, 'inspect_gear_marks');
  state = choose(state, 'play_full_message');
  state = choose(state, 'open_with_evidence');
  state = choose(state, 'begin_final_deduction');
  return state;
}

export default function mysteryGameEngineTest() {
  describe('MysteryGameDomain', () => {
    it('story_catalog_meets_assignment_minimums', 0, () => {
      expect(SCENES.length >= 3).assertTrue();
      expect(STORY_EVENTS.length >= 12).assertTrue();
      expect(CLUES.length >= 6).assertTrue();
      expect(ENDINGS.length >= 2).assertTrue();
    });

    it('new_game_starts_at_library_with_persistable_schema', 0, () => {
      const state = createInitialState();
      expect(state.activeSceneId).assertEqual(SCENE_LIBRARY);
      expect(state.saveVersion).assertEqual(2);
      expect(state.discoveredClues.length).assertEqual(0);
      const event = getCurrentEvent(state);
      expect(event !== null).assertTrue();
      if (event !== null) {
        expect(event.id).assertEqual('E01_CASE_BRIEF');
      }
    });

    it('library_choice_adds_clue_and_advances_node', 0, () => {
      let state = createInitialState();
      state = choose(state, 'accept_case');
      state = choose(state, 'inspect_loan');
      expect(state.discoveredClues.indexOf('clue_loan_log') >= 0).assertTrue();
      const cursor = getSceneCursor(state, SCENE_LIBRARY);
      expect(cursor !== null).assertTrue();
      if (cursor !== null) {
        expect(cursor.nodeId).assertEqual('E03_SEALED_ARCHIVE');
      }
    });

    it('missing_clue_blocks_archive_unlock', 0, () => {
      let state = createInitialState();
      state = choose(state, 'accept_case');
      state = choose(state, 'skip_borrow_record');
      const event = getCurrentEvent(state);
      expect(event !== null).assertTrue();
      if (event !== null) {
        const protectedChoice = event.choices[0];
        expect(isChoiceAvailable(state, protectedChoice)).assertFalse();
        const blocked = applyChoice(state, 'open_with_card');
        expect(blocked.accepted).assertFalse();
      }
    });

    it('scenes_unlock_in_story_order', 0, () => {
      let state = createInitialState();
      expect(isSceneUnlocked(state, SCENE_LAB)).assertFalse();
      expect(isSceneUnlocked(state, SCENE_BELL_TOWER)).assertFalse();
      state = choose(state, 'accept_case');
      state = choose(state, 'inspect_loan');
      state = choose(state, 'open_with_card');
      state = choose(state, 'support_guard');
      expect(isSceneUnlocked(state, SCENE_LAB)).assertTrue();
      expect(isSceneUnlocked(state, SCENE_BELL_TOWER)).assertFalse();
    });

    it('branch_choice_changes_later_availability', 0, () => {
      let completeAudioState = createInitialState();
      completeAudioState = choose(completeAudioState, 'accept_case');
      completeAudioState = choose(completeAudioState, 'inspect_loan');
      completeAudioState = choose(completeAudioState, 'open_with_card');
      completeAudioState = choose(completeAudioState, 'support_guard');
      const audioSelection = selectScene(completeAudioState, SCENE_LAB);
      completeAudioState = audioSelection.state;
      completeAudioState = choose(completeAudioState, 'trace_badge');
      completeAudioState = choose(completeAudioState, 'listen_complete_audio');
      const assistantEvent = getCurrentEvent(completeAudioState) as StoryEventDef;
      expect(isChoiceAvailable(completeAudioState, assistantEvent.choices[0])).assertTrue();

      let partialAudioState = createInitialState();
      partialAudioState = choose(partialAudioState, 'accept_case');
      partialAudioState = choose(partialAudioState, 'skip_borrow_record');
      partialAudioState = choose(partialAudioState, 'force_open_archive');
      partialAudioState = choose(partialAudioState, 'pressure_guard');
      const secondLabSelection = selectScene(partialAudioState, SCENE_LAB);
      partialAudioState = secondLabSelection.state;
      partialAudioState = choose(partialAudioState, 'enter_service_hall');
      partialAudioState = choose(partialAudioState, 'skip_to_last_minute');
      const partialAssistantEvent = getCurrentEvent(partialAudioState) as StoryEventDef;
      expect(isChoiceAvailable(partialAudioState, partialAssistantEvent.choices[0])).assertFalse();
    });

    it('alternative_route_evidence_unlocks_gear_analysis', 0, () => {
      let state = createInitialState();
      state = choose(state, 'accept_case');
      state = choose(state, 'inspect_loan');
      state = choose(state, 'open_with_card');
      state = choose(state, 'support_guard');
      state = selectScene(state, SCENE_LAB).state;
      state = choose(state, 'trace_badge');
      state = choose(state, 'listen_complete_audio');
      state = choose(state, 'show_full_audio');
      state = choose(state, 'compare_power_graphs');
      state = selectScene(state, SCENE_BELL_TOWER).state;
      state = choose(state, 'open_with_badge');
      state = choose(state, 'protect_footprints');
      const event = getCurrentEvent(state) as StoryEventDef;
      expect(event.id).assertEqual('E11_CLOCK_GEAR');
      expect(isChoiceAvailable(state, event.choices[0])).assertTrue();
    });

    it('complete_best_path_enters_deduction', 0, () => {
      const state = completeCaseWithBestEvidence();
      expect(state.phase).assertEqual(PHASE_DEDUCTION);
      expect(state.discoveredClues.length >= 6).assertTrue();
      expect(getEvidenceScore(state) >= 7).assertTrue();
      expect(getProgressPercent(state) >= 90).assertTrue();
    });

    it('correct_deduction_unlocks_truth_ending', 0, () => {
      const state = completeCaseWithBestEvidence();
      const result = finalizeDeduction(state, 'zhou_lan', 'coverup');
      expect(result.accepted).assertTrue();
      expect(result.endingId).assertEqual(ENDING_TRUTH);
      expect(result.grade).assertEqual('A+');
    });

    it('wrong_suspect_unlocks_echo_ending', 0, () => {
      const state = completeCaseWithBestEvidence();
      const result = finalizeDeduction(state, 'lin_che', 'coverup');
      expect(result.accepted).assertTrue();
      expect(result.endingId).assertEqual(ENDING_ECHO);
      expect(result.grade).assertEqual('B');
    });

    it('insufficient_evidence_cannot_claim_truth', 0, () => {
      const state = createInitialState();
      state.phase = PHASE_DEDUCTION;
      state.discoveredClues = ['clue_recorder'];
      const result = finalizeDeduction(state, 'zhou_lan', 'coverup');
      expect(result.accepted).assertTrue();
      expect(result.endingId).assertEqual(ENDING_ECHO);
      expect(result.evidenceScore < 6).assertTrue();
    });

    it('save_round_trip_restores_state', 0, () => {
      const state = completeCaseWithBestEvidence();
      const restored = decodeSave(encodeSave(state));
      expect(restored !== null).assertTrue();
      if (restored !== null) {
        expect(restored.phase).assertEqual(PHASE_DEDUCTION);
        expect(restored.discoveredClues.length).assertEqual(state.discoveredClues.length);
        expect(restored.activeSceneId).assertEqual(state.activeSceneId);
      }
    });

    it('malformed_save_is_rejected_without_exception', 0, () => {
      const malformed = decodeSave('{"saveVersion":2,"phase":');
      expect(malformed === null).assertTrue();
      const unsupported = decodeSave('{"saveVersion":1}');
      expect(unsupported === null).assertTrue();
    });
  });
}
