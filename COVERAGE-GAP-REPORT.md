# COVERAGE & GAP REPORT — Rami Tunisien QA

Generated: 2026-03-08 | Test suite: 148 passing, 12 suites (shared/ engine)

---

## 1. BUSINESS RULES — TEST COVERAGE MATRIX

| # | Business Rule | shared/ tests | Dart offline | simple-server | NestJS server | Status |
|---|--------------|:---:|:---:|:---:|:---:|--------|
| R1 | Deck: 2×52 + 4 jokers = 108 cards | ✅ 9 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R2 | Deal: 14 cards/player, first player gets 15 | ✅ 3 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R3 | Set: 3-4 same rank, different suits | ✅ 9 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R4 | Run: ≥3 consecutive, same suit | ✅ 9 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R5 | Ace low (A-2-3) in runs | ✅ 2 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R6 | **Ace high (Q-K-A) in runs** | ⚠️ 1 test (XFAIL) | ✅ impl | ❌ missing | delegates | **DIVERGENT** |
| R7 | K-A-2 wrap NOT valid | ✅ 1 test | ✅ impl | ✅ impl | delegates | COVERED |
| R8 | Max 1 joker per meld (configurable) | ✅ 2 tests | ⚠️ maxJokersPerMeld=99 | ❌ no limit | delegates | **DIVERGENT** |
| R9 | Opening threshold ≥ 71 points | ✅ 6 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R10 | Opening requires ≥1 clean run | ✅ 4 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R11 | Batch opening (staging + confirm) | ✅ 6 tests | ✅ meldBatch | ✅ staged | delegates | COVERED |
| R12 | Cancel staging | ✅ 1 test | N/A (batch) | ✅ impl | delegates | COVERED |
| R13 | Keep-1-card rule | ✅ 4 tests | ✅ impl | ❌ missing | delegates | **DIVERGENT** |
| R14 | +100 penalty (discard draw w/o opening) | ✅ 3 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R15 | Duplicate protection on discard draw | ✅ 4 tests | ✅ impl | ❌ missing | delegates | **DIVERGENT** |
| R16 | Joker recovery in runs | ✅ 2 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R17 | **Joker recovery in sets (carré only)** | ❌ no test | ✅ impl (Dart) | ❌ missing | delegates | **MISSING** |
| R18 | jokerLocked config guard | ✅ 1 test | ⚠️ field exists | ❌ missing | delegates | PARTIAL |
| R19 | Layoff: add to run start/end | ✅ 5 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R20 | Layoff: add to set (max 4) | ✅ 2 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R21 | First player rotation per round | ✅ 3 tests | ✅ impl | ❌ no rotation | delegates | **DIVERGENT** |
| R22 | Card points: 2-10=face, J/Q/K=10, A=11, JK=30 | ✅ 10 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R23 | Round scoring: winner=0, losers=hand penalty | ✅ 2 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R24 | Game end: max rounds, lowest total wins | ✅ 1 test | ✅ impl | ❌ no multi-round | delegates | **DIVERGENT** |
| R25 | Game end: elimination mode | ✅ 1 test | ✅ impl | ❌ missing | delegates | **DIVERGENT** |
| R26 | **Frich vote (unanimous reshuffle)** | ❌ no test | ✅ impl | ❌ missing | ❌ missing | **MISSING** |
| R27 | Draw pile reshuffle when empty | ⚠️ implied in turn.ts | ✅ impl | ✅ impl | delegates | PARTIAL |
| R28 | Turn flow: draw → play → discard | ✅ 6 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R29 | Turn step enforcement | ✅ 4 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R30 | Wrong player blocked | ✅ 2 tests | ✅ impl | ✅ impl | delegates | COVERED |
| R31 | State sanitization (hide opponent hands) | ✅ 1 test | N/A (online view) | ✅ getPlayerView | ✅ sanitize | COVERED |
| R32 | Bot AI: valid actions only | ✅ 4 tests | ✅ impl | N/A | N/A | COVERED |
| R33 | Card conservation invariant | ✅ 4 tests | N/A | N/A | N/A | COVERED |
| R34 | Immutability on error | ✅ 2 tests | N/A | N/A | N/A | COVERED |
| R35 | **Meld points for opening (Ace=1 low, Ace=11 high in run)** | ❌ no test | ✅ impl | ⚠️ Ace=1 only | delegates | **MISSING** |
| R36 | **Auto-play on timeout** | ❌ no test | ✅ impl | ❌ missing | ❌ missing | **MISSING** |
| R37 | **Smart bot draw (check discard usefulness)** | ❌ no test | ✅ impl | N/A | N/A | **MISSING** |

