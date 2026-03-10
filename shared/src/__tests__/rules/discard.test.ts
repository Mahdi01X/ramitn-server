import { createGame, startRound, applyAction } from '../../engine/game-machine';
import { GamePhase, TurnStep } from '../../types/game-state';
import { card, joker, makePlayer, makeGameState } from '../helpers';
import { Suit, Rank } from '../../types/card';
import { DEFAULT_CONFIG } from '../../types/game-config';

describe('Discard Draw Penalty (+100)', () => {
  test('drawing from discard without opening gives +100 penalty on discard', () => {
    const p1Hand = [
      card(Rank.Two, Suit.Hearts, 1),
      card(Rank.Three, Suit.Hearts, 2),
      card(Rank.Four, Suit.Hearts, 3),
      card(Rank.Five, Suit.Spades, 4),
    ];
    const p2Hand = [
      card(Rank.Six, Suit.Clubs, 10),
      card(Rank.Seven, Suit.Clubs, 11),
      card(Rank.Eight, Suit.Clubs, 12),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...p1Hand] }),
        makePlayer({ id: 'p2', hand: [...p2Hand] }),
      ],
      currentPlayerIndex: 1,
      turnStep: TurnStep.Draw,
      discardPile: [card(Rank.Nine, Suit.Diamonds, 20)],
      drawPile: [card(Rank.Ten, Suit.Diamonds, 21)],
    });

    // P2 draws from discard
    state = applyAction(state, { type: 'draw_from_discard', playerId: 'p2' });
    expect(state.players[1].drewFromDiscard).toBe(true);

    // P2 discards without opening → should get penalty
    state = applyAction(state, { type: 'discard', playerId: 'p2', cardId: 20 });

    // P2 should have +100 penalty accumulated in score (added to totalScore at round end)
    expect(state.players[1].score).toBe(100);
    // Round should NOT have ended — game continues
    expect(state.phase).toBe(GamePhase.PlayerTurn);
  });

  test('drawing from discard with opening gives NO penalty', () => {
    // Create a hand that satisfies opening (71+ with clean run)
    const p1Hand = [
      card(Rank.Two, Suit.Hearts, 1),
      card(Rank.Five, Suit.Spades, 4),
    ];
    const p2Hand = [
      card(Rank.Ten, Suit.Hearts, 10),
      card(Rank.Jack, Suit.Hearts, 11),
      card(Rank.Queen, Suit.Hearts, 12),
      card(Rank.King, Suit.Hearts, 13),
      card(Rank.Ace, Suit.Spades, 14),
      card(Rank.Ace, Suit.Diamonds, 15),
      card(Rank.Ace, Suit.Clubs, 16),
      card(Rank.Five, Suit.Clubs, 17), // card to discard
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...p1Hand] }),
        makePlayer({ id: 'p2', hand: [...p2Hand] }),
      ],
      currentPlayerIndex: 1,
      turnStep: TurnStep.Draw,
      discardPile: [card(Rank.Nine, Suit.Diamonds, 20)],
      drawPile: [card(Rank.Eight, Suit.Diamonds, 21)],
    });

    // P2 draws from discard
    state = applyAction(state, { type: 'draw_from_discard', playerId: 'p2' });
    expect(state.players[1].drewFromDiscard).toBe(true);

    // P2 stages melds for opening: 10-J-Q-K hearts (40pts) + A-A-A (33pts) = 73pts
    state = applyAction(state, { type: 'meld', playerId: 'p2', cardIds: [10, 11, 12, 13] });
    state = applyAction(state, { type: 'meld', playerId: 'p2', cardIds: [14, 15, 16] });
    state = applyAction(state, { type: 'confirm_opening', playerId: 'p2' });

    // P2 opened → no penalty should apply on discard
    state = applyAction(state, { type: 'discard', playerId: 'p2', cardId: 17 });
    expect(state.players[1].totalScore).toBe(0);
  });

  test('drawing from deck gives NO penalty even without opening', () => {
    const p1Hand = [
      card(Rank.Two, Suit.Hearts, 1),
      card(Rank.Five, Suit.Spades, 4),
    ];
    const p2Hand = [
      card(Rank.Six, Suit.Clubs, 10),
      card(Rank.Seven, Suit.Clubs, 11),
      card(Rank.Eight, Suit.Clubs, 12),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...p1Hand] }),
        makePlayer({ id: 'p2', hand: [...p2Hand] }),
      ],
      currentPlayerIndex: 1,
      turnStep: TurnStep.Draw,
      discardPile: [card(Rank.Nine, Suit.Diamonds, 20)],
      drawPile: [card(Rank.Ten, Suit.Diamonds, 21)],
    });

    // P2 draws from deck
    state = applyAction(state, { type: 'draw_from_deck', playerId: 'p2' });
    expect(state.players[1].drewFromDiscard).toBe(false);

    // P2 discards without opening → NO penalty (drew from deck)
    state = applyAction(state, { type: 'discard', playerId: 'p2', cardId: 10 });
    expect(state.players[1].totalScore).toBe(0);
  });
});

describe('Duplicate Protection on Discard Draw', () => {
  test('cannot draw from discard if hand has exact duplicate (same rank+suit)', () => {
    const state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [card(Rank.Seven, Suit.Hearts, 1), card(Rank.Two, Suit.Clubs, 2)] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 10)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Draw,
      discardPile: [card(Rank.Seven, Suit.Hearts, 20)], // same rank+suit as p1's card
      drawPile: [card(Rank.Eight, Suit.Diamonds, 21)],
    });

    expect(() =>
      applyAction(state, { type: 'draw_from_discard', playerId: 'p1' }),
    ).toThrow('Cannot draw from discard');
  });

  test('CAN draw from discard if same rank but different suit', () => {
    const state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [card(Rank.Seven, Suit.Hearts, 1), card(Rank.Two, Suit.Clubs, 2)] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 10)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Draw,
      discardPile: [card(Rank.Seven, Suit.Spades, 20)], // same rank but different suit
      drawPile: [card(Rank.Eight, Suit.Diamonds, 21)],
    });

    const newState = applyAction(state, { type: 'draw_from_discard', playerId: 'p1' });
    expect(newState.players[0].hand).toHaveLength(3);
  });

  test('duplicate protection can be disabled via config', () => {
    const state = makeGameState({
      config: { ...DEFAULT_CONFIG, duplicateProtection: false },
      players: [
        makePlayer({ id: 'p1', hand: [card(Rank.Seven, Suit.Hearts, 1), card(Rank.Two, Suit.Clubs, 2)] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 10)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Draw,
      discardPile: [card(Rank.Seven, Suit.Hearts, 20)],
      drawPile: [card(Rank.Eight, Suit.Diamonds, 21)],
    });

    // Should NOT throw with duplicate protection disabled
    const newState = applyAction(state, { type: 'draw_from_discard', playerId: 'p1' });
    expect(newState.players[0].hand).toHaveLength(3);
  });

  test('jokers are exempt from duplicate protection', () => {
    const state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [joker(1), card(Rank.Two, Suit.Clubs, 2)] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 10)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Draw,
      discardPile: [joker(20)], // joker in discard, joker in hand
      drawPile: [card(Rank.Eight, Suit.Diamonds, 21)],
    });

    // Jokers should be exempt
    const newState = applyAction(state, { type: 'draw_from_discard', playerId: 'p1' });
    expect(newState.players[0].hand).toHaveLength(3);
  });
});
