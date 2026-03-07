import { isValidSet, isValidRun, validateMeld, getCardPoints, calculateMeldPoints, canLayoff } from '../engine/meld-validator';
import { Card, Suit, Rank } from '../types/card';
import { Meld, MeldType } from '../types/meld';
import { DEFAULT_CONFIG } from '../types/game-config';

const config = DEFAULT_CONFIG;

function card(rank: Rank, suit: Suit, id: number = 0): Card {
  return { id, suit, rank, isJoker: false, deckIndex: 0 };
}

function joker(id: number = 99): Card {
  return { id, suit: null, rank: null, isJoker: true, deckIndex: 0 };
}

describe('isValidSet', () => {
  test('valid 3-card set', () => {
    const cards = [
      card(Rank.Seven, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Spades, 2),
      card(Rank.Seven, Suit.Diamonds, 3),
    ];
    expect(isValidSet(cards, config)).toBe(true);
  });

  test('valid 4-card set (carré)', () => {
    const cards = [
      card(Rank.King, Suit.Hearts, 1),
      card(Rank.King, Suit.Spades, 2),
      card(Rank.King, Suit.Diamonds, 3),
      card(Rank.King, Suit.Clubs, 4),
    ];
    expect(isValidSet(cards, config)).toBe(true);
  });

  test('invalid: different ranks', () => {
    const cards = [
      card(Rank.Seven, Suit.Hearts, 1),
      card(Rank.Eight, Suit.Spades, 2),
      card(Rank.Seven, Suit.Diamonds, 3),
    ];
    expect(isValidSet(cards, config)).toBe(false);
  });

  test('invalid: same suit', () => {
    const cards = [
      card(Rank.Seven, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Hearts, 2),
      card(Rank.Seven, Suit.Diamonds, 3),
    ];
    expect(isValidSet(cards, config)).toBe(false);
  });

  test('invalid: only 2 cards', () => {
    const cards = [
      card(Rank.Seven, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Spades, 2),
    ];
    expect(isValidSet(cards, config)).toBe(false);
  });

  test('valid set with 1 joker', () => {
    const cards = [
      card(Rank.Seven, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Spades, 2),
      joker(99),
    ];
    expect(isValidSet(cards, config)).toBe(true);
  });

  test('invalid: too many jokers', () => {
    const cards = [
      card(Rank.Seven, Suit.Hearts, 1),
      joker(98),
      joker(99),
    ];
    expect(isValidSet(cards, { ...config, maxJokersPerMeld: 1 })).toBe(false);
  });
});

describe('isValidRun', () => {
  test('valid 3-card run', () => {
    const cards = [
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Hearts, 2),
      card(Rank.Seven, Suit.Hearts, 3),
    ];
    expect(isValidRun(cards, config)).toBe(true);
  });

  test('valid 5-card run', () => {
    const cards = [
      card(Rank.Three, Suit.Clubs, 1),
      card(Rank.Four, Suit.Clubs, 2),
      card(Rank.Five, Suit.Clubs, 3),
      card(Rank.Six, Suit.Clubs, 4),
      card(Rank.Seven, Suit.Clubs, 5),
    ];
    expect(isValidRun(cards, config)).toBe(true);
  });

  test('invalid: different suits', () => {
    const cards = [
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Six, Suit.Spades, 2),
      card(Rank.Seven, Suit.Hearts, 3),
    ];
    expect(isValidRun(cards, config)).toBe(false);
  });

  test('invalid: not consecutive', () => {
    const cards = [
      card(Rank.Five, Suit.Hearts, 1),
      card(Rank.Seven, Suit.Hearts, 2),
      card(Rank.Eight, Suit.Hearts, 3),
    ];
    expect(isValidRun(cards, config)).toBe(false);
  });

  test('valid run with joker filling gap', () => {
    const cards = [
      card(Rank.Five, Suit.Hearts, 1),
      joker(99),
      card(Rank.Seven, Suit.Hearts, 3),
    ];
    expect(isValidRun(cards, config)).toBe(true);
  });

  test('run A-2-3', () => {
    const cards = [
      card(Rank.Ace, Suit.Hearts, 1),
      card(Rank.Two, Suit.Hearts, 2),
      card(Rank.Three, Suit.Hearts, 3),
    ];
    expect(isValidRun(cards, config)).toBe(true);
  });

  test('run J-Q-K', () => {
    const cards = [
      card(Rank.Jack, Suit.Diamonds, 1),
      card(Rank.Queen, Suit.Diamonds, 2),
      card(Rank.King, Suit.Diamonds, 3),
    ];
    expect(isValidRun(cards, config)).toBe(true);
  });
});

