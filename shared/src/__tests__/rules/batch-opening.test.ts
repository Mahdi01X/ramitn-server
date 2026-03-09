import { createGame, startRound, applyAction, getValidActions } from '../../engine/game-machine';
import { GamePhase, TurnStep } from '../../types/game-state';
import { card, joker, makePlayer, makeGameState, makeRun, makeSet } from '../helpers';
import { Suit, Rank } from '../../types/card';
import { MeldType } from '../../types/meld';
import { DEFAULT_CONFIG } from '../../types/game-config';

describe('Batch Opening (Multi-Meld)', () => {
  test('staging a meld before opening does NOT remove cards from hand', () => {
    const hand = [
      card(Rank.Ten, Suit.Hearts, 10),
      card(Rank.Jack, Suit.Hearts, 11),
      card(Rank.Queen, Suit.Hearts, 12),
      card(Rank.King, Suit.Hearts, 13),
      card(Rank.Ace, Suit.Spades, 14),
      card(Rank.Ace, Suit.Diamonds, 15),
      card(Rank.Ace, Suit.Clubs, 16),
      card(Rank.Five, Suit.Clubs, 17),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Hearts, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    // Stage first meld
    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [10, 11, 12, 13] });

    // Cards should still be in hand (only staged, not committed)
    expect(state.players[0].hand).toHaveLength(8);
    expect(state.players[0].stagedMelds).toHaveLength(1);
    expect(state.players[0].hasOpened).toBe(false);
  });

  test('confirm_opening commits all staged melds and removes cards', () => {
    const hand = [
      card(Rank.Ten, Suit.Hearts, 10),
      card(Rank.Jack, Suit.Hearts, 11),
      card(Rank.Queen, Suit.Hearts, 12),
      card(Rank.King, Suit.Hearts, 13),
      card(Rank.Ace, Suit.Spades, 14),
      card(Rank.Ace, Suit.Diamonds, 15),
      card(Rank.Ace, Suit.Clubs, 16),
      card(Rank.Five, Suit.Clubs, 17),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Hearts, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    // Stage two melds
    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [10, 11, 12, 13] });
    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [14, 15, 16] });

    // Confirm opening
    state = applyAction(state, { type: 'confirm_opening', playerId: 'p1' });

    expect(state.players[0].hasOpened).toBe(true);
    expect(state.players[0].stagedMelds).toHaveLength(0);
    expect(state.players[0].hand).toHaveLength(1); // only card 17 left
    expect(state.tableMelds).toHaveLength(2);
  });

  test('confirm_opening fails if total points < 71', () => {
    const hand = [
      card(Rank.Two, Suit.Hearts, 10),
      card(Rank.Three, Suit.Hearts, 11),
      card(Rank.Four, Suit.Hearts, 12),
      card(Rank.Five, Suit.Spades, 13),
      card(Rank.Six, Suit.Clubs, 14),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    // Stage a small meld (2+3+4 = 9 points)
    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [10, 11, 12] });

    // Confirm should fail
    expect(() =>
      applyAction(state, { type: 'confirm_opening', playerId: 'p1' }),
    ).toThrow('points pour ouvrir');
  });

  test('confirm_opening fails if no clean run', () => {
    const hand = [
      card(Rank.Ten, Suit.Hearts, 10),
      joker(99),
      card(Rank.Queen, Suit.Hearts, 12),
      card(Rank.King, Suit.Hearts, 13),
      card(Rank.Ace, Suit.Spades, 14),
      card(Rank.Ace, Suit.Diamonds, 15),
      card(Rank.Ace, Suit.Clubs, 16),
      card(Rank.Five, Suit.Clubs, 17),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    // Stage run with joker (not clean): 10-JK-Q-K = 40pts, and set of Aces = 33pts, total=73 >= 71
    // But no clean run → should fail
    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [10, 99, 12, 13] });
    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [14, 15, 16] });

    expect(() =>
      applyAction(state, { type: 'confirm_opening', playerId: 'p1' }),
    ).toThrow('suite sans joker');
  });

  test('cancel_staging clears all staged melds', () => {
    const hand = [
      card(Rank.Ten, Suit.Hearts, 10),
      card(Rank.Jack, Suit.Hearts, 11),
      card(Rank.Queen, Suit.Hearts, 12),
      card(Rank.Five, Suit.Clubs, 17),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [10, 11, 12] });
    expect(state.players[0].stagedMelds).toHaveLength(1);

    state = applyAction(state, { type: 'cancel_staging', playerId: 'p1' });
    expect(state.players[0].stagedMelds).toHaveLength(0);
    expect(state.players[0].hand).toHaveLength(4); // cards still in hand
  });

  test('getValidActions includes confirm_opening and cancel_staging when melds staged', () => {
    const hand = [
      card(Rank.Ten, Suit.Hearts, 10),
      card(Rank.Jack, Suit.Hearts, 11),
      card(Rank.Queen, Suit.Hearts, 12),
      card(Rank.Five, Suit.Clubs, 17),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    // Before staging, no confirm/cancel
    let actions = getValidActions(state);
    expect(actions).not.toContain('confirm_opening');

    // After staging
    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [10, 11, 12] });
    actions = getValidActions(state);
    expect(actions).toContain('confirm_opening');
    expect(actions).toContain('cancel_staging');
  });
});

