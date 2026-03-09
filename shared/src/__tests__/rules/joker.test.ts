import { applyAction } from '../../engine/game-machine';
import { TurnStep } from '../../types/game-state';
import { card, joker, makePlayer, makeGameState, makeRun, makeSet } from '../helpers';
import { Card, Suit, Rank } from '../../types/card';
import { MeldType } from '../../types/meld';
import { DEFAULT_CONFIG } from '../../types/game-config';

describe('Joker Recovery', () => {
  test('can replace joker in run with matching natural card', () => {
    const targetMeld = makeRun([
      card(Rank.Five, Suit.Hearts, 50),
      joker(99),
      card(Rank.Seven, Suit.Hearts, 52),
    ], 'meld1');

    let state = makeGameState({
      players: [
        makePlayer({
          id: 'p1',
          hand: [
            card(Rank.Six, Suit.Hearts, 1), // the natural card to replace joker
            card(Rank.Two, Suit.Clubs, 2),   // keep for discard
          ],
          hasOpened: true,
        }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
      tableMelds: [targetMeld],
    });

    state = applyAction(state, {
      type: 'replace_joker',
      playerId: 'p1',
      cardId: 1,
      targetMeldId: 'meld1',
      jokerCardId: 99,
    });

    // Joker should now be in player's hand
    expect(state.players[0].hand.some((c: Card) => c.id === 99)).toBe(true);
    // Natural card should be in the meld
    expect(state.tableMelds[0].cards.some((c: Card) => c.id === 1)).toBe(true);
    expect(state.tableMelds[0].cards.every((c: Card) => !c.isJoker)).toBe(true);
  });

  test('cannot replace joker with wrong card', () => {
    const targetMeld = makeRun([
      card(Rank.Five, Suit.Hearts, 50),
      joker(99),
      card(Rank.Seven, Suit.Hearts, 52),
    ], 'meld1');

    let state = makeGameState({
      players: [
        makePlayer({
          id: 'p1',
          hand: [
            card(Rank.Nine, Suit.Hearts, 1), // wrong card
            card(Rank.Two, Suit.Clubs, 2),
          ],
          hasOpened: true,
        }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
      tableMelds: [targetMeld],
    });

    expect(() =>
      applyAction(state, {
        type: 'replace_joker',
        playerId: 'p1',
        cardId: 1,
        targetMeldId: 'meld1',
        jokerCardId: 99,
      }),
    ).toThrow('Replacement does not produce a valid meld');
  });

  test('cannot replace joker if jokerLocked', () => {
    const targetMeld = makeRun([
      card(Rank.Five, Suit.Hearts, 50),
      joker(99),
      card(Rank.Seven, Suit.Hearts, 52),
    ], 'meld1');

    let state = makeGameState({
      config: { ...DEFAULT_CONFIG, jokerLocked: true },
      players: [
        makePlayer({
          id: 'p1',
          hand: [card(Rank.Six, Suit.Hearts, 1), card(Rank.Two, Suit.Clubs, 2)],
          hasOpened: true,
        }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
      tableMelds: [targetMeld],
    });

    expect(() =>
      applyAction(state, {
        type: 'replace_joker',
        playerId: 'p1',
        cardId: 1,
        targetMeldId: 'meld1',
        jokerCardId: 99,
      }),
    ).toThrow('Jokers cannot be retrieved');
  });

  test('cannot replace joker if not opened', () => {
    const targetMeld = makeRun([
      card(Rank.Five, Suit.Hearts, 50),
      joker(99),
      card(Rank.Seven, Suit.Hearts, 52),
    ], 'meld1');

    let state = makeGameState({
      players: [
        makePlayer({
          id: 'p1',
          hand: [card(Rank.Six, Suit.Hearts, 1), card(Rank.Two, Suit.Clubs, 2)],
          hasOpened: false,
        }),
        makePlayer({ id: 'p2', hand: [card(Rank.Three, Suit.Clubs, 30)] }),
      ],
      currentPlayerIndex: 0,
      turnStep: TurnStep.Play,
      tableMelds: [targetMeld],
    });

    expect(() =>
      applyAction(state, {
        type: 'replace_joker',
        playerId: 'p1',
        cardId: 1,
        targetMeldId: 'meld1',
        jokerCardId: 99,
      }),
    ).toThrow('Must open before replacing jokers');
  });
});
