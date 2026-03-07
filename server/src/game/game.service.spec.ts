import { GameService } from './game.service';
import { GamePhase, TurnStep } from '@rami/shared';

describe('GameService', () => {
  let service: GameService;

  beforeEach(() => {
    service = new GameService();
  });

  const players = [
    { id: 'p1', name: 'Alice', isBot: false },
    { id: 'p2', name: 'Bob', isBot: false },
  ];

  test('create initializes a game', () => {
    const state = service.create(players, {});
    expect(state.players).toHaveLength(2);
    expect(state.phase).toBe(GamePhase.Waiting);
    expect(service.getState(state.id)).toBeDefined();
  });

  test('startNewRound deals cards', () => {
    const state = service.create(players, {});
    const round = service.startNewRound(state.id);
    expect(round.phase).toBe(GamePhase.PlayerTurn);
    expect(round.round).toBe(1);
    expect(round.players[0].hand).toHaveLength(14);
  });

  test('performAction processes draw', () => {
    const state = service.create(players, {});
    service.startNewRound(state.id);

    const after = service.performAction(state.id, {
      type: 'draw_from_deck',
      playerId: 'p1',
    });

    expect(after.players[0].hand).toHaveLength(15);
    expect(after.turnStep).toBe(TurnStep.Play);
  });

  test('getSanitizedState hides other hands', () => {
    const state = service.create(players, {});
    service.startNewRound(state.id);

    const sanitized = service.getSanitizedState(state.id, 'p1');
    expect(sanitized).toBeDefined();
    expect(sanitized!.myHand).toHaveLength(14);
    expect(sanitized!.players[1].handCount).toBe(14);
    expect((sanitized!.players[1] as any).hand).toBeUndefined();
  });

  test('performAction rejects wrong player', () => {
    const state = service.create(players, {});
    service.startNewRound(state.id);

    expect(() =>
      service.performAction(state.id, {
        type: 'draw_from_deck',
        playerId: 'p2', // Not p2's turn
      }),
    ).toThrow();
  });

  test('removeGame cleans up', () => {
    const state = service.create(players, {});
    service.removeGame(state.id);
    expect(service.getState(state.id)).toBeUndefined();
  });
});