---

## 2. RULES STILL MISSING TEST COVERAGE

| Priority | Rule | Engines affected | Risk |
|----------|------|-----------------|------|
| **P0** | Ace-high run (Q-K-A) — engine fix needed | shared/ returns false | Players can't form Q-K-A runs online |
| **P0** | Joker recovery in sets with carré rule | shared/ missing impl | Joker swap in sets behaves differently online vs offline |
| **P1** | Frich vote (reshuffle) | shared/ + simple-server missing | Missing game phase entirely |
| **P1** | Meld points aware of Ace dual value | shared/ always uses aceHighValue=11 | Opening calc may differ from Dart |
| **P2** | Draw pile reshuffle edge case | No explicit test | Game freezes if pile exhausted |
| **P2** | Auto-play on timeout | Not in shared/ or simple-server | Human players can stall the game |
| **P2** | Smart bot discard draw evaluation | Bot always draws from deck | Suboptimal bot play |
| **P3** | Layoff auto-position detection | Dart has layoffAuto, shared/ requires explicit position | UX gap |
| **P3** | Run auto-sorting after meld/layoff | Dart sorts runs, shared/ preserves insertion order | Display inconsistency |

---

## 3. ENGINE DIVERGENCE MATRIX

| Feature | shared/ (TS) | simple-server (JS) | Dart offline | NestJS server |
|---------|:---:|:---:|:---:|:---:|
| Card ID start | 0 | **1** | 0 | delegates(0) |
| Ace in runs | low only | low only | **low + high** | delegates |
| maxJokersPerMeld | 1 (default) | **unlimited** | **99** (default) | delegates(1) |
| Batch opening | staged→confirm | staged→confirm | **meldBatch** (atomic) | delegates |
| Keep-1-card | ✅ enforced | **❌ not enforced** | ✅ enforced | delegates |
| Duplicate protection | ✅ enforced | **❌ missing** | ✅ enforced | delegates |
| +100 discard penalty | ✅ | ✅ | ✅ | delegates |
| First player rotation | ✅ round%n | **❌ always 0** | ✅ round%n | delegates |
| Multi-round | ✅ | **❌ round_end only** | ✅ | delegates |
| Elimination mode | ✅ | **❌ missing** | ✅ | delegates |
| Frich vote | ❌ | ❌ | **✅** | ❌ |
| Joker set recovery (carré) | ❌ | ❌ | **✅** | delegates(❌) |
| Ace meld point value | 11 always | 1 always | **1 or 11** (context) | delegates(11) |
| Action: draw | draw_from_deck | **draw_deck** | **draw_deck** | delegates |
| Action: discard draw | draw_from_discard | **draw_discard** | **draw_discard** | delegates |
| Suit format | enum Hearts | **string 'hearts'** | enum hearts | delegates |
| Rank format | enum (1-13) | **string 'A','2'...'K'** | enum (1-13) | delegates |
| State mutation | immutable | **mutable** | **mutable** | immutable |
| Room code length | N/A | 5 chars | N/A | **6 chars** |
| Auth | N/A | register event | N/A | **JWT + bcrypt** |
| WebSocket namespace | N/A | `/game` | connects to `/game` | `/game` |

---

## 4. PROTOCOL MISMATCHES

### 4a. Action Type Name Mismatches

| Action | Flutter client sends | simple-server expects | shared/ expects | NestJS expects |
|--------|---------------------|----------------------|----------------|---------------|
| Draw deck | `draw_deck` | `draw_deck` ✅ | **`draw_from_deck`** ❌ | **`draw_from_deck`** ❌ |
| Draw discard | `draw_discard` | `draw_discard` ✅ | **`draw_from_discard`** ❌ | **`draw_from_discard`** ❌ |
| Meld | `meld` | `meld` ✅ | `meld` ✅ | `meld` ✅ |
| Confirm opening | `confirm_opening` | `confirm_opening` ✅ | `confirm_opening` ✅ | `confirm_opening` ✅ |
| Cancel staging | `cancel_staging` | `cancel_staging` ✅ | `cancel_staging` ✅ | `cancel_staging` ✅ |
| Layoff | `layoff` | `layoff` ✅ | `layoff` ✅ | `layoff` ✅ |
| Replace joker | `replace_joker`(?) | joker swap inline | `replace_joker` ✅ | `replace_joker` ✅ |
| Discard | `discard` | `discard` ✅ | `discard` ✅ | `discard` ✅ |

