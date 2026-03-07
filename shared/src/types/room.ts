export interface Room {
  id: string;
  code: string;
  hostId: string;
  players: RoomPlayer[];
  config: import('./game-config').GameConfig;
  isPrivate: boolean;
  gameId: string | null;
  createdAt: number;
}

export interface RoomPlayer {
  id: string;
  name: string;
  ready: boolean;
}

