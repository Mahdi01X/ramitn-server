# 🃏 Rami Tunisien — Cross-Platform Card Game

Application mobile cross-platform (Android + iOS) du **Rami Tunisien**, avec backend temps réel.

## Architecture Monorepo

```
/shared   → Types TypeScript + Moteur de jeu (fonctions pures)
/server   → Backend NestJS + WebSocket (Socket.IO) + PostgreSQL + Redis
/mobile   → Application Flutter (Dart) — Android & iOS
```

## Prérequis

- **Node.js** >= 18
- **npm** >= 9
- **Flutter** >= 3.19 (channel stable)
- **Docker** + **Docker Compose** (pour le backend)
- **Android SDK** (pour build Android)
- **Xcode** (macOS uniquement, pour build iOS)

## Initialisation (première fois)

### Option A — Script automatique (Windows)
```bat
.\setup.bat
```

### Option B — Manuel

```bash
# 1. Initialiser le projet Flutter (si android/ et ios/ n'existent pas)
.\init-flutter.bat
# OU manuellement :
# flutter create --org com.example --project-name rami_tunisien mobile_tmp
# Copier android/ et ios/ de mobile_tmp dans mobile/
# Supprimer mobile_tmp

# 2. Installer les dépendances TypeScript
cd shared && npm install && npm run build && cd ..
cd server && npm install && cd ..

# 3. Installer les dépendances Flutter
cd mobile && flutter pub get && cd ..

# 4. Configurer l'environnement serveur
copy server\.env.example server\.env
```

## Démarrage rapide

### Backend (Docker — recommandé)
```bash
docker compose up -d
```
Le serveur est accessible sur `http://localhost:3000`

### Backend (développement local)
```bash
# Terminal 1 — PostgreSQL + Redis (Docker)
docker compose up postgres redis -d

# Terminal 2 — Serveur NestJS
cd server && npm run start:dev
```

### Mobile
```bash
cd mobile

# Android (émulateur ou appareil connecté)
flutter run

# iOS (macOS + Xcode uniquement)
flutter run -d ios

# Spécifier l'URL du serveur (si non-local)
flutter run --dart-define=SERVER_URL=http://192.168.1.42:3000
```

## Tests

```bash
# Tests du moteur de jeu (TypeScript)
cd shared && npm test

# Tests du serveur (NestJS)
cd server && npm test

# Tests Flutter
cd mobile && flutter test
```

## Build de production

### APK Android
```bash
cd mobile
flutter build apk --release
# Output: mobile/build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle Android (Play Store)
```bash
cd mobile
flutter build appbundle --release
# Output: mobile/build/app/outputs/bundle/release/app-release.aab
```

### iOS (macOS uniquement)
```bash
cd mobile
flutter build ios --release
# Puis ouvrir ios/Runner.xcworkspace dans Xcode pour archiver
```

## Variables d'environnement

### Serveur (server/.env)
| Variable | Description | Défaut |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://rami:rami@localhost:5432/rami` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379` |
| `JWT_SECRET` | Secret pour les tokens JWT | `change-me-in-production` |
| `PORT` | Port du serveur HTTP/WS | `3000` |

### Mobile (--dart-define)
| Variable | Description | Défaut |
|---|---|---|
| `SERVER_URL` | URL du backend | `http://10.0.2.2:3000` (émulateur Android) |

## Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) — Architecture technique détaillée
- [RULES.md](./RULES.md) — Règles complètes du Rami Tunisien
- [PROTOCOL.md](./PROTOCOL.md) — Protocole WebSocket documenté
- [VARIANTS.md](./VARIANTS.md) — Points ouverts et variantes configurables

## Structure détaillée

```
├── shared/
│   └── src/
│       ├── types/          # Card, Meld, Player, GameState, Events, Room, Config
│       ├── engine/         # deck, meld-validator, turn, scoring, opening, game-machine, bot-ai
│       └── __tests__/      # Tests unitaires du moteur
├── server/
│   └── src/
│       ├── auth/           # AuthModule (register, login, guest, JWT)
│       └── game/           # GameModule (Gateway WS, RoomService, GameService)
├── mobile/
│   └── lib/
│       ├── app/            # Router (GoRouter)
│       ├── core/           # Theme, Constants
│       ├── engine/         # Portage Dart du moteur (mode offline)
│       ├── models/         # Card, Meld, GameState, GameConfig
│       ├── providers/      # Riverpod (Auth, Game, Room)
│       ├── screens/        # Home, Auth, Offline, Lobby, Game, Rules
│       └── services/       # AuthService (Dio), SocketService (Socket.IO)
└── docker-compose.yml      # PostgreSQL + Redis + Server
```

## Roadmap

### MVP (actuel)
- ✅ Moteur de jeu complet (TypeScript + Dart)
- ✅ Mode hors-ligne hot-seat (2-4 joueurs + bots)
- ✅ Backend WebSocket avec rooms privées
- ✅ Auth (email/password + invité)
- ✅ UI de jeu complète
- ✅ Chat en room

### V1
- 🔲 IA bot améliorée (stratégie avancée)
- 🔲 Matchmaking public
- 🔲 Reconnexion après déconnexion
- 🔲 Statistiques joueur (parties jouées, gagnées)
- 🔲 Anti-abandon (timer + pénalité)
- 🔲 Animations drag & drop avancées
- 🔲 Notifications push
- 🔲 Profil joueur avec avatar


