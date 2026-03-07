import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { RoomService } from './room.service';
import { GameService } from './game.service';
import {
  GamePhase, GameAction, GameError,
} from '@rami/shared';

interface AuthSocket extends Socket {
  userId?: string;
  userName?: string;
}

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/game',
})
export class GameGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server!: Server;

  /** Map userId → socketId */
  private userSockets = new Map<string, string>();

  constructor(
    private jwtService: JwtService,
    private roomService: RoomService,
    private gameService: GameService,
  ) {}

  // ─── Connection ──────────────────────────────────────────

  async handleConnection(client: AuthSocket) {
    try {
      const token = client.handshake.auth?.token || client.handshake.headers?.authorization?.replace('Bearer ', '');
      if (!token) {
        client.emit('game_error', { code: 'AUTH', message: 'No token' });
        client.disconnect();
        return;
      }
      const payload = this.jwtService.verify(token);
      client.userId = payload.sub;
      client.userName = payload.name;
      this.userSockets.set(payload.sub, client.id);
      console.log(`✅ ${payload.name} connected (${client.id})`);
    } catch {
      client.emit('game_error', { code: 'AUTH', message: 'Invalid token' });
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthSocket) {
    if (client.userId) {
      this.userSockets.delete(client.userId);
      // Mark player as disconnected in room
      const room = this.roomService.findRoomByPlayer(client.userId);
      if (room) {
        this.server.to(room.id).emit('player_left', { playerId: client.userId });
      }
    }
  }

  // ─── Room Events ─────────────────────────────────────────

  @SubscribeMessage('create_room')
  handleCreateRoom(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { config?: any },
  ) {
    const room = this.roomService.createRoom(
      client.userId!, client.userName!, data.config || {},
    );
    client.join(room.id);
    client.emit('room_created', { roomCode: room.code, roomId: room.id });
    return { roomCode: room.code };
  }

  @SubscribeMessage('join_room')
  handleJoinRoom(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { roomCode: string },
  ) {
    try {
      const room = this.roomService.joinRoom(data.roomCode, client.userId!, client.userName!);
      client.join(room.id);

      // Notify all in room
      this.server.to(room.id).emit('player_joined', {
        playerId: client.userId,
        playerName: client.userName,
      });

      client.emit('room_joined', {
        roomCode: room.code,
        players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
      });
    } catch (err: any) {
      client.emit('game_error', { code: 'JOIN_ERROR', message: err.message });
    }
  }

  @SubscribeMessage('leave_room')
  handleLeaveRoom(@ConnectedSocket() client: AuthSocket) {
    const room = this.roomService.findRoomByPlayer(client.userId!);
    if (room) {
      this.roomService.leaveRoom(room.id, client.userId!);
      client.leave(room.id);
      this.server.to(room.id).emit('player_left', { playerId: client.userId });
    }
  }

  @SubscribeMessage('ready')
  handleReady(@ConnectedSocket() client: AuthSocket) {
    const room = this.roomService.findRoomByPlayer(client.userId!);
    if (!room) return;

    this.roomService.setReady(room.id, client.userId!);
    this.server.to(room.id).emit('player_ready', { playerId: client.userId });
  }

  @SubscribeMessage('start_game')
  handleStartGame(@ConnectedSocket() client: AuthSocket) {
    const room = this.roomService.findRoomByPlayer(client.userId!);
    if (!room) return;
    if (room.hostId !== client.userId) {
      client.emit('game_error', { code: 'NOT_HOST', message: 'Only host can start' });
      return;
    }
    if (!this.roomService.allReady(room.id)) {
      client.emit('game_error', { code: 'NOT_READY', message: 'Not all players ready' });
      return;
    }

    const playerInfos = room.players.map(p => ({ id: p.id, name: p.name, isBot: false }));
    const gameState = this.gameService.create(playerInfos, room.config);
    this.roomService.setGameId(room.id, gameState.id);

    // Start first round
    const state = this.gameService.startNewRound(gameState.id);

    this.server.to(room.id).emit('game_started', {});
    this.broadcastState(room.id, state.id);
  }

  // ─── Game Actions ────────────────────────────────────────

  @SubscribeMessage('game_action')
  handleGameAction(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { action: any },
  ) {
    const room = this.roomService.findRoomByPlayer(client.userId!);
    if (!room || !room.gameId) {
      client.emit('game_error', { code: 'NO_GAME', message: 'No active game' });
      return;
    }

    const action: GameAction = {
      ...data.action,
      playerId: client.userId!, // Server sets playerId (anti-cheat)
    };

    try {
      const state = this.gameService.performAction(room.gameId, action);

      // Broadcast updated state
      this.broadcastState(room.id, room.gameId);

      // Handle round end
      if (state.phase === GamePhase.RoundEnd) {
        const scores: Record<string, number> = {};
        const totalScores: Record<string, number> = {};
        state.players.forEach(p => {
          scores[p.id] = p.score;
          totalScores[p.id] = p.totalScore;
        });

        this.server.to(room.id).emit('round_end', {
          scores,
          totalScores,
          winnerId: state.winnerId,
          round: state.round,
        });

        // Auto-start next round after delay
        if (state.phase === GamePhase.RoundEnd) {
          setTimeout(() => {
            try {
              const newState = this.gameService.startNewRound(room.gameId!);
              this.broadcastState(room.id, room.gameId!);
            } catch {}
          }, 3000);
        }
      }

      // Handle game end
      if (state.phase === GamePhase.GameEnd) {
        const finalScores: Record<string, number> = {};
        state.players.forEach(p => { finalScores[p.id] = p.totalScore; });

        this.server.to(room.id).emit('game_end', {
          finalScores,
          winnerId: state.winnerId,
        });
      }
    } catch (err: any) {
      const code = err instanceof GameError ? err.code : 'ACTION_ERROR';
      client.emit('game_error', { code, message: err.message });
    }
  }

  // ─── Chat ────────────────────────────────────────────────

  @SubscribeMessage('chat_message')
  handleChat(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { message: string },
  ) {
    const room = this.roomService.findRoomByPlayer(client.userId!);
    if (!room) return;

    this.server.to(room.id).emit('chat_broadcast', {
      senderId: client.userId,
      senderName: client.userName,
      message: data.message.slice(0, 200), // limit length
      timestamp: Date.now(),
    });
  }

  // ─── Matchmaking ─────────────────────────────────────────

  @SubscribeMessage('join_matchmaking')
  handleMatchmaking(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { preferredPlayers: number },
  ) {
    const n = Math.min(Math.max(data.preferredPlayers || 2, 2), 4);
    this.roomService.joinMatchmaking(client.userId!, client.userName!, client.id, n);

    const match = this.roomService.tryMatchmaking(n);
    if (match) {
      // All matched players join the room
      for (const p of match.players) {
        const socket = this.server.sockets.sockets.get(p.socketId);
        if (socket) {
          socket.join(match.room.id);
          socket.emit('room_joined', {
            roomCode: match.room.code,
            players: match.room.players.map(rp => ({ id: rp.id, name: rp.name, ready: rp.ready })),
          });
        }
      }

      // Auto-start
      const playerInfos = match.room.players.map(p => ({ id: p.id, name: p.name, isBot: false }));
      const gameState = this.gameService.create(playerInfos, match.room.config);
      this.roomService.setGameId(match.room.id, gameState.id);
      const state = this.gameService.startNewRound(gameState.id);

      this.server.to(match.room.id).emit('game_started', {});
      this.broadcastState(match.room.id, state.id);
    } else {
      client.emit('matchmaking_waiting', { position: 0 });
    }
  }

  // ─── Resign ──────────────────────────────────────────────

  @SubscribeMessage('resign')
  handleResign(@ConnectedSocket() client: AuthSocket) {
    const room = this.roomService.findRoomByPlayer(client.userId!);
    if (!room || !room.gameId) return;

    this.server.to(room.id).emit('player_left', { playerId: client.userId });
    this.roomService.leaveRoom(room.id, client.userId!);
    client.leave(room.id);
  }

  // ─── Helpers ─────────────────────────────────────────────

  private broadcastState(roomId: string, gameId: string) {
    const room = this.roomService.getRoom(roomId);
    if (!room) return;

    for (const player of room.players) {
      const socketId = this.userSockets.get(player.id);
      if (socketId) {
        const sanitized = this.gameService.getSanitizedState(gameId, player.id);
        this.server.to(socketId).emit('game_state_update', { state: sanitized });
      }
    }
  }
}


