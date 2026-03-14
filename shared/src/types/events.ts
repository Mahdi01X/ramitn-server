import { GameState } from './game-state';
import { GameConfig } from './game-config';

// ─── Client → Server Events ─────────────────────────────────

export interface CreateRoomEvent {
  type: 'create_room';
  config: Partial<GameConfig>;
}

export interface JoinRoomEvent {
  type: 'join_room';
  roomCode: string;
}

export interface StartGameEvent {
  type: 'start_game';
}

export interface GameActionEvent {
  type: 'game_action';
  action: {
    type: string;
    cardIds?: number[];
    cardId?: number;
    targetMeldId?: string;
    jokerCardId?: number;
    position?: 'start' | 'end';
    meldType?: string;
  };
}

export interface ChatMessageEvent {
  type: 'chat_message';
  message: string;
}

export interface ReadyEvent {
  type: 'ready';
}

export interface MatchmakingEvent {
  type: 'join_matchmaking';
  preferredPlayers: number;
}

export interface LeaveRoomEvent {
  type: 'leave_room';
}

export interface ResignEvent {
  type: 'resign';
}

export type ClientEvent =
  | CreateRoomEvent
  | JoinRoomEvent
  | StartGameEvent
  | GameActionEvent
  | ChatMessageEvent
  | ReadyEvent
  | MatchmakingEvent
  | LeaveRoomEvent
  | ResignEvent;

// ─── Server → Client Events ─────────────────────────────────

export interface RoomCreatedEvent {
  type: 'room_created';
  roomCode: string;
  roomId: string;
}

export interface RoomJoinedEvent {
  type: 'room_joined';
  roomCode: string;
  players: { id: string; name: string; ready: boolean }[];
}

export interface PlayerJoinedEvent {
  type: 'player_joined';
  playerId: string;
  playerName: string;
}

export interface PlayerLeftEvent {
  type: 'player_left';
  playerId: string;
}

export interface PlayerReadyEvent {
  type: 'player_ready';
  playerId: string;
}

export interface GameStartedEvent {
  type: 'game_started';
}

export interface GameStateUpdateEvent {
  type: 'game_state_update';
  state: SanitizedGameState;
}

export interface GameErrorEvent {
  type: 'game_error';
  code: string;
  message: string;
}

export interface ChatBroadcastEvent {
  type: 'chat_broadcast';
  senderId: string;
  senderName: string;
  message: string;
  timestamp: number;
}

export interface RoundEndEvent {
  type: 'round_end';
  scores: Record<string, number>;
  totalScores: Record<string, number>;
  winnerId: string;
  round: number;
}

export interface GameEndEvent {
  type: 'game_end';
  finalScores: Record<string, number>;
  winnerId: string;
}

export type ServerEvent =
  | RoomCreatedEvent
  | RoomJoinedEvent
  | PlayerJoinedEvent
  | PlayerLeftEvent
  | PlayerReadyEvent
  | GameStartedEvent
  | GameStateUpdateEvent
  | GameErrorEvent
  | ChatBroadcastEvent
  | RoundEndEvent
  | GameEndEvent;

// ─── Sanitized state (per-player view — hides other hands) ──

export interface SanitizedPlayer {
  id: string;
  name: string;
  handCount: number;
  melds: import('./meld').Meld[];
  totalScore: number;
  hasOpened: boolean;
  openingScore: number;
  isBot: boolean;
  isConnected: boolean;
}

export interface SanitizedGameState {
  id: string;
  phase: string;
  turnStep: string;
  currentPlayerIndex: number;
  players: SanitizedPlayer[];
  myHand: import('./card').Card[];
  drawPileCount: number;
  discardPile: import('./card').Card[];
  tableMelds: import('./meld').Meld[];
  round: number;
  turnCount: number;
  config: GameConfig;
}

