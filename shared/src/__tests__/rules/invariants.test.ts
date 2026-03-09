/**
 * Invariant tests: properties that must ALWAYS hold regardless of game state.
 * These are fuzz-style tests that verify structural guarantees.
 */
import { createGame, startRound, applyAction, getValidActions } from '../../engine/game-machine';
import { GamePhase, TurnStep } from '../../types/game-state';
import { Card } from '../../types/card';
import { DEFAULT_CONFIG } from '../../types/game-config';

// ─── Card conservation: total cards never change ──────────

function countAllCards(state: ReturnType<typeof createGame>): number {
  let total = 0;
  total += state.drawPile.length;
  total += state.discardPile.length;
  for (const p of state.players) {
    total += p.hand.length;
  }
  for (const m of state.tableMelds) {
    total += m.cards.length;
  }
  return total;
}

function getAllCardIds(state: ReturnType<typeof createGame>): number[] {
  const ids: number[] = [];
  ids.push(...state.drawPile.map(c => c.id));
  ids.push(...state.discardPile.map(c => c.id));
  for (const p of state.players) {
    ids.push(...p.hand.map(c => c.id));
  }
  for (const m of state.tableMelds) {
    ids.push(...m.cards.map(c => c.id));
  }
  return ids;
}

describe('Invariants', () => {
  describe('Card Conservation', () => {
    test('total card count is constant after startRound', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
      ]);
      state = startRound(state, 123);
      const initialCount = countAllCards(state);

      // Expected: 2 decks × 52 + 4 jokers = 108
      expect(initialCount).toBe(108);
    });

    test('card count preserved through draw/discard cycle', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
      ]);
      state = startRound(state, 42);
      const initialCount = countAllCards(state);

      // P1 discards
      state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });
      expect(countAllCards(state)).toBe(initialCount);

      // P2 draws from deck
      state = applyAction(state, { type: 'draw_from_deck', playerId: 'p2' });
      expect(countAllCards(state)).toBe(initialCount);

      // P2 discards
      state = applyAction(state, { type: 'discard', playerId: 'p2', cardId: state.players[1].hand[0].id });
      expect(countAllCards(state)).toBe(initialCount);
    });

    test('card count preserved through draw from discard', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
      ]);
      state = startRound(state, 42);
      const initialCount = countAllCards(state);

      // P1 discards to create a discard pile
      state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });

      // P2 draws from discard
      state = applyAction(state, { type: 'draw_from_discard', playerId: 'p2' });
      expect(countAllCards(state)).toBe(initialCount);
    });

    test('no duplicate card IDs exist at any point', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
      ]);
      state = startRound(state, 42);

      const ids = getAllCardIds(state);
      const uniqueIds = new Set(ids);
      expect(uniqueIds.size).toBe(ids.length);
    });
  });

  describe('Turn Order', () => {
    test('currentPlayerIndex always valid', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
        { id: 'p3', name: 'C', isBot: false },
      ]);
      state = startRound(state, 42);

      expect(state.currentPlayerIndex).toBeGreaterThanOrEqual(0);
      expect(state.currentPlayerIndex).toBeLessThan(3);

      // After P1 discards
      state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });
      expect(state.currentPlayerIndex).toBeGreaterThanOrEqual(0);
      expect(state.currentPlayerIndex).toBeLessThan(3);
    });

    test('turn alternates between draw and play steps', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
      ]);
      state = startRound(state, 42);

      // First player starts at Play (15 cards)
      expect(state.turnStep).toBe(TurnStep.Play);

      // After discard → next player at Draw
      state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });
      expect(state.turnStep).toBe(TurnStep.Draw);

      // After draw → Play
      state = applyAction(state, { type: 'draw_from_deck', playerId: 'p2' });
      expect(state.turnStep).toBe(TurnStep.Play);
    });
  });

  describe('Rejected Actions = No State Change', () => {
    test('wrong player action does not mutate state', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
      ]);
      state = startRound(state, 42);
      const snapshot = JSON.parse(JSON.stringify(state));

      try {
        applyAction(state, { type: 'discard', playerId: 'p2', cardId: 0 });
      } catch {
        // expected
      }

      expect(state).toEqual(snapshot);
    });

    test('invalid draw step action does not mutate state', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
      ]);
      state = startRound(state, 42);
      const snapshot = JSON.parse(JSON.stringify(state));

      try {
        applyAction(state, { type: 'draw_from_deck', playerId: 'p1' });
      } catch {
        // expected - P1 is at Play step, not Draw
      }

      expect(state).toEqual(snapshot);
    });
  });

  describe('Score Consistency', () => {
    test('winner always has score 0 at round end', () => {
      let state = createGame([
        { id: 'p1', name: 'A', isBot: false },
        { id: 'p2', name: 'B', isBot: false },
      ]);
      state = startRound(state, 42);

      // Play multiple turns until we can simulate a win
      // For this test, manually construct a near-win state
      const { makePlayer, card, makeGameState } = require('../helpers');
      const { Suit, Rank } = require('../../types/card');

      const winState = makeGameState({
        players: [
          makePlayer({
            id: 'p1',
            hand: [card(Rank.Two, Suit.Hearts, 1)],
            hasOpened: true,
          }),
          makePlayer({
            id: 'p2',
            hand: [card(Rank.King, Suit.Spades, 10), card(Rank.Queen, Suit.Diamonds, 11)],
          }),
        ],
        currentPlayerIndex: 0,
        turnStep: TurnStep.Play,
        drawPile: [card(Rank.Three, Suit.Clubs, 20)],
      });

      const endState = applyAction(winState, { type: 'discard', playerId: 'p1', cardId: 1 });
      expect(endState.winnerId).toBe('p1');
      expect(endState.players.find((p: any) => p.id === 'p1')!.score).toBe(0);
    });

    test('losers always have score > 0 at round end (unless hand is empty)', () => {
      const { makePlayer, card, makeGameState } = require('../helpers');
      const { Suit, Rank } = require('../../types/card');

      const state = makeGameState({
        players: [
          makePlayer({
            id: 'p1',
            hand: [card(Rank.Two, Suit.Hearts, 1)],
            hasOpened: true,
          }),
          makePlayer({
            id: 'p2',
            hand: [card(Rank.King, Suit.Spades, 10)],
          }),
        ],
        currentPlayerIndex: 0,
        turnStep: TurnStep.Play,
        drawPile: [card(Rank.Three, Suit.Clubs, 20)],
      });

      const endState = applyAction(state, { type: 'discard', playerId: 'p1', cardId: 1 });
      const loser = endState.players.find((p: any) => p.id === 'p2')!;
      expect(loser.hand.length).toBeGreaterThan(0);
      expect(loser.score).toBeGreaterThan(0);
    });
  });

  describe('Multi-turn Fuzz', () => {
    test('10 random games of 50 turns each maintain invariants', () => {
      for (let gameIdx = 0; gameIdx < 10; gameIdx++) {
        let state = createGame([
          { id: 'p1', name: 'A', isBot: false },
          { id: 'p2', name: 'B', isBot: false },
        ]);
        state = startRound(state, gameIdx * 7 + 1);
        const expectedCardCount = countAllCards(state);

        for (let turn = 0; turn < 50; turn++) {
          if (state.phase !== GamePhase.PlayerTurn) break;

          const currentPlayer = state.players[state.currentPlayerIndex];
          const validActions = getValidActions(state);

          if (validActions.length === 0) break;

          try {
            if (state.turnStep === TurnStep.Play) {
              // Discard first card in hand
              state = applyAction(state, {
                type: 'discard',
                playerId: currentPlayer.id,
                cardId: currentPlayer.hand[0].id,
              });
            } else if (state.turnStep === TurnStep.Draw) {
              // Draw from deck
              state = applyAction(state, {
                type: 'draw_from_deck',
                playerId: currentPlayer.id,
              });
            }
          } catch {
            // Some actions might fail (e.g., empty deck), skip
            break;
          }

          // Invariant checks after every action
          expect(countAllCards(state)).toBe(expectedCardCount);
          if (state.phase === GamePhase.PlayerTurn) {
            expect(state.currentPlayerIndex).toBeGreaterThanOrEqual(0);
            expect(state.currentPlayerIndex).toBeLessThan(state.players.length);
          }
        }
      }
    });
  });
});
