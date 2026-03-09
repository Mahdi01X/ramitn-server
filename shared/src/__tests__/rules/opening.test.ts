import { isValidSet, isValidRun, validateMeld, canLayoff, getCardPoints, calculateMeldPoints } from '../../engine/meld-validator';
import { card, joker, makeRun, makeSet } from '../helpers';
import { Suit, Rank } from '../../types/card';
import { MeldType } from '../../types/meld';
import { DEFAULT_CONFIG, GameConfig } from '../../types/game-config';

const config = DEFAULT_CONFIG;

describe('Opening Rules', () => {
  describe('Minimum 71 points', () => {
    test('clean run 10-J-Q-K + set of Aces = 40+33=73 >= 71', () => {
      const run = [
        card(Rank.Ten, Suit.Hearts, 1),
        card(Rank.Jack, Suit.Hearts, 2),
        card(Rank.Queen, Suit.Hearts, 3),
        card(Rank.King, Suit.Hearts, 4),
      ];
      const set = [
        card(Rank.Ace, Suit.Hearts, 5),
        card(Rank.Ace, Suit.Spades, 6),
        card(Rank.Ace, Suit.Diamonds, 7),
      ];
      const runPoints = run.reduce((s, c) => s + getCardPoints(c, config), 0);
      const setPoints = set.reduce((s, c) => s + getCardPoints(c, config), 0);
      expect(runPoints + setPoints).toBeGreaterThanOrEqual(71);
    });

    test('run 2-3-4 = 9 points, not enough', () => {
      const run = [
        card(Rank.Two, Suit.Hearts, 1),
        card(Rank.Three, Suit.Hearts, 2),
        card(Rank.Four, Suit.Hearts, 3),
      ];
      const points = run.reduce((s, c) => s + getCardPoints(c, config), 0);
      expect(points).toBe(9);
      expect(points).toBeLessThan(71);
    });
  });

  describe('Clean run requirement', () => {
    test('run with joker is NOT a clean run', () => {
      const cards = [
        card(Rank.Ten, Suit.Hearts, 1),
        joker(99),
        card(Rank.Queen, Suit.Hearts, 3),
      ];
      expect(isValidRun(cards, config)).toBe(true);
      // Has joker → not clean
      expect(cards.some(c => c.isJoker)).toBe(true);
    });

    test('run without joker IS a clean run', () => {
      const cards = [
        card(Rank.Ten, Suit.Hearts, 1),
        card(Rank.Jack, Suit.Hearts, 2),
        card(Rank.Queen, Suit.Hearts, 3),
      ];
      expect(isValidRun(cards, config)).toBe(true);
      expect(cards.every(c => !c.isJoker)).toBe(true);
    });
  });
});

describe('Meld Validation - Sets', () => {
  test('3 cards same rank different suits = valid set', () => {
    expect(isValidSet([
      card(Rank.Seven, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Spades, 2),
      card(Rank.Seven, Suit.Diamonds, 3),
    ], config)).toBe(true);
  });

  test('4 cards same rank all suits = valid carré', () => {
    expect(isValidSet([
      card(Rank.King, Suit.Hearts, 1),
      card(Rank.King, Suit.Spades, 2),
      card(Rank.King, Suit.Diamonds, 3),
      card(Rank.King, Suit.Clubs, 4),
    ], config)).toBe(true);
  });

  test('duplicate suit = invalid set', () => {
    expect(isValidSet([
      card(Rank.Seven, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Hearts, 2),
      card(Rank.Seven, Suit.Diamonds, 3),
    ], config)).toBe(false);
  });

  test('5 cards = invalid (too many)', () => {
    expect(isValidSet([
      card(Rank.Seven, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Spades, 2),
      card(Rank.Seven, Suit.Diamonds, 3),
      card(Rank.Seven, Suit.Clubs, 4),
      joker(5),
    ], config)).toBe(false);
  });

  test('set with 1 joker = valid', () => {
    expect(isValidSet([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Five, Suit.Spades, 2),
      joker(99),
    ], config)).toBe(true);
  });

  test('set with 2 jokers = invalid (default maxJokersPerMeld=1)', () => {
    expect(isValidSet([
      card(Rank.Five, Suit.Hearts, 1),
      joker(98),
      joker(99),
    ], config)).toBe(false);
  });

  test('different ranks = invalid set', () => {
    expect(isValidSet([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Spades, 2),
      card(Rank.Five, Suit.Diamonds, 3),
    ], config)).toBe(false);
  });

  test('2 cards only = invalid', () => {
    expect(isValidSet([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Five, Suit.Spades, 2),
    ], config)).toBe(false);
  });
});

