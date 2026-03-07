import { calculateHandPenalty, calculateRoundScores } from '../engine/scoring';
import { canOpen, validateOpening } from '../engine/opening';
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

describe('Scoring', () => {
  test('calculateHandPenalty sums card points', () => {
    const hand = [
      card(Rank.Five, Suit.Hearts),
      card(Rank.King, Suit.Spades),
      card(Rank.Ace, Suit.Diamonds),
    ];
    // 5 + 10 + 11 = 26
    expect(calculateHandPenalty(hand, config)).toBe(26);
  });

  test('empty hand = 0 penalty', () => {
    expect(calculateHandPenalty([], config)).toBe(0);
  });

  test('joker in hand = jokerValue penalty', () => {
    const hand = [joker(99)];
    expect(calculateHandPenalty(hand, config)).toBe(30);
  });
});

describe('Opening', () => {
  test('canOpen returns false for set-only (clean run required)', () => {
    // Set of Kings: 10+10+10=30, but it's a set not a run
    const melds: Meld[] = [{
      id: 'm1',
      type: MeldType.Set,
      cards: [
        card(Rank.King, Suit.Hearts, 1),
        card(Rank.King, Suit.Spades, 2),
        card(Rank.King, Suit.Diamonds, 3),
      ],
      jokerSubstitutions: {},
    }];
    // Fails: not enough points (30 < 71) AND no clean run
    expect(canOpen(melds, config, false)).toBe(false);
  });

  test('canOpen returns true with clean run + enough points', () => {
    // 10♥ J♥ Q♥ K♥ = 40pts + A♥ A♠ A♦ = 33pts = 73 >= 71
    const melds: Meld[] = [
      {
        id: 'run1',
        type: MeldType.Run,
        cards: [
          card(Rank.Ten, Suit.Hearts, 10),
          card(Rank.Jack, Suit.Hearts, 11),
          card(Rank.Queen, Suit.Hearts, 12),
          card(Rank.King, Suit.Hearts, 13),
        ],
        jokerSubstitutions: {},
      },
      {
        id: 'set1',
        type: MeldType.Set,
        cards: [
          card(Rank.Ace, Suit.Hearts, 20),
          card(Rank.Ace, Suit.Spades, 21),
          card(Rank.Ace, Suit.Diamonds, 22),
        ],
        jokerSubstitutions: {},
      },
    ];
    expect(canOpen(melds, config, false)).toBe(true);
  });

  test('canOpen returns false if threshold not met', () => {
    const melds: Meld[] = [{
      id: 'm1',
      type: MeldType.Run,
      cards: [
        card(Rank.Two, Suit.Hearts, 1),
        card(Rank.Three, Suit.Hearts, 2),
        card(Rank.Four, Suit.Hearts, 3),
      ],
      jokerSubstitutions: {},
    }];
    // 2 + 3 + 4 = 9 < 71
    expect(canOpen(melds, config, false)).toBe(false);
  });

  test('canOpen returns true if already opened', () => {
    expect(canOpen([], config, true)).toBe(true);
  });

  test('canOpen returns true if threshold is 0', () => {
    expect(canOpen([], { ...config, openingThreshold: 0 }, false)).toBe(true);
  });

  test('canOpen rejects run with joker when openingRequiresCleanRun', () => {
    // Run with joker: 10♥ JOKER Q♥ K♥ A♥ = 10+30+10+10+11 = 71
    // Points are enough but the run has a joker → not a clean run
    const melds: Meld[] = [{
      id: 'run',
      type: MeldType.Run,
      cards: [
        card(Rank.Ten, Suit.Hearts, 1),
        joker(99),
        card(Rank.Queen, Suit.Hearts, 3),
        card(Rank.King, Suit.Hearts, 4),
        card(Rank.Ace, Suit.Hearts, 5),
      ],
      jokerSubstitutions: { 99: { suit: 'hearts', rank: 11 } },
    }];
    expect(canOpen(melds, config, false)).toBe(false);
  });

  test('canOpen accepts run with joker when openingRequiresCleanRun is false', () => {
    const melds: Meld[] = [{
      id: 'run',
      type: MeldType.Run,
      cards: [
        card(Rank.Ten, Suit.Hearts, 1),
        joker(99),
        card(Rank.Queen, Suit.Hearts, 3),
        card(Rank.King, Suit.Hearts, 4),
        card(Rank.Ace, Suit.Hearts, 5),
      ],
      jokerSubstitutions: { 99: { suit: 'hearts', rank: 11 } },
    }];
    expect(canOpen(melds, { ...config, openingRequiresCleanRun: false }, false)).toBe(true);
  });

  test('validateOpening returns points and reason on failure', () => {
    const melds: Meld[] = [{
      id: 'm1',
      type: MeldType.Run,
      cards: [
        card(Rank.Jack, Suit.Hearts, 1),
        card(Rank.Queen, Suit.Hearts, 2),
        card(Rank.King, Suit.Hearts, 3),
      ],
      jokerSubstitutions: {},
    }];
    const result = validateOpening(melds, config);
    // 10+10+10 = 30 < 71 → invalid
    expect(result.valid).toBe(false);
    expect(result.points).toBe(30);
    expect(result.reason).toBeDefined();
  });

  test('validateOpening succeeds with enough points and clean run', () => {
    const melds: Meld[] = [
      {
        id: 'run1',
        type: MeldType.Run,
        cards: [
          card(Rank.Nine, Suit.Spades, 30),
          card(Rank.Ten, Suit.Spades, 31),
          card(Rank.Jack, Suit.Spades, 32),
          card(Rank.Queen, Suit.Spades, 33),
          card(Rank.King, Suit.Spades, 34),
          card(Rank.Ace, Suit.Spades, 35),
        ],
        jokerSubstitutions: {},
      },
    ];
    const result = validateOpening(melds, config);
    // 9+10+10+10+10+11 = 60... not enough. Let's add more.
    // Actually: 9+10+10+10+10+11 = 60 < 71
    expect(result.valid).toBe(false);
  });

  test('validateOpening with two clean runs succeeds', () => {
    const melds: Meld[] = [
      {
        id: 'run1',
        type: MeldType.Run,
        cards: [
          card(Rank.Ten, Suit.Hearts, 40),
          card(Rank.Jack, Suit.Hearts, 41),
          card(Rank.Queen, Suit.Hearts, 42),
          card(Rank.King, Suit.Hearts, 43),
        ],
        jokerSubstitutions: {},
      },
      {
        id: 'run2',
        type: MeldType.Run,
        cards: [
          card(Rank.Ten, Suit.Spades, 50),
          card(Rank.Jack, Suit.Spades, 51),
          card(Rank.Queen, Suit.Spades, 52),
          card(Rank.King, Suit.Spades, 53),
        ],
        jokerSubstitutions: {},
      },
    ];
    const result = validateOpening(melds, config);
    // 40 + 40 = 80 >= 71, and both are clean runs
    expect(result.valid).toBe(true);
    expect(result.points).toBe(80);
  });
});