describe('Keep-1-Card Rule', () => {
  test('cannot stage melds that would leave 0 cards for discard', () => {
    const hand = [
      card(Rank.Ten, Suit.Hearts, 10),
      card(Rank.Jack, Suit.Hearts, 11),
      card(Rank.Queen, Suit.Hearts, 12),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    // Staging all 3 cards leaves 0 → should fail
    expect(() =>
      applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [10, 11, 12] }),
    ).toThrow('must keep at least 1 card');
  });

  test('can stage melds that leave exactly 1 card', () => {
    const hand = [
      card(Rank.Ten, Suit.Hearts, 10),
      card(Rank.Jack, Suit.Hearts, 11),
      card(Rank.Queen, Suit.Hearts, 12),
      card(Rank.Five, Suit.Clubs, 17),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    // 3 cards staged, 1 left → OK
    state = applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [10, 11, 12] });
    expect(state.players[0].stagedMelds).toHaveLength(1);
  });

  test('post-opening meld cannot leave 0 cards', () => {
    const hand = [
      card(Rank.Two, Suit.Hearts, 1),
      card(Rank.Three, Suit.Hearts, 2),
      card(Rank.Four, Suit.Hearts, 3),
    ];

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [...hand], hasOpened: true }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
    });

    expect(() =>
      applyAction(state, { type: 'meld', playerId: 'p1', cardIds: [1, 2, 3] }),
    ).toThrow('must keep at least 1 card');
  });

  test('layoff cannot leave 0 cards', () => {
    const existingMeld = makeRun([
      card(Rank.Five, Suit.Hearts, 50),
      card(Rank.Six, Suit.Hearts, 51),
      card(Rank.Seven, Suit.Hearts, 52),
    ]);

    let state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [card(Rank.Eight, Suit.Hearts, 1)], hasOpened: true }),
        makePlayer({ id: 'p2', hand: [card(Rank.Two, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
      tableMelds: [existingMeld],
    });

    // Only 1 card left, layoff would leave 0 → should fail
    expect(() =>
      applyAction(state, {
        type: 'layoff',
        playerId: 'p1',
        cardId: 1,
        targetMeldId: existingMeld.id,
        position: 'end',
      }),
    ).toThrow('must keep at least 1 card');
  });
});

describe('First Player Rotation', () => {
  test('round 1: player 0 starts', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
      { id: 'p3', name: 'Charlie', isBot: false },
    ]);
    state = startRound(state, 42);
    expect(state.currentPlayerIndex).toBe(0);
    expect(state.players[0].hand).toHaveLength(15);
    expect(state.players[1].hand).toHaveLength(14);
  });

  test('round 2: player 1 starts (after manual round increment)', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
      { id: 'p3', name: 'Charlie', isBot: false },
    ]);
    // Simulate that we already did round 1
    state = { ...state, round: 1 };
    state = startRound(state, 42);
    expect(state.round).toBe(2);
    expect(state.currentPlayerIndex).toBe(1);
    expect(state.players[1].hand).toHaveLength(15);
    expect(state.players[0].hand).toHaveLength(14);
  });

  test('round 4 with 3 players: player 0 starts again (wraps)', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
      { id: 'p3', name: 'Charlie', isBot: false },
    ]);
    state = { ...state, round: 3 };
    state = startRound(state, 42);
    expect(state.round).toBe(4);
    expect(state.currentPlayerIndex).toBe(0); // 3 % 3 = 0
  });
});
