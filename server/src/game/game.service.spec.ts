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
    // First player gets 15 cards (Rami Tunisien rule: extra card)
    expect(round.players[0].hand).toHaveLength(15);
    // Second player gets the normal 14 cards
    expect(round.players[1].hand).toHaveLength(14);
  });

  test('performAction processes discard (first player starts at Play step)', () => {
    const state = service.create(players, {});
    const round = service.startNewRound(state.id);

    // First player has 15 cards and turnStep is Play (skip draw)
    expect(round.turnStep).toBe(TurnStep.Play);
    expect(round.players[0].hand).toHaveLength(15);

    // First player must discard (or meld then discard)
    const cardToDiscard = round.players[0].hand[0];
    const after = service.performAction(state.id, {
      type: 'discard',
      playerId: 'p1',
      cardId: cardToDiscard.id,
    });

    expect(after.players[0].hand).toHaveLength(14);
    expect(after.turnStep).toBe(TurnStep.Draw); // next player's turn starts at Draw
  });

  test('getSanitizedState hides other hands', () => {
    const state = service.create(players, {});
    service.startNewRound(state.id);

    const sanitized = service.getSanitizedState(state.id, 'p1');
    expect(sanitized).toBeDefined();
    // First player (p1) has 15 cards (Rami Tunisien: extra card for first player)
    expect(sanitized!.myHand).toHaveLength(15);
    // Second player (p2) has 14 cards
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

