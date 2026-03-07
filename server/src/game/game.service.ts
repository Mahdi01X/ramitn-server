import { Injectable } from '@nestjs/common';
import {
  createGame, startRound, applyAction, getValidActions, sanitizeStateForPlayer,
  GameState, GameAction, GamePhase, GameError, GameConfig,
} from '@rami/shared';

@Injectable()
export class GameService {
  /** Active games stored in memory (use Redis for production scaling) */
  private games = new Map<string, GameState>();

  create(
    playerInfos: { id: string; name: string; isBot: boolean }[],
    config: Partial<GameConfig>,
  ): GameState {
    const state = createGame(playerInfos, config);
    this.games.set(state.id, state);
    return state;
  }

  startNewRound(gameId: string): GameState {
    const state = this.games.get(gameId);
    if (!state) throw new Error('Game not found');

    const newState = startRound(state);
    this.games.set(gameId, newState);
    return newState;
  }

  performAction(gameId: string, action: GameAction): GameState {
    const state = this.games.get(gameId);
    if (!state) throw new Error('Game not found');

    const newState = applyAction(state, action);
    this.games.set(gameId, newState);
    return newState;
  }

  getState(gameId: string): GameState | undefined {
    return this.games.get(gameId);
  }

  getSanitizedState(gameId: string, playerId: string) {
    const state = this.games.get(gameId);
    if (!state) return undefined;
    return sanitizeStateForPlayer(state, playerId);
  }

  getValidActions(gameId: string) {
    const state = this.games.get(gameId);
    if (!state) return [];
    return getValidActions(state);
  }

  removeGame(gameId: string): void {
    this.games.delete(gameId);
  }
}

