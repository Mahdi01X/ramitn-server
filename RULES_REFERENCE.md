# Rami Tunisien — Référentiel Unique des Règles Cible

> **Ce document est la source de vérité fonctionnelle unique pour le Rami Tunisien.**
> Toute implémentation (shared/, simple-server/, mobile/offline) DOIT converger vers ces règles.
> Dernière mise à jour : 2026-03-08

---

## 1. Composition du jeu

| Élément | Valeur |
|---------|--------|
| Paquets | 2 jeux de 52 cartes standard |
| Jokers | 4 (2 par paquet) |
| Total cartes | **108** |
| Joueurs | 2 à 4 |

### 1.1 Rangs et valeurs

| Rang | Valeur numérique | Points (ouverture / pénalité main) |
|------|-------------------|------------------------------------|
| As | 1 (bas) ou 14 (haut) selon contexte | **11** en pénalité, **1 ou 11** en ouverture selon position dans suite |
| 2–10 | Face value | Face value |
| Valet (J) | 11 | **10** |
| Dame (Q) | 12 | **10** |
| Roi (K) | 13 | **10** |
| Joker | — | **30** en pénalité |

### 1.2 As haut / As bas

- **As bas** : l'As peut être utilisé comme rang 1 dans une suite (A-2-3).
- **As haut** : l'As peut être utilisé comme rang 14 dans une suite (Q-K-A).
- **INTERDIT** : bouclage (K-A-2) — l'As ne peut pas servir de pont.
- En **set (tierce)** : l'As compte pour **11 points** de pénalité, et sa valeur de points de meld dépend de la configuration.

> **Hypothèse** : l'As vaut 1 point dans A-2-3 et 11 points dans Q-K-A pour le calcul d'ouverture. Configurable via `aceHighValue`.

---

## 2. Distribution

1. Le jeu est mélangé aléatoirement.
2. Chaque joueur reçoit **14 cartes**.
3. Le **premier joueur** (donneur ou joueur désigné) reçoit **15 cartes**.
4. La pioche (draw pile) contient les cartes restantes.
5. La défausse (discard pile) commence **vide**.
6. Le premier joueur commence directement en phase **Play** (il doit défausser sans piocher).

---

## 3. Ordre du premier joueur

- **Manche 1** : le premier joueur est le joueur d'index 0.
- **Manches suivantes** : le premier joueur tourne. L'index du premier joueur = `(round - 1) % numPlayers`.
- Le premier joueur d'une manche reçoit la carte supplémentaire (15 au lieu de 14).

---

## 4. Déroulement d'un tour

### 4.1 États du tour

Chaque tour suit cette machine d'état :

```
Draw → Play → Discard → (prochain joueur: Draw)
```

- **Draw** : le joueur DOIT piocher exactement 1 carte (pioche OU défausse).
- **Play** : le joueur PEUT poser des combinaisons, faire des layoffs, récupérer des jokers.
- **Discard** : le joueur DOIT défausser exactement 1 carte pour terminer son tour.

**Exception premier joueur** : le premier joueur de la manche commence directement en phase **Play** (car il a 15 cartes).

### 4.2 Pioche depuis la pioche (draw pile)

- Le joueur prend la carte du dessus de la pioche.
- Si la pioche est vide, la défausse est remélangée (sauf la carte du dessus) et devient la nouvelle pioche.
- Si les deux sont vides/insuffisantes → la manche est déclarée nulle (deck vide).

### 4.3 Pioche depuis la défausse (discard pile)

- Le joueur prend la carte du dessus de la défausse.
- **PÉNALITÉ +100** : si le joueur pioche depuis la défausse et ne parvient pas à ouvrir (ou n'a pas encore ouvert) avant la fin de son tour, il reçoit immédiatement **100 points de pénalité**.
- Le flag `drewFromDiscard` est activé pour le tour.

### 4.4 Interdiction de doublon exact sur défausse

- **Règle** : un joueur ne peut PAS prendre la carte du dessus de la défausse s'il possède déjà dans sa main **une carte de même rang ET même couleur** (doublon exact, pas besoin d'être du même paquet).
- Cette vérification s'applique avant la prise.

> **Hypothèse** : cette règle est optionnelle (configurable via `duplicateProtection: boolean`). Active par défaut en mode tunisien.

### 4.5 Pénalité de pioche défausse

