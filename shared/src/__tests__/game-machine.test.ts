import { createGame, startRound, applyAction, getValidActions, sanitizeStateForPlayer } from '../engine/game-machine';
import { GamePhase, TurnStep } from '../types/game-state';
import { DEFAULT_CONFIG } from '../types/game-config';

const players = [
  { id: 'p1', name: 'Alice', isBot: false },
  { id: 'p2', name: 'Bob', isBot: false },
];

describe('Game Machine', () => {
  test('createGame initializes correct state', () => {
    const state = createGame(players);
    expect(state.phase).toBe(GamePhase.Waiting);
    expect(state.players).toHaveLength(2);
    expect(state.players[0].name).toBe('Alice');
    expect(state.players[1].name).toBe('Bob');
    expect(state.round).toBe(0);
  });

  test('startRound: P1 gets 15 cards, P2 gets 14, starts at Play', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    expect(state.phase).toBe(GamePhase.PlayerTurn);
    expect(state.round).toBe(1);
    expect(state.players[0].hand).toHaveLength(15); // First player gets extra card
    expect(state.players[1].hand).toHaveLength(14);
    expect(state.discardPile).toHaveLength(0); // No initial discard
    expect(state.turnStep).toBe(TurnStep.Play); // Must discard first
    expect(state.drawPile.length).toBe(108 - 29); // 108 - 14 - 14 - 1 extra
  });

  test('P1 discards first (has 15 cards), then P2 draws', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // P1 starts at Play step with 15 cards — must discard
    expect(state.turnStep).toBe(TurnStep.Play);
    const cardToDiscard = state.players[0].hand[0];
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: cardToDiscard.id });

    // Turn advances to P2
    expect(state.currentPlayerIndex).toBe(1);
    expect(state.turnStep).toBe(TurnStep.Draw);
    expect(state.players[0].hand).toHaveLength(14);
    expect(state.discardPile).toHaveLength(1);

    // P2 draws from deck
    state = applyAction(state, { type: 'draw_from_deck', playerId: 'p2' });
    expect(state.players[1].hand).toHaveLength(15);
    expect(state.turnStep).toBe(TurnStep.Play);
  });

  test('P2 can draw from discard after P1 discards', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    const discardedCard = state.players[0].hand[0];
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: discardedCard.id });

    // P2 draws from discard
    state = applyAction(state, { type: 'draw_from_discard', playerId: 'p2' });
    expect(state.players[1].hand).toHaveLength(15);
    expect(state.players[1].hand.some(c => c.id === discardedCard.id)).toBe(true);
    expect(state.discardPile).toHaveLength(0);
  });

  test('wrong player cannot act', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // P2 tries to act on P1's turn
    expect(() =>
      applyAction(state, { type: 'discard', playerId: 'p2', cardId: 0 }),
    ).toThrow('not your turn');
  });

  test('cannot draw during play step', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // P1 is already at Play step, cannot draw
    expect(() =>
      applyAction(state, { type: 'draw_from_deck', playerId: 'p1' }),
    ).toThrow();
  });

  test('getValidActions at start: meld + discard (not draw)', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // P1 starts at Play step
    let actions = getValidActions(state);
    expect(actions).toContain('meld');
    expect(actions).toContain('discard');
    expect(actions).not.toContain('draw_from_deck');

    // After P1 discards, P2 should draw
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });
    actions = getValidActions(state);
    expect(actions).toContain('draw_from_deck');
    expect(actions).toContain('draw_from_discard');
  });

  test('sanitizeStateForPlayer hides other hands', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    const sanitized = sanitizeStateForPlayer(state, 'p1');
    expect(sanitized.myHand).toHaveLength(15); // P1 has 15 at start
    expect(sanitized.players[0].handCount).toBe(15);
    expect(sanitized.players[1].handCount).toBe(14);
    expect((sanitized.players[1] as any).hand).toBeUndefined();
  });

  test('full turn cycle', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // P1: discard (already has 15 cards)
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });

    // P2: draw → discard
    state = applyAction(state, { type: 'draw_from_deck', playerId: 'p2' });
    state = applyAction(state, { type: 'discard', playerId: 'p2', cardId: state.players[1].hand[0].id });

    // P1: draw → discard
    state = applyAction(state, { type: 'draw_from_deck', playerId: 'p1' });
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });

    expect(state.currentPlayerIndex).toBe(1);
    expect(state.turnCount).toBe(3);
  });
});