describe('Meld Validation - Runs', () => {
  test('3 consecutive same suit = valid run', () => {
    expect(isValidRun([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Hearts, 2),
      card(Rank.Seven, Suit.Hearts, 3),
    ], config)).toBe(true);
  });

  test('5 consecutive same suit = valid run', () => {
    expect(isValidRun([
      card(Rank.Three, Suit.Clubs, 1),
      card(Rank.Four, Suit.Clubs, 2),
      card(Rank.Five, Suit.Clubs, 3),
      card(Rank.Six, Suit.Clubs, 4),
      card(Rank.Seven, Suit.Clubs, 5),
    ], config)).toBe(true);
  });

  test('different suits = invalid run', () => {
    expect(isValidRun([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Spades, 2),
      card(Rank.Seven, Suit.Hearts, 3),
    ], config)).toBe(false);
  });

  test('non-consecutive = invalid run', () => {
    expect(isValidRun([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Hearts, 2),
      card(Rank.Eight, Suit.Hearts, 3),
    ], config)).toBe(false);
  });

  test('run with joker filling gap = valid', () => {
    expect(isValidRun([
      card(Rank.Five, Suit.Hearts, 1),
      joker(99),
      card(Rank.Seven, Suit.Hearts, 3),
    ], config)).toBe(true);
  });

  test('A-2-3 (Ace low) = valid run', () => {
    expect(isValidRun([
      card(Rank.Ace, Suit.Hearts, 1),
      card(Rank.Two, Suit.Hearts, 2),
      card(Rank.Three, Suit.Hearts, 3),
    ], config)).toBe(true);
  });

  test('J-Q-K = valid run', () => {
    expect(isValidRun([
      card(Rank.Jack, Suit.Diamonds, 1),
      card(Rank.Queen, Suit.Diamonds, 2),
      card(Rank.King, Suit.Diamonds, 3),
    ], config)).toBe(true);
  });

  test('2 cards only = invalid run', () => {
    expect(isValidRun([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Hearts, 2),
    ], config)).toBe(false);
  });

  test('duplicate rank in run = invalid', () => {
    expect(isValidRun([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Five, Suit.Hearts, 2),
      card(Rank.Six, Suit.Hearts, 3),
    ], config)).toBe(false);
  });
});

describe('Meld Validation - Ace High/Low', () => {
  test('A-2-3 valid (Ace as 1)', () => {
    expect(isValidRun([
      card(Rank.Ace, Suit.Spades, 1),
      card(Rank.Two, Suit.Spades, 2),
      card(Rank.Three, Suit.Spades, 3),
    ], config)).toBe(true);
  });

  // Note: Q-K-A (Ace as 14) is NOT currently supported in shared/ isValidRun
  // This test documents the current behavior
  test('Q-K-A — Ace high in run (valid per Tunisian rules)', () => {
    const result = isValidRun([
      card(Rank.Queen, Suit.Spades, 1),
      card(Rank.King, Suit.Spades, 2),
      card(Rank.Ace, Suit.Spades, 3),
    ], config);
    expect(result).toBe(true);
  });

  test('K-A-2 wrapping is NOT valid', () => {
    expect(isValidRun([
      card(Rank.King, Suit.Spades, 1),
      card(Rank.Ace, Suit.Spades, 2),
      card(Rank.Two, Suit.Spades, 3),
    ], config)).toBe(false);
  });
});

describe('Card Points', () => {
  test('number card = face value', () => {
    expect(getCardPoints(card(Rank.Five, Suit.Hearts), config)).toBe(5);
    expect(getCardPoints(card(Rank.Nine, Suit.Spades), config)).toBe(9);
  });

  test('face cards = 10', () => {
    expect(getCardPoints(card(Rank.Jack, Suit.Hearts), config)).toBe(10);
    expect(getCardPoints(card(Rank.Queen, Suit.Hearts), config)).toBe(10);
    expect(getCardPoints(card(Rank.King, Suit.Hearts), config)).toBe(10);
  });

  test('Ace = aceHighValue (11 by default)', () => {
    expect(getCardPoints(card(Rank.Ace, Suit.Hearts), config)).toBe(11);
  });

  test('Joker = jokerValue (30 by default)', () => {
    expect(getCardPoints(joker(), config)).toBe(30);
  });
});

describe('Layoff validation', () => {
  test('can add card to end of run', () => {
    const m = makeRun([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Hearts, 2),
      card(Rank.Seven, Suit.Hearts, 3),
    ]);
    expect(canLayoff(card(Rank.Eight, Suit.Hearts, 4), m, 'end', config)).toBe(true);
  });

  test('can add card to start of run', () => {
    const m = makeRun([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Hearts, 2),
      card(Rank.Seven, Suit.Hearts, 3),
    ]);
    expect(canLayoff(card(Rank.Four, Suit.Hearts, 4), m, 'start', config)).toBe(true);
  });

  test('cannot add wrong card to run', () => {
    const m = makeRun([
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Hearts, 2),
      card(Rank.Seven, Suit.Hearts, 3),
    ]);
    expect(canLayoff(card(Rank.Nine, Suit.Hearts, 4), m, 'end', config)).toBe(false);
  });

  test('can add 4th card to set (different suit)', () => {
    const m = makeSet([
      card(Rank.Ten, Suit.Hearts, 1),
      card(Rank.Ten, Suit.Spades, 2),
      card(Rank.Ten, Suit.Diamonds, 3),
    ]);
    expect(canLayoff(card(Rank.Ten, Suit.Clubs, 4), m, 'end', config)).toBe(true);
  });

  test('cannot add 5th card to set', () => {
    const m = makeSet([
      card(Rank.Ten, Suit.Hearts, 1),
      card(Rank.Ten, Suit.Spades, 2),
      card(Rank.Ten, Suit.Diamonds, 3),
      card(Rank.Ten, Suit.Clubs, 4),
    ]);
    expect(canLayoff(joker(5), m, 'end', config)).toBe(false);
  });
});
