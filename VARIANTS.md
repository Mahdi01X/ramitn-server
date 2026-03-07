# 🔧 Points Ouverts — Variantes Configurables

Ce document liste les règles du Rami Tunisien qui peuvent varier selon les régions/familles
et indique comment les configurer dans l'application.

## 1. Ouverture (Opening Threshold)

**Question :** Faut-il un seuil minimum de points pour poser la première fois ?

| Variante | Valeur | Paramètre |
|---|---|---|
| **A (défaut)** | Oui, 71 points minimum + **une suite sans joker obligatoire** | `openingThreshold: 71, openingRequiresCleanRun: true` |
| **B** | Oui, 30 points minimum (variante allégée) | `openingThreshold: 30, openingRequiresCleanRun: false` |
| **C** | Oui, 51 points minimum (variante intermédiaire) | `openingThreshold: 51` |
| **D** | Non, pas de seuil | `openingThreshold: 0` |

**Où configurer :** `GameConfig.openingThreshold` + `GameConfig.openingRequiresCleanRun`

**Note :** L'obligation d'une suite sans joker signifie qu'un joueur ne peut pas ouvrir avec uniquement des brelans/carrés. Il doit poser au moins une suite (Run) composée entièrement de cartes normales (aucun joker).

## 2. Jokers

### 2a. Jokers récupérables

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | Un joker posé peut être récupéré par qui possède la carte remplacée | `jokerLocked: false` |
| **B** | Les jokers posés sont verrouillés | `jokerLocked: true` |

### 2b. Nombre de jokers par meld

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | 1 joker maximum par combinaison | `maxJokersPerMeld: 1` |
| **B** | 2 jokers par combinaison (plus permissif) | `maxJokersPerMeld: 2` |

### 2c. Nombre total de jokers dans le deck

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | 4 jokers (un par demi-deck × 2) | `numJokers: 4` |
| **B** | 2 jokers | `numJokers: 2` |

## 3. Valeur de l'As

**Question :** L'As vaut-il toujours 11 points ou 1 point en début de suite ?

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | L'As vaut 11 points (en main et en scoring) | `aceHighValue: 11` |
| **B** | L'As vaut 1 point | `aceHighValue: 1` |

**Note :** Dans les suites, l'As peut être utilisé en position basse (A-2-3) ou haute (Q-K-A).
Le scoring utilise toujours `aceHighValue` pour la pénalité.

## 4. Mode de Scoring

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | Cumulatif : on additionne les pénalités. Après N manches, le plus bas gagne. | `scoringMode: 'cumulative'` |
| **B** | Élimination : un joueur est éliminé quand il dépasse un seuil. | `scoringMode: 'elimination'` |

### 4a. Nombre de manches (mode cumulatif)

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | 5 manches | `maxRounds: 5` |
| **B** | 10 manches | `maxRounds: 10` |
| **C** | Personnalisé (1-20) | `maxRounds: N` |

### 4b. Seuil d'élimination (mode élimination)

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | 100 points | `eliminationThreshold: 100` |
| **B** | 150 points | `eliminationThreshold: 150` |

## 5. Valeur des Jokers en pénalité

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | 30 points | `jokerValue: 30` |
| **B** | 50 points (plus punitif) | `jokerValue: 50` |

## 6. Nombre de cartes distribuées

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | 14 cartes | `cardsPerPlayer: 14` |
| **B** | 13 cartes | `cardsPerPlayer: 13` |

## 7. Timer par tour

| Variante | Description | Paramètre |
|---|---|---|
| **A (défaut)** | 60 secondes | `turnTimeoutSeconds: 60` |
| **B** | Pas de timer | `turnTimeoutSeconds: 0` |
| **C** | 30 secondes (mode rapide) | `turnTimeoutSeconds: 30` |

## Où configurer

Tous ces paramètres sont dans l'objet `GameConfig` :

```typescript
// shared/src/types/game-config.ts
interface GameConfig {
  numPlayers: number;           // 2-4
  numJokers: number;            // 2 ou 4 (défaut: 4)
  cardsPerPlayer: number;       // 13 ou 14
  openingThreshold: number;     // 0, 30, 51, 71... (défaut: 71)
  openingRequiresCleanRun: boolean; // true = suite sans joker obligatoire (défaut: true)
  jokerValue: number;           // 30 ou 50
  aceHighValue: number;         // 1 ou 11
  maxRounds: number;            // 1-20
  scoringMode: string;          // 'cumulative' | 'elimination'
  eliminationThreshold: number; // 100, 150...
  jokerLocked: boolean;         // false | true
  maxJokersPerMeld: number;     // 1 ou 2
  turnTimeoutSeconds: number;   // 0, 30, 60...
}
```

**Côté mobile (Flutter)** : même structure dans `lib/models/game_config.dart`.

**Côté serveur** : passé lors de `create_room` → `{ config: Partial<GameConfig> }`.

**Mode hors-ligne** : configurable depuis l'écran de setup (`offline_setup_screen.dart`).




