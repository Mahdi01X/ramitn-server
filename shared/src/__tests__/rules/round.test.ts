import { createGame, startRound, applyAction } from '../../engine/game-machine';
import { GamePhase, TurnStep, GameError } from '../../types/game-state';
import { card, joker, makePlayer, makeGameState } from '../helpers';
import { Suit, Rank } from '../../types/card';
import { DEFAULT_CONFIG } from '../../types/game-config';

describe('Turn Flow', () => {
  test('first player starts at Play step with 15 cards', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
    ]);
    state = startRound(state, 42);

    expect(state.turnStep).toBe(TurnStep.Play);
    expect(state.players[0].hand).toHaveLength(15);
    expect(state.currentPlayerIndex).toBe(0);
  });

  test('after first player discards, second player is at Draw step', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
    ]);
    state = startRound(state, 42);

    const cardToDiscard = state.players[0].hand[0];
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: cardToDiscard.id });

    expect(state.currentPlayerIndex).toBe(1);
    expect(state.turnStep).toBe(TurnStep.Draw);
  });

  test('wrong player cannot act', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
    ]);
    state = startRound(state, 42);

    expect(() =>
      applyAction(state, { type: 'discard', playerId: 'p2', cardId: 0 }),
    ).toThrow();
  });

  test('cannot draw during play step', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
    ]);
    state = startRound(state, 42);

    expect(() =>
      applyAction(state, { type: 'draw_from_deck', playerId: 'p1' }),
    ).toThrow();
  });

  test('cannot discard during draw step', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
    ]);
    state = startRound(state, 42);

    // P1 discards → P2 at draw step
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });

    expect(() =>
      applyAction(state, { type: 'discard', playerId: 'p2', cardId: state.players[1].hand[0].id }),
    ).toThrow();
  });

  test('full turn cycle: P1 discard → P2 draw → P2 play/discard → P1 draw', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
    ]);
    state = startRound(state, 42);

    // P1 discards
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });
    expect(state.currentPlayerIndex).toBe(1);

    // P2 draws
    state = applyAction(state, { type: 'draw_from_deck', playerId: 'p2' });
    expect(state.turnStep).toBe(TurnStep.Play);

    // P2 discards
    state = applyAction(state, { type: 'discard', playerId: 'p2', cardId: state.players[1].hand[0].id });
    expect(state.currentPlayerIndex).toBe(0);
    expect(state.turnStep).toBe(TurnStep.Draw);
  });
});

describe('Round End', () => {
  test('player wins when hand is empty after discard', () => {
    let state = makeGameState({
      players: [
        makePlayer({
          id: 'p1',
          hand: [card(Rank.Two, Suit.Hearts, 1)],
          hasOpened: true,
        }),
        makePlayer({
          id: 'p2',
          hand: [card(Rank.King, Suit.Spades, 10), card(Rank.Ace, Suit.Diamonds, 11)],
          hasOpened: true, // opened but has remaining cards
        }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
      drawPile: [card(Rank.Three, Suit.Clubs, 20)],
    });

    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: 1 });

    expect(state.phase).toBe(GamePhase.RoundEnd);
    expect(state.winnerId).toBe('p1');
    // P2's score: K(10) + A(11) = 21
    expect(state.players[1].score).toBe(21);
    expect(state.players[0].score).toBe(0);
  });

  test('game ends after max rounds', () => {
    let state = makeGameState({
      config: { ...DEFAULT_CONFIG, maxRounds: 1 },
      round: 1,
      players: [
        makePlayer({
          id: 'p1',
          hand: [card(Rank.Two, Suit.Hearts, 1)],
          hasOpened: true,
          totalScore: 10,
        }),
        makePlayer({
          id: 'p2',
          hand: [card(Rank.King, Suit.Spades, 10)],
          totalScore: 50,
        }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
      drawPile: [card(Rank.Three, Suit.Clubs, 20)],
    });

    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: 1 });

    expect(state.phase).toBe(GamePhase.GameEnd);
    expect(state.winnerId).toBe('p1'); // lower total score
  });
});

describe('Error Handling', () => {
  test('action refused does not modify state', () => {
    let state = createGame([
      { id: 'p1', name: 'Alice', isBot: false },
      { id: 'p2', name: 'Bob', isBot: false },
    ]);
    state = startRound(state, 42);

    const stateBefore = JSON.stringify(state);

    try {
      applyAction(state, { type: 'draw_from_deck', playerId: 'p2' }); // wrong player
    } catch {
      // expected
    }

    // State should be unchanged
    expect(JSON.stringify(state)).toBe(stateBefore);
  });

  test('cannot act after game end', () => {
    const state = makeGameState({
      phase: GamePhase.GameEnd,
      players: [
        makePlayer({ id: 'p1', hand: [card(Rank.Two, Suit.Hearts, 1)] }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 10)] }),
      ],
    });

    expect(() =>
      applyAction(state, { type: 'discard', playerId: 'p1', cardId: 1 }),
    ).toThrow('Game has already ended');
  });
});
