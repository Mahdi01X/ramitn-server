import { Injectable } from '@nestjs/common';
import { v4 as uuid } from 'uuid';
import { Room, RoomPlayer } from '@rami/shared';
import { DEFAULT_CONFIG, GameConfig } from '@rami/shared';

@Injectable()
export class RoomService {
  private rooms = new Map<string, Room>();
  private codeToId = new Map<string, string>();
  /** matchmaking queue: players waiting grouped by desired player count */
  private matchQueue = new Map<number, { playerId: string; playerName: string; socketId: string }[]>();

  createRoom(hostId: string, hostName: string, config: Partial<GameConfig>): Room {
    const id = uuid();
    const code = this.generateCode();

    const room: Room = {
      id,
      code,
      hostId,
      players: [{ id: hostId, name: hostName, ready: true }],  // Host is auto-ready
      config: { ...DEFAULT_CONFIG, ...config },
      isPrivate: true,
      gameId: null,
      createdAt: Date.now(),
    };

    this.rooms.set(id, room);
    this.codeToId.set(code, id);
    return room;
  }

  joinRoom(code: string, playerId: string, playerName: string): Room {
    const roomId = this.codeToId.get(code.toUpperCase());
    if (!roomId) throw new Error('Room not found');

    const room = this.rooms.get(roomId)!;
    if (room.players.length >= room.config.numPlayers) {
      throw new Error('Room is full');
    }
    if (room.gameId) throw new Error('Game already in progress');
    if (room.players.some(p => p.id === playerId)) {
      return room; // Already in room
    }

    room.players.push({ id: playerId, name: playerName, ready: false });
    return room;
  }

  leaveRoom(roomId: string, playerId: string): Room | null {
    const room = this.rooms.get(roomId);
    if (!room) return null;

    room.players = room.players.filter(p => p.id !== playerId);

    if (room.players.length === 0) {
      this.rooms.delete(roomId);
      this.codeToId.delete(room.code);
      return null;
    }

    // Transfer host if needed
    if (room.hostId === playerId) {
      room.hostId = room.players[0].id;
    }

    return room;
  }

  setReady(roomId: string, playerId: string): Room {
    const room = this.rooms.get(roomId)!;
    const player = room.players.find(p => p.id === playerId);
    if (player) player.ready = true;
    return room;
  }

  allReady(roomId: string): boolean {
    const room = this.rooms.get(roomId)!;
    // Host is always ready — only check non-host players
    return room.players.length >= 2 && room.players.every(p => p.id === room.hostId || p.ready);
  }

  getRoom(roomId: string): Room | undefined {
    return this.rooms.get(roomId);
  }

  getRoomByCode(code: string): Room | undefined {
    const id = this.codeToId.get(code.toUpperCase());
    return id ? this.rooms.get(id) : undefined;
  }

  findRoomByPlayer(playerId: string): Room | undefined {
    for (const room of this.rooms.values()) {
      if (room.players.some(p => p.id === playerId)) return room;
    }
    return undefined;
  }

  setGameId(roomId: string, gameId: string): void {
    const room = this.rooms.get(roomId);
    if (room) room.gameId = gameId;
  }

  /** Add player to matchmaking queue */
  joinMatchmaking(playerId: string, playerName: string, socketId: string, preferredPlayers: number): void {
    if (!this.matchQueue.has(preferredPlayers)) {
      this.matchQueue.set(preferredPlayers, []);
    }
    const queue = this.matchQueue.get(preferredPlayers)!;
    if (!queue.some(p => p.playerId === playerId)) {
      queue.push({ playerId, playerName, socketId });
    }
  }

  /** Check if matchmaking can form a room */
  tryMatchmaking(preferredPlayers: number): { players: { playerId: string; playerName: string; socketId: string }[]; room: Room } | null {
    const queue = this.matchQueue.get(preferredPlayers);
    if (!queue || queue.length < preferredPlayers) return null;

    const matched = queue.splice(0, preferredPlayers);
    const room = this.createRoom(matched[0].playerId, matched[0].playerName, { numPlayers: preferredPlayers });
    room.isPrivate = false;

    // Add other players
    for (let i = 1; i < matched.length; i++) {
      room.players.push({ id: matched[i].playerId, name: matched[i].playerName, ready: true });
    }
    // Host is also ready in matchmaking
    room.players[0].ready = true;

    return { players: matched, room };
  }

  private generateCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars[Math.floor(Math.random() * chars.length)];
    }
    // Ensure uniqueness
    if (this.codeToId.has(code)) return this.generateCode();
    return code;
  }
}

