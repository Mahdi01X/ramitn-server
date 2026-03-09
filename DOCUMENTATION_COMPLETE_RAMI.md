# Documentation Complete - Projet RamiTN

## 1. Resume Executif

Le projet contient bien une architecture monorepo (`mobile` + `shared` + `server`), mais en pratique il existe **deux backends online differents** :

1. `simple-server/` (Node + Socket.IO, sans JWT)  
   - C'est celui qui est lance par les scripts locaux et deploye sur Render.
2. `server/` (NestJS + JWT + TypeORM + shared engine)  
   - C'est une architecture plus propre, mais elle n'est pas totalement alignee avec le client Flutter online actuel.

Conclusion importante : **les regles ne sont pas exactement les memes selon le mode** (offline mobile, online simple-server, online Nest/shared).

---

## 2. Architecture Reelle

## 2.1 Monorepo

- `mobile/` : client Flutter (offline + online).
- `shared/` : types et moteur TypeScript (utilise par NestJS).
- `server/` : backend NestJS (auth JWT + rooms + moteur shared).
- `simple-server/` : backend Socket.IO autonome, actuellement utilise en production.

## 2.2 Runtime Online actuellement utilise

- Le client online Flutter (`SocketService.connect`) envoie un event `register` sans token JWT.
- Le backend `simple-server` attend exactement ce flux.
- Les scripts `start-server*.bat/ps1`, `LANCER-TOUT.bat`, `render.yaml` pointent tous vers `simple-server`.

## 2.3 Runtime cible (NestJS + shared)

- Le gateway NestJS exige un token JWT au handshake.
- Les actions attendues sont du type `draw_from_deck`, `draw_from_discard`, etc.
- Ce chemin est plus robuste sur le papier, mais pas aligne avec le protocole online actuellement utilise par Flutter (`draw_deck`, `draw_discard`, `confirm_opening`, `register`).

## 2.4 Offline

- L'offline est gere par `mobile/lib/engine/game_engine.dart`.
- Ce moteur Dart contient des regles et comportements qui n'existent pas dans `shared`.
- Il inclut aussi des features avancees (frich vote, timer auto-play, regle des 100 points, blocage des doublons sur la defausse).

---

## 3. Regles Implantees (etat reel)

## 3.1 Matrice des regles par mode

Legende :
- Oui = implemente
- Partiel = implemente avec limites
- Non = absent

| Regle | Offline (Dart) | Online (simple-server) | Online (Nest + shared) |
|---|---|---|---|
| Deck 2x52 + jokers configurables | Oui | Partiel (4 jokers fixes dans le flux principal) | Oui |
| Distribution 15 pour le premier, 14 pour les autres | Oui | Oui | Oui |
| Premier joueur commence en `play` (doit jeter) | Oui | Oui | Oui |
| Ouverture 71 + clean run | Oui | Oui | Oui |
| Ouverture multi-paquets dans le meme tour | Oui (`meldBatch`) | Oui (`meld` stage + `confirm_opening`) | **Non** (validation paquet par paquet) |
| Pioche defausse + echec d'ouverture = +100 | Oui | Oui | Non |
| Interdiction de prendre une defausse en doublon exact | Oui | Non | Non |
| Recuperation joker | Oui (avec regles specifiques) | Partiel | Partiel |
| Limite de jokers par meld (`maxJokersPerMeld`) | **Non reelle** (peu/pas appliquee) | Non | Oui |
| As haut (Q-K-A) en suite | Oui | Non | Non |
| Obligation de garder 1 carte pour defausser | Oui | Non | Non |
| Scoring multi-manches complet | Oui | **Non** (round end partiel) | Oui |
| Mode elimination | Oui | Non | Oui |
| Rotation du joueur qui commence la manche | Oui | Non (host toujours premier) | Non (index 0) |
| Vote "frich" (reshuffle consensuel) | Oui | Non | Non |

## 3.2 Details importants sur la coherence

- Le jeu online "reel" du produit suit surtout `simple-server`, pas `shared`.
- Les docs existantes presentent surtout la vision `shared + Nest`, mais ce n'est pas exactement ce que joue un utilisateur online aujourd'hui.
- L'offline est aujourd'hui le mode le plus riche en regles tunisiennes specifiques.

---

## 4. Regles Manquantes pour un "vrai rami tunisien" (version stricte)

Reference proposee (la plus courante dans les parties cafe/famille, a valider metier) :