| Condition | Effet |
|-----------|-------|
| Pioche défausse + ouverture réussie dans le même tour | Pas de pénalité |
| Pioche défausse + déjà ouvert | Pas de pénalité |
| Pioche défausse + pas d'ouverture ce tour + pas encore ouvert | **+100 points pénalité** |

---

## 5. Combinaisons (Melds)

### 5.1 Types

| Type | Description | Taille |
|------|-------------|--------|
| **Set (Tierce)** | 3 ou 4 cartes de même rang, couleurs toutes différentes | 3–4 |
| **Run (Suite)** | 3+ cartes consécutives de même couleur | 3–13 |

### 5.2 Règles de set

- Minimum 3 cartes, maximum 4 (carré).
- Toutes les cartes doivent avoir le **même rang**.
- Toutes les couleurs (suits) doivent être **différentes**.
- Un joker peut remplacer une couleur manquante.
- Maximum 1 joker par set (configurable via `maxJokersPerMeld`).

### 5.3 Règles de suite (run)

- Minimum 3 cartes consécutives de la **même couleur**.
- Les jokers peuvent combler les trous.
- Maximum 1 joker par suite par défaut (configurable).
- L'As peut être bas (A-2-3) ou haut (Q-K-A), jamais les deux (pas de bouclage K-A-2).
- Les cartes doivent être strictement consécutives (pas de doublons de rang).

### 5.4 Points des combinaisons pour l'ouverture

- Chaque carte (y compris joker) est comptée selon sa valeur de points.
- Joker = `jokerValue` (défaut 30) dans le calcul de points de meld.
- As = 1 si dans A-2-3, = `aceHighValue` (défaut 11) sinon.

---

## 6. Ouverture

### 6.1 Seuil d'ouverture

- Le joueur doit poser un ensemble de combinaisons valides totalisant **≥ 71 points**.
- Configurable via `openingThreshold`.

### 6.2 Suite propre obligatoire (clean run)

- L'ouverture DOIT contenir au moins **1 suite (run) sans aucun joker**.
- Configurable via `openingRequiresCleanRun`.

### 6.3 Ouverture multi-paquets (batch opening)

- Le joueur peut **poser plusieurs combinaisons en une seule action d'ouverture**.
- Les combinaisons sont "staged" (mises en attente) jusqu'à confirmation.
- Actions disponibles :
  - `meld` → ajoute un paquet au staging
  - `confirm_opening` → valide l'ensemble des paquets stagés
  - `cancel_staging` → annule tous les paquets stagés
- La validation du seuil et de la suite propre s'applique à **l'ensemble** des paquets stagés.
- Les cartes stagées restent dans la main du joueur jusqu'à `confirm_opening`.

### 6.4 Obligation de garder 1 carte pour défausser

- **AVANT** de confirmer l'ouverture, vérifier que le joueur conserve **au moins 1 carte** dans sa main pour pouvoir défausser.
- Si toutes les cartes seraient utilisées par les melds stagés, l'ouverture est refusée.
- Exception : si le joueur vide exactement sa main et que cela constitue une victoire de manche, c'est autorisé (rami sec / going out).

---

## 7. Actions post-ouverture

### 7.1 Pose de meld additionnel

- Après l'ouverture, le joueur peut poser des melds individuels sans contrainte de seuil.
- Chaque meld doit être valide (set ou run).

### 7.2 Layoff (ajout à un meld existant)

