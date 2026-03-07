# 🏗️ Architecture — Rami Tunisien

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                       MONOREPO                                  │
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌────────────────────┐        │
│  │  shared/  │───>│  server/  │    │     mobile/        │        │
│  │  (TS)    │    │  (NestJS) │    │     (Flutter)      │        │
│  │          │    │           │    │                    │        │
│  │ • Types  │    │ • Auth    │    │ • Screens          │        │
│  │ • Engine │    │ • WS GW   │    │ • Engine (Dart)    │        │
│  │ • Bot AI │    │ • Rooms   │    │ • Providers        │        │
│  │ • Tests  │    │ • Games   │    │ • Services         │        │
│  └──────────┘    └────┬──────┘    └─────────┬──────────┘        │
│                       │                     │                   │
│               ┌───────▼───────┐    ┌────────▼────────┐          │
│               │  PostgreSQL   │    │  Socket.IO       │          │
│               │  Redis        │    │  REST (Auth)     │          │
│               └───────────────┘    └─────────────────┘          │
└─────────────────────────────────────────────────────────────────┘
```

## Principes clés

### 1. Source de vérité unique
- **Online** : le serveur (NestJS) est la seule source de vérité
- **Offline** : le moteur local Dart est la source de vérité
- Le client ne peut jamais imposer un état → anti-triche

### 2. Moteur de jeu partagé
Le moteur de jeu est implémenté deux fois :
- `shared/src/engine/` (TypeScript) → utilisé par le serveur
- `mobile/lib/engine/` (Dart) → utilisé pour le mode offline

Les deux implémentations suivent la même logique : fonctions pures, mêmes règles, mêmes validations.

### 3. State Management
- **Flutter** : Riverpod (StateNotifier)
  - `AuthProvider` : auth state (login, register, guest)
  - `GameProvider` : game state (offline engine + online state)
  - `RoomProvider` : lobby/room state (players, ready, chat)

### 4. Communication réseau
```
Client (Flutter)  ←→  Socket.IO  ←→  Server (NestJS)
                  ←→  REST/HTTP  ←→  Auth endpoints
```

## Flux de données

### Mode Offline (Hot-seat)
```
User Action → GameProvider → OfflineGameEngine → State Update → UI Rebuild
                                    ↓
                            Bot AI (auto-play)
```

### Mode Online
```
User Action → GameProvider → Socket.emit() → Server
                                               ↓
                                          GameService.performAction()
                                               ↓
                                          sanitizeStateForPlayer()
                                               ↓
Server → Socket.emit('game_state_update') → GameProvider → UI Rebuild
```

## Structure des dossiers détaillée

### `/shared` (source de vérité des règles)
```
src/
├── types/
│   ├── card.ts          # Card, Rank, Suit
│   ├── meld.ts          # Meld, MeldType
│   ├── player.ts        # Player
│   ├── game-config.ts   # GameConfig + DEFAULT_CONFIG
│   ├── game-state.ts    # GameState, TurnStep, GamePhase, GameAction, GameError
│   ├── events.ts        # WebSocket event types
│   └── room.ts          # Room, RoomPlayer
├── engine/
│   ├── deck.ts          # createDeck, shuffleDeck, deal
│   ├── meld-validator.ts # isValidRun, isValidSet, validateMeld, canLayoff, getCardPoints
│   ├── opening.ts       # canOpen (threshold check)
│   ├── scoring.ts       # calculateHandPenalty, calculateRoundScores, findGameWinner
│   ├── turn.ts          # drawFromDeck, drawFromDiscard, meld, layoff, discard
│   ├── game-machine.ts  # createGame, startRound, applyAction, sanitizeStateForPlayer
│   └── bot-ai.ts        # computeBotMove (greedy strategy)
├── __tests__/
│   ├── deck.test.ts
│   ├── meld-validator.test.ts
│   ├── scoring.test.ts
│   ├── game-machine.test.ts
│   └── bot-ai.test.ts
└── index.ts             # Re-exports everything
```

### `/server` (NestJS backend)
```
src/
├── main.ts              # Bootstrap NestJS
├── app.module.ts        # Root module
├── auth/
│   ├── auth.module.ts   # Auth module config (JWT, TypeORM)
│   ├── auth.service.ts  # register, login, guestLogin, validateUser
│   ├── auth.controller.ts # POST /auth/register, /auth/login, /auth/guest
│   ├── jwt.strategy.ts  # Passport JWT strategy
│   └── user.entity.ts   # TypeORM User entity
└── game/
    ├── game.module.ts   # Game module config
    ├── game.gateway.ts  # WebSocket gateway (all WS events)
    ├── game.service.ts  # Game state management (wraps shared engine)
    ├── room.service.ts  # Room management + matchmaking
    ├── game.service.spec.ts  # Tests
    └── room.service.spec.ts  # Tests
```

### `/mobile` (Flutter app)
```
lib/
├── main.dart            # App entry point (ProviderScope)
├── app/
│   └── router.dart      # GoRouter routes
├── core/
│   ├── theme.dart       # Material theme (green card table aesthetic)
│   └── constants.dart   # API URL, WS URL
├── models/
│   ├── card.dart        # Card, Rank, Suit (mirrors TS types)
│   ├── meld.dart        # Meld, MeldType
│   ├── game_config.dart # GameConfig (mirrors TS)
│   └── game_state.dart  # GameState (online mode state)
├── engine/
│   ├── deck.dart        # createDeck, shuffleDeck, deal
│   ├── meld_validator.dart # Validation functions (mirrors TS)
│   └── game_engine.dart # OfflineGameEngine (full offline play)
├── providers/
│   ├── auth_provider.dart  # AuthNotifier (login, register, guest)
│   ├── game_provider.dart  # GameNotifier (offline + online play)
│   └── room_provider.dart  # RoomNotifier (lobby, chat)
├── services/
│   ├── auth_service.dart   # Dio HTTP client for auth
│   └── socket_service.dart # Socket.IO wrapper
├── screens/
│   ├── home/home_screen.dart         # Main menu
│   ├── auth/login_screen.dart        # Login/Register
│   ├── offline/offline_setup_screen.dart # Offline game setup
│   ├── lobby/
│   │   ├── create_room_screen.dart   # Create online room
│   │   ├── join_room_screen.dart     # Join by code
│   │   └── lobby_screen.dart         # Waiting room
│   ├── game/
│   │   ├── game_table_screen.dart    # Main game table + hot-seat handoff
│   │   └── widgets/
│   │       ├── card_widget.dart      # Card display
│   │       ├── hand_widget.dart      # Player hand fan
│   │       ├── table_area_widget.dart # Draw/discard piles + melds
│   │       └── score_board_widget.dart # Score overlay
│   └── rules/rules_screen.dart       # Game rules
└── test/
    └── engine_test.dart              # Dart engine unit tests
```

## Sécurité (anti-triche)

| Couche | Protection |
|---|---|
| **Auth** | JWT tokens, bcrypt passwords, guest accounts |
| **WebSocket** | Token validation on handshake, playerId injected from JWT |
| **Game Actions** | All validated server-side by shared engine |
| **State** | sanitizeStateForPlayer() hides other players' cards |
| **Room** | Code-based join, host controls, max players enforced |

