// ─── Simple Rami Tunisien Lobby Server ────────────────────────
// No JWT, no DB. Just Socket.IO rooms with codes.
// Run: npm install && node server.js

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
    credentials: true,
  },
  allowEIO3: true, // compatibility
  transports: ['websocket', 'polling'],
  pingTimeout: 60000,
  pingInterval: 25000,
});

// ─── In-memory state ──────────────────────────────────────────

const rooms = new Map();       // roomId → Room
const codeToRoom = new Map();  // code → roomId
const playerToRoom = new Map();// playerId → roomId

function generateCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 5; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  if (codeToRoom.has(code)) return generateCode();
  return code;
}

function generateId() {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
}

// ─── Health check ─────────────────────────────────────────────

app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'RamiTN Server',
    rooms: rooms.size,
    players: playerToRoom.size,
    uptime: Math.floor(process.uptime()),
  });
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// ─── Socket.IO namespace: /game ───────────────────────────────

const gameNs = io.of('/game');

gameNs.on('connection', (socket) => {
  // Each socket has: socket.playerId, socket.playerName
  let playerId = null;
  let playerName = null;

  console.log(`🔌 Socket connected: ${socket.id}`);

  // ─── Register (no auth — just a pseudo) ──────────────────

  socket.on('register', (data, ack) => {
    playerName = (data.name || 'Joueur').slice(0, 20);
    playerId = data.playerId || `p_${generateId()}`;
    socket.playerId = playerId;
    socket.playerName = playerName;
    console.log(`✅ Registered: ${playerName} (${playerId})`);
    if (typeof ack === 'function') {
      ack({ playerId, playerName });
    }
    socket.emit('registered', { playerId, playerName });
  });

  // ─── Create Room ─────────────────────────────────────────

  socket.on('create_room', (data) => {
    if (!playerId) {
      socket.emit('game_error', { code: 'NOT_REGISTERED', message: 'Register first' });
      return;
    }

    const numPlayers = Math.min(Math.max(data?.numPlayers || 2, 2), 4);
    const code = generateCode();
    const roomId = `room_${generateId()}`;

    const room = {
      id: roomId,
      code,
      hostId: playerId,
      numPlayers,
      players: [{
        id: playerId,
        name: playerName,
        socketId: socket.id,
        ready: false,
      }],
      gameStarted: false,
      createdAt: Date.now(),
    };

    rooms.set(roomId, room);
    codeToRoom.set(code, roomId);
    playerToRoom.set(playerId, roomId);

    socket.join(roomId);

    console.log(`🏠 Room created: ${code} by ${playerName}`);

    socket.emit('room_created', {
      roomCode: code,
      roomId,
      players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
    });
  });

  // ─── Join Room ───────────────────────────────────────────

  socket.on('join_room', (data) => {
    if (!playerId) {
      socket.emit('game_error', { code: 'NOT_REGISTERED', message: 'Register first' });
      return;
    }

    const code = (data?.roomCode || '').toUpperCase().trim();
    const roomId = codeToRoom.get(code);

    if (!roomId || !rooms.has(roomId)) {
      socket.emit('game_error', { code: 'NOT_FOUND', message: `Aucune partie trouvée avec le code "${code}"` });
      return;
    }

    const room = rooms.get(roomId);

    if (room.gameStarted) {
      socket.emit('game_error', { code: 'STARTED', message: 'La partie a déjà commencé' });
      return;
    }

    if (room.players.length >= room.numPlayers) {
      socket.emit('game_error', { code: 'FULL', message: 'La salle est pleine' });
      return;
    }

    // Already in room?
    if (room.players.some(p => p.id === playerId)) {
      socket.emit('room_joined', {
        roomCode: room.code,
        roomId: room.id,
        players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
      });
      return;
    }

    room.players.push({
      id: playerId,
      name: playerName,
      socketId: socket.id,
      ready: false,
    });
    playerToRoom.set(playerId, roomId);

    socket.join(roomId);

    console.log(`👋 ${playerName} joined room ${code} (${room.players.length}/${room.numPlayers})`);

    // Notify everyone in room
    gameNs.to(roomId).emit('player_joined', {
      playerId,
      playerName,
      players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
    });

    // Confirm to joiner
    socket.emit('room_joined', {
      roomCode: room.code,
      roomId: room.id,
      players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
    });
  });

  // ─── Ready Toggle ────────────────────────────────────────

  socket.on('ready', () => {
    if (!playerId) return;
    const roomId = playerToRoom.get(playerId);
    if (!roomId) return;
    const room = rooms.get(roomId);
    if (!room) return;

    const player = room.players.find(p => p.id === playerId);
    if (player) {
      player.ready = !player.ready;
      gameNs.to(roomId).emit('player_ready', {
        playerId,
        ready: player.ready,
        players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
      });
    }
  });

  // ─── Start Game (host only) ──────────────────────────────

  socket.on('start_game', () => {
    if (!playerId) return;
    const roomId = playerToRoom.get(playerId);
    if (!roomId) return;
    const room = rooms.get(roomId);
    if (!room) return;

    if (room.hostId !== playerId) {
      socket.emit('game_error', { code: 'NOT_HOST', message: 'Seul l\'hôte peut démarrer' });
      return;
    }

    if (room.players.length < 2) {
      socket.emit('game_error', { code: 'NOT_ENOUGH', message: 'Il faut au moins 2 joueurs' });
      return;
    }

    if (!room.players.every(p => p.ready)) {
      socket.emit('game_error', { code: 'NOT_READY', message: 'Tous les joueurs ne sont pas prêts' });
      return;
    }

    room.gameStarted = true;
    console.log(`🎮 Game started in room ${room.code} with ${room.players.length} players`);

    gameNs.to(roomId).emit('game_started', {
      players: room.players.map(p => ({ id: p.id, name: p.name })),
    });
  });

  // ─── Chat ────────────────────────────────────────────────

  socket.on('chat_message', (data) => {
    if (!playerId) return;
    const roomId = playerToRoom.get(playerId);
    if (!roomId) return;

    gameNs.to(roomId).emit('chat_broadcast', {
      senderId: playerId,
      senderName: playerName,
      message: (data?.message || '').slice(0, 200),
      timestamp: Date.now(),
    });
  });

  // ─── Disconnect ──────────────────────────────────────────

  socket.on('disconnect', () => {
    console.log(`🔌 Disconnected: ${playerName || socket.id}`);
    if (!playerId) return;

    const roomId = playerToRoom.get(playerId);
    if (roomId && rooms.has(roomId)) {
      const room = rooms.get(roomId);
      room.players = room.players.filter(p => p.id !== playerId);

      gameNs.to(roomId).emit('player_left', {
        playerId,
        players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
      });

      // If room is empty, delete it
      if (room.players.length === 0) {
        rooms.delete(roomId);
        codeToRoom.delete(room.code);
        console.log(`🗑️ Room ${room.code} deleted (empty)`);
      } else if (room.hostId === playerId) {
        // Transfer host
        room.hostId = room.players[0].id;
      }
    }

    playerToRoom.delete(playerId);
  });
});

// ─── Start ────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🃏 Rami Tunisien Lobby Server`);
  console.log(`   Running on port ${PORT}`);
  console.log(`   http://localhost:${PORT}\n`);
});



