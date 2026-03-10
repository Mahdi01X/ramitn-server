// ─── Simple Rami Tunisien Server with Game Engine ─────────────
// Socket.IO rooms with codes + full game logic on server.
// Run: npm install && node server.js

const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'], credentials: true },
  allowEIO3: true,
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
  for (let i = 0; i < 5; i++) code += chars[Math.floor(Math.random() * chars.length)];
  if (codeToRoom.has(code)) return generateCode();
  return code;
}
function generateId() {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
}

// ─── Card / Deck Engine ──────────────────────────────────────

const SUITS = ['hearts', 'diamonds', 'clubs', 'spades'];
const RANKS = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

function rankValue(rank) {
  if (rank === 'A') return 1;
  if (rank === 'J' || rank === 'Q' || rank === 'K') return 10;
  return parseInt(rank);
}

function rankIndex(rank) {
  return RANKS.indexOf(rank);
}

function createDeck(numJokers = 4) {
  let id = 1;
  const cards = [];
  // 2 standard decks
  for (let d = 0; d < 2; d++) {
    for (const suit of SUITS) {
      for (const rank of RANKS) {
        cards.push({ id: id++, suit, rank, isJoker: false });
      }
    }
  }
  // Jokers
  for (let j = 0; j < numJokers; j++) {
    cards.push({ id: id++, suit: 'joker', rank: 'JOKER', isJoker: true });
  }
  return cards;
}

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// ─── Meld Validation ─────────────────────────────────────────

function isValidSet(cards) {
  if (cards.length < 3 || cards.length > 4) return false;
  const nonJokers = cards.filter(c => !c.isJoker);
  if (nonJokers.length === 0) return false;
  const rank = nonJokers[0].rank;
  if (!nonJokers.every(c => c.rank === rank)) return false;
  // No duplicate suits among non-jokers
  const suits = nonJokers.map(c => c.suit);
  if (new Set(suits).size !== suits.length) return false;
  return true;
}

function isValidRun(cards) {
  if (cards.length < 3) return false;
  const nonJokers = cards.filter(c => !c.isJoker);
  if (nonJokers.length === 0) return false;
  // All same suit
  const suit = nonJokers[0].suit;
  if (!nonJokers.every(c => c.suit === suit)) return false;
  // Sort by rank index
  const sorted = [...cards].sort((a, b) => {
    if (a.isJoker) return 1;
    if (b.isJoker) return -1;
    return rankIndex(a.rank) - rankIndex(b.rank);
  });
  // Fill in with jokers and check consecutive
  let jokerCount = cards.filter(c => c.isJoker).length;
  const positions = [];
  for (const c of sorted) {
    if (!c.isJoker) positions.push(rankIndex(c.rank));
  }
  positions.sort((a, b) => a - b);
  // Check gaps
  for (let i = 1; i < positions.length; i++) {
    const gap = positions[i] - positions[i - 1] - 1;
    if (gap < 0) return false; // duplicate rank
    jokerCount -= gap;
    if (jokerCount < 0) return false;
  }
  return true;
}

function isValidMeld(cards) {
  return isValidSet(cards) || isValidRun(cards);
}

function getMeldType(cards) {
  if (isValidSet(cards)) return 'set';
  if (isValidRun(cards)) return 'run';
  return null;
}

function containsJoker(cards) {
  return cards.some(c => c.isJoker);
}

function calculateMeldPoints(cards) {
  let pts = 0;
  // For a run, joker takes the value of the card it replaces
  const type = getMeldType(cards);
  if (type === 'run') {
    const nonJokers = cards.filter(c => !c.isJoker).sort((a, b) => rankIndex(a.rank) - rankIndex(b.rank));
    // Find all positions
    const minIdx = rankIndex(nonJokers[0].rank);
    for (let i = 0; i < cards.length; i++) {
      const rIdx = minIdx + i;
      if (rIdx < RANKS.length) {
        pts += rankValue(RANKS[rIdx]);
      }
    }
  } else {
    // Set: all cards have same rank
    const nonJokers = cards.filter(c => !c.isJoker);
    const val = rankValue(nonJokers[0].rank);
    pts = val * cards.length;
  }
  return pts;
}

function calculateHandPenalty(hand) {
  let total = 0;
  for (const c of hand) {
    if (c.isJoker) { total += 30; continue; }
    if (c.rank === 'A') { total += 11; continue; }
    total += rankValue(c.rank);
  }
  return total;
}

