import { calculateHandPenalty, calculateRoundScores, checkGameEnd } from '../../engine/scoring';
import { card, joker, makePlayer, makeGameState } from '../helpers';
import { Suit, Rank } from '../../types/card';
import { GamePhase } from '../../types/game-state';
import { DEFAULT_CONFIG } from '../../types/game-config';

const config = DEFAULT_CONFIG;

describe('Hand Penalty Calculation', () => {
  test('empty hand = 0', () => {
    expect(calculateHandPenalty([], config)).toBe(0);
  });

  test('number cards = face value', () => {
    const hand = [
      card(Rank.Five, Suit.Hearts),
      card(Rank.Three, Suit.Spades),
    ];
    expect(calculateHandPenalty(hand, config)).toBe(8);
  });

  test('face cards = 10 each', () => {
    const hand = [
      card(Rank.Jack, Suit.Hearts),
      card(Rank.Queen, Suit.Spades),
      card(Rank.King, Suit.Diamonds),
    ];
    expect(calculateHandPenalty(hand, config)).toBe(30);
  });

  test('Ace = 11 (aceHighValue)', () => {
    const hand = [card(Rank.Ace, Suit.Hearts)];
    expect(calculateHandPenalty(hand, config)).toBe(11);
  });

  test('Joker = 30 (jokerValue)', () => {
    const hand = [joker()];
    expect(calculateHandPenalty(hand, config)).toBe(30);
  });

  test('mixed hand', () => {
    const hand = [
      card(Rank.Five, Suit.Hearts),  // 5
      card(Rank.King, Suit.Spades),  // 10
      card(Rank.Ace, Suit.Diamonds), // 11
      joker(),                       // 30
    ];
    expect(calculateHandPenalty(hand, config)).toBe(56);
  });
});

describe('Round Scores', () => {
  test('winner gets 0, losers get hand penalty', () => {
    const state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [] }), // winner
        makePlayer({
          id: 'p2',
          hand: [card(Rank.King, Suit.Hearts, 1), card(Rank.Ace, Suit.Spades, 2)],
          hasOpened: true, // opened but has remaining cards
        }),
      ],
    });

    const scores = calculateRoundScores(state);
    expect(scores['p1']).toBe(0);
    expect(scores['p2']).toBe(21); // 10 + 11
  });

  test('player who never opened gets 100 pts flat penalty', () => {
    const state = makeGameState({
      players: [
        makePlayer({ id: 'p1', hand: [] }), // winner
        makePlayer({
          id: 'p2',
          hand: [card(Rank.King, Suit.Hearts, 1), card(Rank.Ace, Suit.Spades, 2)],
          hasOpened: false,
        }),
      ],
    });

    const scores = calculateRoundScores(state);
    expect(scores['p1']).toBe(0);
    expect(scores['p2']).toBe(100); // flat penalty — never opened
  });
});

describe('Game End Conditions', () => {
  test('max rounds reached → lowest total score wins', () => {
    const state = makeGameState({
      config: { ...DEFAULT_CONFIG, maxRounds: 3 },
      round: 3,
      players: [
        makePlayer({ id: 'p1', totalScore: 50 }),
        makePlayer({ id: 'p2', totalScore: 80 }),
      ],
    });

    const result = checkGameEnd(state);
    expect(result.isEnd).toBe(true);
    expect(result.winnerId).toBe('p1');
  });

  test('elimination mode: last player standing wins', () => {
    const state = makeGameState({
      config: { ...DEFAULT_CONFIG, scoringMode: 'elimination', eliminationThreshold: 100 },
      round: 2,
      players: [
        makePlayer({ id: 'p1', totalScore: 50 }),
        makePlayer({ id: 'p2', totalScore: 120 }), // eliminated
      ],
    });

    const result = checkGameEnd(state);
    expect(result.isEnd).toBe(true);
    expect(result.winnerId).toBe('p1');
  });

  test('game continues if not enough rounds played and no elimination', () => {
    const state = makeGameState({
      config: { ...DEFAULT_CONFIG, maxRounds: 5 },
      round: 2,
      players: [
        makePlayer({ id: 'p1', totalScore: 30 }),
        makePlayer({ id: 'p2', totalScore: 50 }),
      ],
    });

    const result = checkGameEnd(state);
    expect(result.isEnd).toBe(false);
  });
});