1. Ouverture en plusieurs paquets dans le meme tour avec total >= seuil.
2. Obligation clean run a l'ouverture (si variante active).
3. Si on prend la defausse et on n'ouvre pas ce tour : penalite immediate lourde (souvent 100).
4. Interdiction de prendre une carte defaussee deja possedee (doublon exact).
5. Obligation de garder une carte pour jeter (pas de tour "sans defausse").
6. Gestion stricte de recuperation joker (carte exacte, contraintes set/run).
7. Gestion claire de l'As en suite (A-2-3 et Q-K-A selon variante).
8. Rotation du premier joueur entre manches.
9. Tie-breaks et cas limites (deck vide, blocage de manche, egalites) formalises.

### Ecarts actuels majeurs

- Online simple-server : pas d'As haut, pas de blocage doublon defausse, pas de "garder 1 carte", pas de multi-manches solide.
- Online Nest/shared : pas de penalite 100, pas d'ouverture multi-paquets, pas d'As haut, pas de blocage doublon, pas de "garder 1 carte".
- Moteurs non alignes => resultat de partie different selon mode.

---

## 5. Ce Qui Manque pour un "Jeu Parfait"

## 5.1 Priorite 1 - Unifier les regles

Choisir une seule source de verite pour les regles :

- Option recommandee : migrer tout l'online sur `server + shared` **apres** avoir porte les regles offline specifiques manquantes dans `shared`.
- Puis faire deriver le moteur offline depuis la meme logique regle (ou codegen de contrats/tests croises).

## 5.2 Priorite 2 - Unifier le protocole online

- Meme nomenclature d'actions partout (`draw_from_deck` vs `draw_deck`).
- Supprimer les events fantomes/non supportes cote client.
- Contrat unique versionne (events + schemas payload).

## 5.3 Priorite 3 - Completer les regles metier

- Ouvrir avec plusieurs melds dans `shared`.
- Penalite "defausse prise sans ouverture".
- Regle doublon defausse.
- Regle "garder 1 carte pour jeter".
- As haut/bas harmonise.
- Recuperation joker stricte (traquer la substitution exacte).
- Rotation du premier joueur par manche.

## 5.4 Priorite 4 - Qualite produit online

- Reconnexion/reprise de partie.
- Gestion abandon (forfeit propre, timeout).
- Persistance de parties (etat + historique).
- Leaderboard/stats reels.
- Observabilite (logs, metriques, traces).
- CI avec tests unitaires + integration + e2e protocole.

---

## 6. Risques Techniques Actuels

1. **Divergence de regles** entre offline/online.
2. **Divergence protocole** entre Flutter et Nest.
3. **Soft-lock potentiel** si un joueur pose toutes ses cartes sans possibilite de defausse (modes online non proteges).
4. **Confiance fonctionnelle faible** : tests non executes localement actuellement (dependances Jest absentes au moment de l'audit).
5. **Documentation existante partiellement obsolete** par rapport au runtime online deploye.

---

## 7. Plan de Route Recommande (court -> moyen terme)

## Semaine 1-2

1. Fixer le referentiel regles "Rami Tunisien cible" (document fonctionnel unique).
2. Aligner `shared` sur ces regles (ouverture multi-meld, As haut/bas, +100, doublon defausse, keep-1-card, joker strict).
3. Ajouter tests de non-regression croises (shared vs dart).

## Semaine 3-4

1. Aligner le client Flutter online avec protocole Nest/shared.
2. Basculer le deployment online vers `server/` (ou garder simple-server mais en miroir exact des regles shared).
3. Retirer les chemins legacy incompatibles.

## Semaine 5+

1. Reconnexion + reprise de game.
2. Persistance complete des parties.
3. Classement/statistiques.
4. Monitoring + alerting.

---

## 8. Sources Code Auditees (principales)

- `mobile/lib/engine/game_engine.dart`
- `mobile/lib/engine/meld_validator.dart`
- `mobile/lib/providers/game_provider.dart`
- `mobile/lib/services/socket_service.dart`
- `mobile/lib/screens/game/game_table_screen.dart`
- `simple-server/server.js`
- `shared/src/engine/*`
- `shared/src/types/*`
- `server/src/game/*`
- `server/src/auth/*`
- `render.yaml` et scripts de lancement `start-server*`, `LANCER-*`

---

## 9. Note Finale

Le projet a une base solide et deja riche en gameplay.  
Le principal travail pour obtenir un "vrai rami tunisien parfait" n'est pas d'ajouter des ecrans, mais de **supprimer les divergences** :

- un seul moteur regles,
- un seul protocole online,
- une seule interpretation officielle des regles.

