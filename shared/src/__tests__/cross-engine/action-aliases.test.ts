/**
 * Tests for action type alias normalization.
 * Ensures shared/ engine accepts both canonical and aliased action types.
 */

import { GameAction, TurnStep, GamePhase } from '../../types/game-state';
import { createGame, startRound, applyAction } from '../../engine/game-machine';

describe('Action type alias normalization', () => {
  function setupDrawState() {
    let state = createGame(
      [
        { id: 'p1', name: 'Alice', isBot: false },
        { id: 'p2', name: 'Bob', isBot: false },
      ],
      {},
    );
    state = startRound(state, 42);
    // First player has 15 cards, turnStep = Play. Discard to advance.
    const cardToDiscard = state.players[state.currentPlayerIndex].hand[0];
    state = applyAction(state, { type: 'discard', playerId: state.players[state.currentPlayerIndex].id, cardId: cardToDiscard.id });
    // Now it's next player's turn, turnStep = Draw
    expect(state.turnStep).toBe(TurnStep.Draw);
    return state;
  }

  it('accepts draw_from_deck (canonical)', () => {
    const state = setupDrawState();
    const pid = state.players[state.currentPlayerIndex].id;
    const newState = applyAction(state, { type: 'draw_from_deck', playerId: pid });
    expect(newState.turnStep).toBe(TurnStep.Play);
  });

  it('accepts draw_deck (alias) — normalized to draw_from_deck', () => {
    const state = setupDrawState();
    const pid = state.players[state.currentPlayerIndex].id;
    const newState = applyAction(state, { type: 'draw_deck', playerId: pid });
    expect(newState.turnStep).toBe(TurnStep.Play);
  });

  it('accepts draw_from_discard (canonical)', () => {
    let state = setupDrawState();
    // Need a card on discard pile
    if (state.discardPile.length === 0) {
      // The first discard should have put a card there
      throw new Error('Expected discard pile to have a card');
    }
    const pid = state.players[state.currentPlayerIndex].id;
    const newState = applyAction(state, { type: 'draw_from_discard', playerId: pid });
    expect(newState.turnStep).toBe(TurnStep.Play);
  });

  it('accepts draw_discard (alias) — normalized to draw_from_discard', () => {
    let state = setupDrawState();
    if (state.discardPile.length === 0) {
      throw new Error('Expected discard pile to have a card');
    }
    const pid = state.players[state.currentPlayerIndex].id;
    const newState = applyAction(state, { type: 'draw_discard', playerId: pid });
    expect(newState.turnStep).toBe(TurnStep.Play);
  });
});
