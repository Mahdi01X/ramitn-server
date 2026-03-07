import { computeBotMove } from '../engine/bot-ai';
import { createGame, startRound, applyAction } from '../engine/game-machine';
import { TurnStep } from '../types/game-state';

describe('Bot AI', () => {
  const players = [
    { id: 'p1', name: 'Alice', isBot: true },
    { id: 'p2', name: 'Bob', isBot: true },
  ];

  test('bot discards on first turn (P1 starts with 15 cards at Play step)', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // P1 starts at Play step with 15 cards
    expect(state.turnStep).toBe(TurnStep.Play);
    const move = computeBotMove(state, 'p1');
    expect(['meld', 'layoff', 'discard']).toContain(move.type);
  });

  test('bot draws from deck on draw step (P2 after P1 discards)', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // P1 discards first
    state = applyAction(state, { type: 'discard', playerId: 'p1', cardId: state.players[0].hand[0].id });

    // P2 is now at Draw step
    expect(state.turnStep).toBe(TurnStep.Draw);
    const move = computeBotMove(state, 'p2');
    expect(move.type).toBe('draw_from_deck');
  });

  test('bot plays a full turn without errors', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // P1 starts at Play — plays until discard
    let move = computeBotMove(state, 'p1');
    while (move.type !== 'discard') {
      state = applyAction(state, move);
      move = computeBotMove(state, 'p1');
    }
    state = applyAction(state, move);

    // Should now be P2's turn at draw step
    expect(state.currentPlayerIndex).toBe(1);
    expect(state.turnStep).toBe(TurnStep.Draw);
  });

  test('two bots can play multiple turns', () => {
    let state = createGame(players);
    state = startRound(state, 42);

    // Play 10 full turns
    for (let turn = 0; turn < 10; turn++) {
      const currentId = state.players[state.currentPlayerIndex].id;

      // If at draw step, draw first
      if (state.turnStep === TurnStep.Draw) {
        let move = computeBotMove(state, currentId);
        state = applyAction(state, move);
      }

      // Play until discard
      let move = computeBotMove(state, currentId);
      while (move.type !== 'discard') {
        state = applyAction(state, move);
        move = computeBotMove(state, currentId);
      }
      state = applyAction(state, move);

      // Check if round ended
      if (state.phase !== 'player_turn') break;
    }

    expect(state.turnCount).toBeGreaterThanOrEqual(1);
  });
});