describe('validateMeld', () => {
  test('detects set', () => {
    const cards = [
      card(Rank.Ten, Suit.Hearts, 1),
      card(Rank.Ten, Suit.Spades, 2),
      card(Rank.Ten, Suit.Diamonds, 3),
    ];
    expect(validateMeld(cards, config)).toBe(MeldType.Set);
  });

  test('detects run', () => {
    const cards = [
      card(Rank.Eight, Suit.Clubs, 1),
      card(Rank.Nine, Suit.Clubs, 2),
      card(Rank.Ten, Suit.Clubs, 3),
    ];
    expect(validateMeld(cards, config)).toBe(MeldType.Run);
  });

  test('returns null for invalid', () => {
    const cards = [
      card(Rank.Two, Suit.Hearts, 1),
      card(Rank.Five, Suit.Spades, 2),
      card(Rank.King, Suit.Clubs, 3),
    ];
    expect(validateMeld(cards, config)).toBeNull();
  });
});

describe('getCardPoints', () => {
  test('number card returns face value', () => {
    expect(getCardPoints(card(Rank.Five, Suit.Hearts), config)).toBe(5);
  });

  test('face card returns 10', () => {
    expect(getCardPoints(card(Rank.Jack, Suit.Hearts), config)).toBe(10);
    expect(getCardPoints(card(Rank.Queen, Suit.Hearts), config)).toBe(10);
    expect(getCardPoints(card(Rank.King, Suit.Hearts), config)).toBe(10);
  });

  test('ace returns aceHighValue', () => {
    expect(getCardPoints(card(Rank.Ace, Suit.Hearts), config)).toBe(11);
  });

  test('joker returns jokerValue', () => {
    expect(getCardPoints(joker(), config)).toBe(30);
  });
});

describe('canLayoff', () => {
  test('can add card to end of run', () => {
    const m: Meld = {
      id: 'm1',
      type: MeldType.Run,
      cards: [
        card(Rank.Five, Suit.Hearts, 1),
        card(Rank.Six, Suit.Hearts, 2),
        card(Rank.Seven, Suit.Hearts, 3),
      ],
      jokerSubstitutions: {},
    };
    expect(canLayoff(card(Rank.Eight, Suit.Hearts, 4), m, 'end', config)).toBe(true);
  });

  test('can add card to start of run', () => {
    const m: Meld = {
      id: 'm1',
      type: MeldType.Run,
      cards: [
        card(Rank.Five, Suit.Hearts, 1),
        card(Rank.Six, Suit.Hearts, 2),
        card(Rank.Seven, Suit.Hearts, 3),
      ],
      jokerSubstitutions: {},
    };
    expect(canLayoff(card(Rank.Four, Suit.Hearts, 4), m, 'start', config)).toBe(true);
  });

  test('cannot add wrong card to run', () => {
    const m: Meld = {
      id: 'm1',
      type: MeldType.Run,
      cards: [
        card(Rank.Five, Suit.Hearts, 1),
        card(Rank.Six, Suit.Hearts, 2),
        card(Rank.Seven, Suit.Hearts, 3),
      ],
      jokerSubstitutions: {},
    };
    expect(canLayoff(card(Rank.Nine, Suit.Hearts, 4), m, 'end', config)).toBe(false);
  });

  test('can add 4th card to set', () => {
    const m: Meld = {
      id: 'm1',
      type: MeldType.Set,
      cards: [
        card(Rank.Ten, Suit.Hearts, 1),
        card(Rank.Ten, Suit.Spades, 2),
        card(Rank.Ten, Suit.Diamonds, 3),
      ],
      jokerSubstitutions: {},
    };
    expect(canLayoff(card(Rank.Ten, Suit.Clubs, 4), m, 'end', config)).toBe(true);
  });
});