// ─── Game State Manager ──────────────────────────────────────

function createGameState(roomPlayers) {
  const deck = shuffle(createDeck(4));
  const players = roomPlayers.map(p => ({
    id: p.id,
    name: p.name,
    socketId: p.socketId,
    hand: [],
    hasOpened: false,
    openingScore: 0,
    totalScore: 0,
    drewFromDiscard: false,
  }));

  // Deal: 14 cards each, first player gets 15
  for (let i = 0; i < 14; i++) {
    for (const p of players) {
      p.hand.push(deck.pop());
    }
  }
  players[0].hand.push(deck.pop()); // dealer (first) gets 15

  // Discard pile starts empty (first player must discard to start)
  const discardPile = [];
  const drawPile = deck;

  return {
    players,
    drawPile,
    discardPile,
    tableMelds: [],
    currentPlayerIndex: 0,
    // First player has 15 cards → must DISCARD first (turnStep = 'play')
    turnStep: 'play',
    round: 1,
    turnCount: 0,
    phase: 'playing',
  };
}

function getPlayerView(game, playerIdx) {
  const p = game.players[playerIdx];
  return {
    state: {
      id: `game_${Date.now()}`,
      phase: game.phase,
      turnStep: game.turnStep,
      currentPlayerIndex: game.currentPlayerIndex,
      players: game.players.map((pl, i) => ({
        id: pl.id,
        name: pl.name,
        handCount: pl.hand.length,
        melds: [],
        totalScore: pl.totalScore,
        hasOpened: pl.hasOpened,
        openingScore: pl.openingScore || 0,
        isBot: false,
        isConnected: true,
      })),
      myHand: p.hand,
      drawPileCount: game.drawPile.length,
      discardPile: game.discardPile.slice(-5), // last 5 cards
      tableMelds: game.tableMelds,
      round: game.round,
      turnCount: game.turnCount,
      config: { openingThreshold: 71, numJokers: 4, maxRounds: 5 },
    },
  };
}