**CRITICAL**: If Flutter client connects to NestJS server, `draw_deck`/`draw_discard` actions will fail because shared/ expects `draw_from_deck`/`draw_from_discard`.

### 4b. Event Name Mismatches

| Event | simple-server emits | NestJS emits | Flutter listens for |
|-------|-------------------|-------------|-------------------|
| Room created | `room_created` | `room_created` | `room_created` ✅ |
| Game state | `game_state_update` | `game_state_update` | `game_state_update` ✅ |
| Meld staged | `meld_staged` | ❌ (inside state update) | `meld_staged` ⚠️ |
| Staging cancelled | `staging_cancelled` | ❌ (inside state update) | `staging_cancelled` ⚠️ |
| Round end | `round_end` | `round_end` | `round_end` ✅ |
| Game end | ❌ (inside round_end) | `game_end` | `game_end` ⚠️ |
| Matchmaking | ❌ missing | `matchmaking_waiting` | `matchmaking_waiting` ⚠️ |
| Resign | ❌ missing | `resign` | N/A |

### 4c. Payload Shape Mismatches

| Field | simple-server sends | NestJS/shared sends | Flutter expects |
|-------|-------------------|-------------------|----------------|
| Suit | `'hearts'` (string) | `'hearts'` (enum→string) | Maps both ✅ |
| Rank | `'A','2','K'` (string) | `1,2,13` (enum int) | Maps both via `fromJson` ✅ |
| Card ID | starts at **1** | starts at **0** | Accepts any int ✅ |
| Hand | `myHand` (array) | `myHand` (in sanitized) | `myHand` ✅ |
| Others' hands | `handCount` | `handCount` | `handCount` ✅ |
| Discard pile | last 5 only | full pile | Expects full? ⚠️ |
| Player fields | `openingScore` | no `openingScore` | reads `openingScore` ⚠️ |

---

## 5. HIGH-RISK SCENARIOS NOT YET TESTED

| # | Scenario | Risk Level | Why |
|---|----------|-----------|-----|
| H1 | Draw pile exhaustion + reshuffle mid-game | HIGH | Game freeze if reshuffle fails |
| H2 | Q-K-A meld attempt in online mode | HIGH | Rejected by server but valid per rules |
| H3 | Joker swap in a set (online) | HIGH | No carré check → joker stuck in set |
| H4 | 4-player game, round 5 rotation | MED | Rotation logic untested with max players+rounds |
| H5 | Player disconnects mid-turn | HIGH | State may corrupt or stall |
| H6 | Rapid action spam (double-tap discard) | MED | Duplicate discard → state corruption |
| H7 | Meld with all jokers | MED | Edge case in validation |
| H8 | Opening exactly at 71 points (boundary) | MED | Off-by-one in threshold check |
| H9 | Multiple rounds with cumulative scoring | MED | Score accumulation across rounds |
| H10 | Elimination: last 2 players, one eliminated | MED | Game end via elimination |
| H11 | Full game to completion (5 rounds) | HIGH | Integration test: no test covers full game |
| H12 | Flutter online → simple-server state sync | HIGH | Protocol mismatches may cause desync |
| H13 | Concurrent room actions (join while starting) | MED | Race condition |
| H14 | Bot vs human mixed game | LOW | Bot logic correctness |

---

## 6. PRIORITY FIX PLAN

| Priority | Fix | Phase |
|----------|-----|-------|
| **P0** | Fix Ace-high run (Q-K-A) in shared/ `isValidRun()` | Step 2 |
| **P0** | Add action type aliases in shared/ (accept `draw_deck` + `draw_from_deck`) | Step 3 |
| **P1** | Add joker set recovery (carré rule) to shared/ | Step 2 |
| **P1** | Add keep-1-card rule to simple-server | Step 2 |
| **P1** | Add duplicate protection to simple-server | Step 2 |
| **P1** | Add first player rotation to simple-server | Step 2 |
| **P2** | Add Frich vote to shared/ | Deferred |
| **P2** | Add draw pile reshuffle test | Step 2 |
| **P2** | Harmonize meld point calculation for Ace | Step 2 |
| **P3** | Add run auto-sorting to shared/ | Deferred |
| **P3** | Add `openingScore` to shared/ player | Step 3 |