- Le joueur peut ajouter une carte à un meld existant (sien ou d'un autre joueur) **seulement s'il a déjà ouvert**.
- La carte doit maintenir la validité du meld.
- Position : `start` ou `end` pour les suites, `end` pour les sets (ajout du 4ème).

### 7.3 Récupération de joker (replace_joker)

- Un joueur qui a ouvert peut remplacer un joker dans un meld par la carte naturelle correspondante.
- Le joker récupéré va dans la main du joueur.
- Le meld résultant doit rester valide après remplacement.
- Configurable : `jokerLocked: boolean` — si true, les jokers ne peuvent pas être récupérés.

> **Règle tunisienne stricte (Dart offline)** : récupération d'un joker depuis un set uniquement si le set devient un carré complet (4 cartes, 4 couleurs différentes, toutes naturelles).

---

## 8. Défausse

- Le joueur DOIT défausser exactement 1 carte à la fin de son tour.
- La carte est placée face visible sur le dessus de la défausse.
- Après défausse, la pénalité discard-draw est évaluée (voir §4.5).
- Le tour passe au joueur suivant.

---

## 9. Frich (vote de redistribution)

- **OPTIONNEL** (configurable `frichEnabled: boolean`).
- Au début de chaque manche, après distribution, chaque joueur vote s'il souhaite une redistribution ("frich").
- Si **tous** les joueurs votent "oui", les cartes sont redistribuées.
- Si un seul joueur vote "non", le jeu continue normalement.
- Cette mécanique n'est implémentée que dans le mode offline Dart actuellement.

---

## 10. Fin de manche

### 10.1 Victoire

- Un joueur **gagne la manche** quand il vide complètement sa main (la défausse de la dernière carte compte).
- Le gagnant marque **0 points** pour cette manche.

### 10.2 Calcul des pénalités (scoring)

Pour chaque perdant :
- Chaque carte restant en main est comptabilisée avec sa **valeur de pénalité** :
  - As = 11
  - Figure (J/Q/K) = 10
  - Nombre (2-10) = face value
  - Joker = 30
- Le total est ajouté au `totalScore` cumulé du joueur.

### 10.3 Pénalité spéciale discard-draw

- Si un joueur a pioché depuis la défausse et n'a pas ouvert ce tour → +100 points ajoutés immédiatement à `totalScore`.

### 10.4 Deck vide

- Si la pioche et la défausse sont toutes deux épuisées, la manche est déclarée **nulle** (aucun gagnant, aucune pénalité, ou autre convention).

> **Hypothèse** : en cas de deck vide, la défausse est remélangée en pioche (sauf la carte du dessus). Si même ça ne suffit pas, la manche est annulée.

---

## 11. Fin de partie

### 11.1 Mode cumulatif (cumulative)

- La partie dure `maxRounds` manches (défaut : 5).
- À la fin, le joueur avec le **score total le plus bas** gagne.
- En cas d'égalité, les joueurs sont à égalité (pas de tiebreaker défini).

### 11.2 Mode élimination

- Un joueur est éliminé quand son `totalScore` atteint ou dépasse `eliminationThreshold` (défaut : 100).
- Le dernier joueur non éliminé gagne.
- Si le seuil d'élimination est atteint par le dernier joueur restant, vérifier quand même le seuil de manches.

---

## 12. Rotation du joueur de départ

- À chaque nouvelle manche, l'index du premier joueur tourne :
  - Manche 1 → joueur 0
  - Manche 2 → joueur 1
  - Manche N → joueur `(N-1) % numPlayers`
- Le premier joueur reçoit 15 cartes et commence en phase Play.

---

## 13. Prévention de soft-lock

### 13.1 Règle "garder 1 carte"

- À tout moment du tour, si un joueur tente une action qui le laisserait avec 0 cartes sans que cela constitue une fin de manche valide, l'action est refusée.
- Concrètement : avant un meld ou layoff, vérifier que `hand.length - cardsUsed >= 1` (sauf si le meld+discard vide la main = victoire).

### 13.2 Blocage complet

- Si aucun joueur ne peut jouer (pioche vide, défausse vide, aucune action possible) → manche nulle.

---

## 14. Protocole online cible (événements Socket.IO)

### 14.1 Client → Serveur

| Événement | Payload | Description |
|-----------|---------|-------------|
| `register` | `{ name, playerId? }` | Enregistrement du joueur |
| `create_room` | `{ numPlayers, config? }` | Création de salle |
| `join_room` | `{ roomCode }` | Rejoindre une salle |
| `ready` | — | Basculer prêt/pas prêt |
| `start_game` | — | Démarrer (hôte seulement) |
| `game_action` | `{ action: GameAction }` | Action de jeu (voir §14.3) |
| `chat_message` | `{ message }` | Message de chat |

### 14.2 Serveur → Client

| Événement | Payload | Description |
|-----------|---------|-------------|
| `registered` | `{ playerId, playerName }` | Confirmation d'enregistrement |
| `room_created` | `{ roomCode, roomId, numPlayers, players }` | Salle créée |
| `room_joined` | `{ roomCode, roomId, numPlayers, players }` | Joueur a rejoint |
| `player_joined` | `{ playerId, playerName, players }` | Notification de nouveau joueur |
| `player_ready` | `{ playerId, ready, players }` | Statut prêt changé |
| `game_started` | `{ players }` | Partie démarrée |
| `game_state_update` | `{ state: SanitizedGameState }` | Mise à jour d'état |
| `game_error` | `{ code?, message }` | Erreur |
| `meld_staged` | `{ meldType, points, stagedTotal, hasCleanRun }` | Meld stagé (pré-ouverture) |
| `staging_cancelled` | — | Staging annulé |
| `round_end` | `{ winnerId, winnerName, results, scores }` | Fin de manche |
| `game_over_forfeit` | `{ winnerId, winnerName, reason }` | Forfait |
| `chat_broadcast` | `{ senderId, senderName, message, timestamp }` | Chat |

### 14.3 Actions de jeu (GameAction)

| Type | Champs | Description |
|------|--------|-------------|
| `draw_deck` | — | Piocher depuis la pioche |
| `draw_discard` | — | Piocher depuis la défausse |
| `meld` | `{ cardIds }` | Poser un meld (staged si pas ouvert) |
| `confirm_opening` | — | Confirmer l'ouverture |
| `cancel_staging` | — | Annuler le staging |
| `layoff` | `{ cardId, meldId }` | Ajouter à un meld existant |
| `discard` | `{ cardId }` | Défausser une carte |

> **Note** : `replace_joker` est fusionné dans `layoff` côté simple-server (détection automatique de swap joker). Côté shared/, c'est une action séparée. **Cible** : garder `replace_joker` comme action explicite.

---

## 15. Configuration par défaut

```json
{
  "numPlayers": 4,
  "numJokers": 4,
  "cardsPerPlayer": 14,
  "openingThreshold": 71,
  "openingRequiresCleanRun": true,
  "jokerValue": 30,
  "aceHighValue": 11,
  "maxRounds": 5,
  "scoringMode": "cumulative",
  "eliminationThreshold": 100,
  "jokerLocked": false,
  "maxJokersPerMeld": 1,
  "turnTimeoutSeconds": 60,
  "duplicateProtection": true,
  "frichEnabled": false
}
```

---

## 16. Matrice de divergences connues

| Règle | shared/ | simple-server | Dart offline | Cible |
|-------|---------|---------------|-------------|-------|
| Ouverture multi-paquets (batch) | ❌ (1 meld) | ✅ (staged) | ✅ (meldBatch) | ✅ |
| Pénalité +100 discard sans ouverture | ❌ | ✅ | ✅ | ✅ |
| Doublon exact sur défausse | ❌ | ❌ | ✅ | ✅ |
| As haut (Q-K-A) | ❌ (pas testé) | ❌ | ✅ (try low then high) | ✅ |
| Garder 1 carte pour jeter | ❌ | ❌ | ✅ | ✅ |
| Joker recovery strict (carré) | ❌ | ❌ (swap simple) | ✅ | ✅ |
| Frich vote | ❌ | ❌ | ✅ | ✅ (optionnel) |
| Rotation premier joueur | ❌ (toujours idx 0) | ❌ | ✅ | ✅ |
| Calcul As dans suite pour points | Toujours 11 | Toujours rankValue | Contexte (1 ou 11) | Contexte |
| confirm_opening / staging | ❌ | ✅ | ✅ (implicit) | ✅ |
| replace_joker explicite | ✅ | ❌ (dans layoff) | ✅ | ✅ |
| Deck vide → reshuffle | ✅ | ✅ | ✅ | ✅ |
| Soft-lock prevention | ❌ | ❌ | Partiel | ✅ |

---

## 17. Hypothèses à confirmer

1. **Rami sec** : un joueur peut-il gagner en posant toutes ses cartes en un seul tour (sans défausser) ? Hypothèse : oui, si la dernière action est un meld/layoff qui vide la main.
2. **Score joker dans suite** : le joker vaut-il les points de la carte qu'il remplace (pour le calcul d'ouverture) ? Hypothèse : oui.
3. **Égalité en fin de partie** : comment départager ? Hypothèse : pas de tiebreaker, égalité déclarée.
4. **Multiple rounds de frich** : peut-on re-voter ? Hypothèse : un seul vote par manche au début.
5. **Reconnexion** : en cas de déconnexion, le joueur peut-il reprendre ? Hypothèse : supporté ultérieurement, pas critique pour v1.

---

## 18. Trajectoire de convergence

1. **Phase immédiate** : porter les règles manquantes dans `shared/` (source de vérité)
2. **Phase 2** : adapter `simple-server/` pour utiliser le moteur de `shared/` au lieu de son moteur embarqué
3. **Phase 3** : adapter le client Flutter online pour utiliser les noms d'actions de `shared/`
4. **Phase 4** : aligner le moteur Dart offline sur les mêmes règles que `shared/`
5. **Phase finale** : une seule source de tests, un seul protocole, un seul moteur
