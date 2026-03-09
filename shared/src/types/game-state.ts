import { Card } from './card';
import { Meld } from './meld';
import { Player } from './player';
import { GameConfig } from './game-config';

export enum GamePhase {
  Waiting = 'waiting',
  Dealing = 'dealing',
  PlayerTurn = 'player_turn',
  RoundEnd = 'round_end',
  GameEnd = 'game_end',
}

export enum TurnStep {
  /** Player must draw */
  Draw = 'draw',
  /** Player has drawn, may meld/layoff, must discard */
  Play = 'play',
}

export interface GameState {
  id: string;
  config: GameConfig;
  phase: GamePhase;
  turnStep: TurnStep;
  players: Player[];
  currentPlayerIndex: number;
  drawPile: Card[];
  discardPile: Card[];
  /** All melds on the table (from all players) */
  tableMelds: Meld[];
  round: number;
  turnCount: number;
  winnerId: string | null;
  lastAction: GameAction | null;
}

// ─── Actions ─────────────────────────────────────────────────

export type GameAction =
  | { type: 'draw_from_deck'; playerId: string }
  | { type: 'draw_from_discard'; playerId: string }
  | { type: 'draw_deck'; playerId: string }       // alias for draw_from_deck (Flutter/simple-server compat)
  | { type: 'draw_discard'; playerId: string }     // alias for draw_from_discard (Flutter/simple-server compat)
  | { type: 'meld'; playerId: string; cardIds: number[]; meldType?: string }
  | { type: 'confirm_opening'; playerId: string }
  | { type: 'cancel_staging'; playerId: string }
  | { type: 'layoff'; playerId: string; cardId: number; targetMeldId: string; position: 'start' | 'end' }
  | { type: 'replace_joker'; playerId: string; cardId: number; targetMeldId: string; jokerCardId: number }
  | { type: 'discard'; playerId: string; cardId: number }
  | { type: 'end_turn'; playerId: string };

// ─── Errors ──────────────────────────────────────────────────

export class GameError extends Error {
  constructor(
    public code: string,
    message: string,
  ) {
    super(message);
    this.name = 'GameError';
  }
}

