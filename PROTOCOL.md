# 📡 Protocole WebSocket — Rami Tunisien

## Connexion

Endpoint : `ws://<host>:3000/game`

Authentification via le handshake :
```json
{
  "auth": { "token": "<JWT_TOKEN>" }
}
```

## Événements Client → Serveur

### Room Management

| Événement | Données | Description |
|---|---|---|
| `create_room` | `{ config?: Partial<GameConfig> }` | Crée une room privée |
| `join_room` | `{ roomCode: string }` | Rejoint une room par code |
| `leave_room` | `{}` | Quitte la room |
| `ready` | `{}` | Signale que le joueur est prêt |
| `start_game` | `{}` | Lance la partie (host uniquement) |

### Game Actions

| Événement | Données | Description |
|---|---|---|
| `game_action` | `{ action: { type: "draw_from_deck" } }` | Piocher du deck |
| `game_action` | `{ action: { type: "draw_from_discard" } }` | Piocher du talon |
| `game_action` | `{ action: { type: "meld", cardIds: number[] } }` | Poser une combinaison |
| `game_action` | `{ action: { type: "layoff", cardId: number, targetMeldId: string, position: "start"|"end" } }` | Compléter une combinaison |
| `game_action` | `{ action: { type: "replace_joker", cardId: number, targetMeldId: string, jokerCardId: number } }` | Remplacer un joker |
| `game_action` | `{ action: { type: "discard", cardId: number } }` | Défausser une carte |

### Autres

| Événement | Données | Description |
|---|---|---|
| `chat_message` | `{ message: string }` | Envoyer un message dans le chat |
| `join_matchmaking` | `{ preferredPlayers: number }` | Rejoindre le matchmaking |
| `resign` | `{}` | Abandonner la partie |

## Événements Serveur → Client

| Événement | Données | Description |
|---|---|---|
| `room_created` | `{ roomCode, roomId }` | Room créée avec succès |
| `room_joined` | `{ roomCode, players[] }` | Rejoint avec succès |
| `player_joined` | `{ playerId, playerName }` | Un joueur a rejoint |
| `player_left` | `{ playerId }` | Un joueur a quitté |
| `player_ready` | `{ playerId }` | Un joueur est prêt |
| `game_started` | `{}` | Partie lancée |
| `game_state_update` | `{ state: SanitizedGameState }` | État du jeu mis à jour |
| `game_error` | `{ code, message }` | Erreur de jeu |
| `chat_broadcast` | `{ senderId, senderName, message, timestamp }` | Message chat |
| `round_end` | `{ scores, totalScores, winnerId, round }` | Fin de manche |
| `game_end` | `{ finalScores, winnerId }` | Fin de partie |
| `matchmaking_waiting` | `{ position }` | En attente de matchmaking |

## SanitizedGameState

Chaque joueur reçoit une vue filtrée du jeu :
- `myHand` : ses propres cartes
- `players[].handCount` : nombre de cartes des autres (pas leurs cartes)
- `drawPileCount` : taille de la pioche
- `discardPile` : cartes visibles du talon
- `tableMelds` : combinaisons posées
- `currentPlayerIndex`, `phase`, `turnStep`

## Sécurité

- Le serveur injecte toujours `playerId` depuis le JWT (le client ne peut pas usurper)
- Chaque action est validée par le moteur de jeu côté serveur
- Le client ne voit jamais les cartes des autres joueurs

