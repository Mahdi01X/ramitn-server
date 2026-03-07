# 🃏 Règles du Rami Tunisien

## Matériel
- 2 jeux de 52 cartes + **4 jokers** (configurable : 2 ou 4)
- 2 à 4 joueurs

## But du jeu
Se débarrasser de toutes ses cartes en posant des combinaisons valides.

## Distribution
- Chaque joueur reçoit **14 cartes** (configurable)
- Le reste forme la **pioche** (face cachée)
- La première carte de la pioche est retournée pour former le **talon** (défausse)

## Combinaisons valides

### Suite (Run)
3+ cartes consécutives de la **même couleur**.
Exemple : 5♥ 6♥ 7♥ ou 10♠ J♠ Q♠ K♠

### Brelan / Carré (Set)
3 ou 4 cartes de **même rang**, de couleurs **différentes**.
Exemple : 7♥ 7♠ 7♦ ou K♥ K♠ K♦ K♣

## Tour de jeu
1. **Piocher** : prendre une carte de la pioche OU la dernière carte du talon
2. **Poser** (optionnel) : poser des combinaisons ou compléter des combinaisons existantes
3. **Défausser** : se défaire d'une carte sur le talon

## Ouverture (Variante A — activée par défaut)
- Pour poser pour la **première fois**, la somme des points des combinaisons posées doit atteindre un **seuil minimum** (**71 points** par défaut, configurable).
- L'ouverture **doit inclure au moins une suite sans joker** (clean run). Un brelan/carré seul ne suffit pas pour ouvrir.
- **Variante B** (désactivable) : pas de seuil, le joueur peut poser dès qu'il veut (`openingThreshold: 0`).
- **Variante C** (configurable) : pas d'obligation de suite sans joker (`openingRequiresCleanRun: false`).

## Jokers
- Un joker peut **remplacer n'importe quelle carte** dans une combinaison.
- **Variante A** (par défaut) : un joker posé peut être **récupéré** par un joueur qui possède la carte qu'il remplace.
- **Variante B** (configurable) : les jokers posés sont **verrouillés** et ne peuvent pas être récupérés.
- Maximum **1 joker** par combinaison (configurable).

## Valeur des cartes (pour le scoring)
| Carte | Points |
|---|---|
| As | 1 (en début de suite) ou 11 (en fin / seul) — configurable |
| 2–10 | Valeur faciale |
| Valet, Dame, Roi | 10 |
| Joker | 30 (ou 50, configurable) |

## Fin de manche
- Un joueur pose ou complète toutes ses cartes restantes → il **gagne la manche**.
- Les autres joueurs comptent les points des cartes **restant en main**.
- Le gagnant marque **0 points**.

## Scoring multi-manches
- **Mode A** (par défaut) : on cumule les pénalités. Après N manches (défaut: 5), le joueur avec le **score le plus bas** gagne.
- **Mode B** (configurable) : un joueur est **éliminé** quand il dépasse un seuil (ex: 100 points). Le dernier survivant gagne.

## Paramètres configurables (GameConfig)
| Paramètre | Défaut | Description |
|---|---|---|
| `numJokers` | 4 | Nombre de jokers dans le deck |
| `cardsPerPlayer` | 14 | Nombre de cartes distribuées |
| `openingThreshold` | 71 | Points minimum pour la première pose (0 = désactivé) |
| `openingRequiresCleanRun` | true | L'ouverture doit inclure une suite sans joker |
| `jokerValue` | 30 | Valeur en points d'un joker en main |
| `aceHighValue` | 11 | Valeur de l'As non en début de suite |
| `maxRounds` | 5 | Nombre de manches |
| `scoringMode` | `"cumulative"` | `"cumulative"` ou `"elimination"` |
| `eliminationThreshold` | 100 | Seuil d'élimination (mode B) |
| `jokerLocked` | false | Jokers verrouillés une fois posés |
| `maxJokersPerMeld` | 1 | Max jokers par combinaison |