function broadcastState(gameNs, roomId, game) {
  for (let i = 0; i < game.players.length; i++) {
    const p = game.players[i];
    const view = getPlayerView(game, i);
    // Find socket by socketId
    const sock = gameNs.sockets.get(p.socketId);
    if (sock) {
      sock.emit('game_state_update', view);
    }
  }
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
app.get('/health', (req, res) => res.status(200).send('OK'));

// ─── Socket.IO namespace: /game ───────────────────────────────

const gameNs = io.of('/game');

gameNs.on('connection', (socket) => {
  let playerId = null;
  let playerName = null;

  console.log(`🔌 Socket connected: ${socket.id}`);

  // ─── Register ──────────────────────────────────────────

  socket.on('register', (data, ack) => {
    playerName = (data.name || 'Joueur').slice(0, 20);
    playerId = data.playerId || `p_${generateId()}`;
    socket.playerId = playerId;
    socket.playerName = playerName;
    console.log(`✅ Registered: ${playerName} (${playerId})`);
    if (typeof ack === 'function') ack({ playerId, playerName });
    socket.emit('registered', { playerId, playerName });
  });

  // ─── Create Room ───────────────────────────────────────

  socket.on('create_room', (data) => {
    if (!playerId) { socket.emit('game_error', { message: 'Register first' }); return; }
    const numPlayers = Math.min(Math.max(data?.numPlayers || 2, 2), 4);
    const code = generateCode();
    const roomId = `room_${generateId()}`;

    const room = {
      id: roomId, code, hostId: playerId, numPlayers,
      players: [{ id: playerId, name: playerName, socketId: socket.id, ready: true }],
      gameStarted: false, game: null, createdAt: Date.now(),
    };

    rooms.set(roomId, room);
    codeToRoom.set(code, roomId);
    playerToRoom.set(playerId, roomId);
    socket.join(roomId);

    console.log(`🏠 Room created: ${code} by ${playerName}`);
    socket.emit('room_created', {
      roomCode: code, roomId, numPlayers,
      players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
    });
  });

  // ─── Join Room ─────────────────────────────────────────

  socket.on('join_room', (data) => {
    if (!playerId) { socket.emit('game_error', { message: 'Register first' }); return; }
    const code = (data?.roomCode || '').toUpperCase().trim();
    const roomId = codeToRoom.get(code);

    if (!roomId || !rooms.has(roomId)) {
      socket.emit('game_error', { code: 'NOT_FOUND', message: `Aucune partie trouvée avec le code "${code}"` });
      return;
    }
    const room = rooms.get(roomId);
    if (room.gameStarted) { socket.emit('game_error', { message: 'La partie a déjà commencé' }); return; }
    if (room.players.length >= room.numPlayers) { socket.emit('game_error', { message: 'La salle est pleine' }); return; }

    if (room.players.some(p => p.id === playerId)) {
      socket.emit('room_joined', {
        roomCode: room.code, roomId: room.id, numPlayers: room.numPlayers,
        players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
      });
      return;
    }

    room.players.push({ id: playerId, name: playerName, socketId: socket.id, ready: false });
    playerToRoom.set(playerId, roomId);
    socket.join(roomId);

    console.log(`👋 ${playerName} joined room ${code} (${room.players.length}/${room.numPlayers})`);

    gameNs.to(roomId).emit('player_joined', {
      playerId, playerName,
      players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
    });
    socket.emit('room_joined', {
      roomCode: room.code, roomId: room.id, numPlayers: room.numPlayers,
      players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
    });
  });

  // ─── Ready Toggle ──────────────────────────────────────

  socket.on('ready', () => {
    if (!playerId) return;
    const roomId = playerToRoom.get(playerId);
    if (!roomId) return;
    const room = rooms.get(roomId);
    if (!room) return;
    // Host is always ready — don't toggle
    if (playerId === room.hostId) return;
    const player = room.players.find(p => p.id === playerId);
    if (player) {
      player.ready = !player.ready;
      gameNs.to(roomId).emit('player_ready', {
        playerId, ready: player.ready,
        players: room.players.map(p => ({ id: p.id, name: p.name, ready: p.ready })),
      });
    }
  });

  // ─── Start Game (host only) ────────────────────────────

  socket.on('start_game', () => {
    if (!playerId) return;
    const roomId = playerToRoom.get(playerId);
    if (!roomId) return;
    const room = rooms.get(roomId);
    if (!room) return;
    if (room.hostId !== playerId) { socket.emit('game_error', { message: 'Seul l\'hôte peut démarrer' }); return; }
    if (room.players.length < 2) { socket.emit('game_error', { message: 'Il faut au moins 2 joueurs' }); return; }
    // Auto-mark host as ready (host is always considered ready)
    const hostPlayer = room.players.find(p => p.id === room.hostId);
    if (hostPlayer) hostPlayer.ready = true;
    // Only check non-host players
    const allNonHostReady = room.players.every(p => p.id === room.hostId || p.ready);
    if (!allNonHostReady) { socket.emit('game_error', { message: 'Tous les joueurs ne sont pas prêts' }); return; }

    // Create game state
    room.gameStarted = true;
    room.game = createGameState(room.players);

    console.log(`🎮 Game started in room ${room.code} with ${room.players.length} players`);

    // Notify all players
    gameNs.to(roomId).emit('game_started', {
      players: room.players.map(p => ({ id: p.id, name: p.name })),
    });

    // Send initial game state to each player (each sees only their own hand)
    broadcastState(gameNs, roomId, room.game);
  });

  // ─── Game Actions ──────────────────────────────────────

  socket.on('game_action', (data) => {
    if (!playerId) return;
    const roomId = playerToRoom.get(playerId);
    if (!roomId) return;
    const room = rooms.get(roomId);
    if (!room || !room.game) return;

    const game = room.game;
    const action = data?.action;
    if (!action) return;

    const currentPlayer = game.players[game.currentPlayerIndex];
    if (currentPlayer.id !== playerId) {
      socket.emit('game_error', { message: 'Ce n\'est pas ton tour' });
      return;
    }

    try {
      switch (action.type) {
        case 'draw_deck': {
          if (game.turnStep !== 'draw') throw new Error('Tu dois d\'abord piocher');
          // Reshuffle discard pile if draw pile is empty
          if (game.drawPile.length === 0) {
            if (game.discardPile.length <= 1) throw new Error('Plus de cartes disponibles');
            const topDiscard = game.discardPile.pop();
            // Shuffle remaining discard pile into draw pile
            game.drawPile = game.discardPile.sort(() => Math.random() - 0.5);
            game.discardPile = [topDiscard];
            console.log(`🔄 Reshuffle: ${game.drawPile.length} cards back in draw pile`);
          }
          const card = game.drawPile.pop();
          currentPlayer.hand.push(card);
          currentPlayer.drewFromDiscard = false;
          game.turnStep = 'play';
          break;
        }

        case 'draw_discard': {
          if (game.turnStep !== 'draw') throw new Error('Tu dois d\'abord piocher');
          if (game.discardPile.length === 0) throw new Error('Le talon est vide');
          const card = game.discardPile.pop();
          currentPlayer.hand.push(card);
          currentPlayer.drewFromDiscard = true;
          game.turnStep = 'play';
          break;
        }

        case 'meld': {
          if (game.turnStep !== 'play') throw new Error('Tu dois piocher d\'abord');
          const cardIds = action.cardIds || [];
          const cards = cardIds.map(id => currentPlayer.hand.find(c => c.id === id)).filter(Boolean);
          if (cards.length < 3) throw new Error('Il faut au moins 3 cartes');
          if (!isValidMeld(cards)) throw new Error('Combinaison invalide');

          const meldType = getMeldType(cards);
          const meldPts = calculateMeldPoints(cards);

          if (!currentPlayer.hasOpened) {
            // Track staged melds for opening
            if (!currentPlayer._stagedMelds) currentPlayer._stagedMelds = [];
            currentPlayer._stagedMelds.push({ cards, type: meldType, points: meldPts, hasJoker: containsJoker(cards) });
            // Don't remove from hand yet — wait for confirm_opening
            socket.emit('meld_staged', {
              meldType, points: meldPts,
              stagedTotal: currentPlayer._stagedMelds.reduce((s, m) => s + m.points, 0),
              hasCleanRun: currentPlayer._stagedMelds.some(m => m.type === 'run' && !m.hasJoker),
            });
            return; // Don't broadcast state yet
          }

          // Already opened — place meld directly
          for (const c of cards) {
            currentPlayer.hand = currentPlayer.hand.filter(h => h.id !== c.id);
          }
          game.tableMelds.push({
            id: `meld_${generateId()}`,
            type: meldType,
            cards,
            ownerId: playerId,
          });
          break;
        }

        case 'confirm_opening': {
          if (currentPlayer.hasOpened) throw new Error('Tu as déjà ouvert');
          const staged = currentPlayer._stagedMelds || [];
          if (staged.length === 0) throw new Error('Aucun paquet posé');
          const total = staged.reduce((s, m) => s + m.points, 0);
          const hasCleanRun = staged.some(m => m.type === 'run' && !m.hasJoker);
          if (total < 71) throw new Error(`Il faut au moins 71 points (tu as ${total})`);
          if (!hasCleanRun) throw new Error('Il faut au moins une suite sans joker');

          // Commit all staged melds
          for (const meld of staged) {
            for (const c of meld.cards) {
              currentPlayer.hand = currentPlayer.hand.filter(h => h.id !== c.id);
            }
            game.tableMelds.push({
              id: `meld_${generateId()}`,
              type: meld.type,
              cards: meld.cards,
              ownerId: playerId,
            });
          }
          currentPlayer.hasOpened = true;
          currentPlayer.openingScore = total;
          currentPlayer._stagedMelds = [];
          break;
        }

        case 'cancel_staging': {
          currentPlayer._stagedMelds = [];
          socket.emit('staging_cancelled');
          return;
        }

        case 'layoff': {
          if (game.turnStep !== 'play') throw new Error('Tu dois piocher d\'abord');
          if (!currentPlayer.hasOpened) throw new Error('Tu dois d\'abord ouvrir');
          const cardId = action.cardId;
          const meldId = action.meldId;
          const card = currentPlayer.hand.find(c => c.id === cardId);
          const meld = game.tableMelds.find(m => m.id === meldId);
          if (!card || !meld) throw new Error('Carte ou paquet invalide');

          // Try adding card at end
          let addedEnd = isValidMeld([...meld.cards, card]);
          let addedStart = !addedEnd && isValidMeld([card, ...meld.cards]);
          if (meld.type === 'set' && meld.cards.length >= 4) {
            addedEnd = false; addedStart = false;
          }

          // Check joker swap: if card replaces a joker in the meld
          let jokerSwapped = null;
          if (!addedEnd && !addedStart && !card.isJoker) {
            for (let ji = 0; ji < meld.cards.length; ji++) {
              if (meld.cards[ji].isJoker) {
                const testCards = [...meld.cards];
                testCards[ji] = card;
                if (isValidMeld(testCards)) {
                  jokerSwapped = meld.cards[ji];
                  meld.cards[ji] = card;
                  currentPlayer.hand = currentPlayer.hand.filter(h => h.id !== cardId);
                  currentPlayer.hand.push(jokerSwapped);
                  break;
                }
              }
            }
          }

          if (jokerSwapped) break; // Joker was swapped

          if (!addedEnd && !addedStart) throw new Error('Cette carte ne peut pas être ajoutée à ce paquet');

          if (addedEnd) {
            meld.cards.push(card);
          } else {
            meld.cards.unshift(card);
          }
          currentPlayer.hand = currentPlayer.hand.filter(h => h.id !== cardId);
          break;
        }

        case 'discard': {
          if (game.turnStep !== 'play') throw new Error('Tu dois piocher d\'abord');
          const cardId = action.cardId;
          const card = currentPlayer.hand.find(c => c.id === cardId);
          if (!card) throw new Error('Carte introuvable');

          currentPlayer.hand = currentPlayer.hand.filter(h => h.id !== cardId);
          game.discardPile.push(card);

          // Penalty: drew from discard but didn't open → 100 pts
          if (currentPlayer.drewFromDiscard && !currentPlayer.hasOpened) {
            currentPlayer.totalScore += 100;
            console.log(`⚠️ ${currentPlayer.name} gets 100pts penalty (drew from discard without opening)`);
          }

          // Check win condition
          if (currentPlayer.hand.length === 0) {
            game.phase = 'round_end';
            // Calculate penalties
            const roundResults = game.players.map(p => ({
              id: p.id,
              name: p.name,
              penalty: p.id === playerId ? 0 : calculateHandPenalty(p.hand),
              cardsLeft: p.hand.length,
            }));
            for (const r of roundResults) {
              const p = game.players.find(pl => pl.id === r.id);
              if (p) p.totalScore += r.penalty;
            }
            gameNs.to(roomId).emit('round_end', {
              winnerId: playerId,
              winnerName: currentPlayer.name,
              results: roundResults,
              scores: game.players.map(p => ({ id: p.id, name: p.name, totalScore: p.totalScore })),
            });
            broadcastState(gameNs, roomId, game);
            return;
          }

          // Next player's turn
          game.currentPlayerIndex = (game.currentPlayerIndex + 1) % game.players.length;
          game.turnStep = 'draw';
          game.turnCount++;
          currentPlayer.drewFromDiscard = false;
          break;
        }

        default:
          throw new Error(`Action inconnue: ${action.type}`);
      }

      // Broadcast updated state to all players
      broadcastState(gameNs, roomId, game);

    } catch (err) {
      socket.emit('game_error', { message: err.message });
    }
  });

  // ─── Chat ──────────────────────────────────────────────

  socket.on('chat_message', (data) => {
    if (!playerId) return;
    const roomId = playerToRoom.get(playerId);
    if (!roomId) return;
    gameNs.to(roomId).emit('chat_broadcast', {
      senderId: playerId, senderName: playerName,
      message: (data?.message || '').slice(0, 200), timestamp: Date.now(),
    });
  });

  // ─── Disconnect ────────────────────────────────────────

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

      // If game is in progress and only 1 player remains, declare them winner
      if (room.game && room.players.length === 1) {
        const winner = room.players[0];
        console.log(`🏆 Only 1 player left in room ${room.code}, ${winner.name} wins by forfeit`);
        gameNs.to(roomId).emit('game_over_forfeit', {
          winnerId: winner.id,
          winnerName: winner.name,
          reason: 'L\'adversaire a quitté la partie',
        });
        // Clean up game
        room.game = null;
      }

      if (room.players.length === 0) {
        rooms.delete(roomId);
        codeToRoom.delete(room.code);
        console.log(`🗑️ Room ${room.code} deleted (empty)`);
      } else if (room.hostId === playerId) {
        room.hostId = room.players[0].id;
      }
    }
    playerToRoom.delete(playerId);
  });
});

// ─── Start ────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🃏 RamiTN Server v2.0 (with Game Engine)`);
  console.log(`   Running on port ${PORT}`);
  console.log(`   http://localhost:${PORT}\n`);
});

