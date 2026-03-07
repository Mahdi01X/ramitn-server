import { createDeck, shuffle, deal } from '../engine/deck';
import { Suit, Rank } from '../types/card';

describe('Deck', () => {
  test('createDeck creates 106 cards (2×52 + 2 jokers)', () => {
    const deck = createDeck(2);
    expect(deck).toHaveLength(106);
  });

  test('createDeck creates 108 cards with 4 jokers', () => {
    const deck = createDeck(4);
    expect(deck).toHaveLength(108);
  });

  test('createDeck has unique IDs', () => {
    const deck = createDeck(2);
    const ids = new Set(deck.map(c => c.id));
    expect(ids.size).toBe(106);
  });

  test('createDeck has correct number of jokers', () => {
    const deck = createDeck(2);
    const jokers = deck.filter(c => c.isJoker);
    expect(jokers).toHaveLength(2);
  });

  test('createDeck has 8 of each rank (2 decks)', () => {
    const deck = createDeck(2);
    const aces = deck.filter(c => c.rank === Rank.Ace);
    expect(aces).toHaveLength(8);
    const kings = deck.filter(c => c.rank === Rank.King);
    expect(kings).toHaveLength(8);
  });

  test('shuffle produces different order (seeded)', () => {
    const deck = createDeck(2);
    const shuffled = shuffle(deck, 42);
    // Very unlikely to be in same order
    const sameOrder = deck.every((c, i) => c.id === shuffled[i].id);
    expect(sameOrder).toBe(false);
  });

  test('shuffle with same seed produces same result', () => {
    const deck = createDeck(2);
    const a = shuffle(deck, 123);
    const b = shuffle(deck, 123);
    expect(a.map(c => c.id)).toEqual(b.map(c => c.id));
  });

  test('deal distributes correct number of cards', () => {
    const deck = shuffle(createDeck(2), 42);
    const [hands, remaining] = deal(deck, 4, 14);

    expect(hands).toHaveLength(4);
    hands.forEach(h => expect(h).toHaveLength(14));
    expect(remaining).toHaveLength(106 - 56); // 106 - 4×14
  });

  test('deal with 2 players', () => {
    const deck = shuffle(createDeck(2), 42);
    const [hands, remaining] = deal(deck, 2, 14);

    expect(hands).toHaveLength(2);
    hands.forEach(h => expect(h).toHaveLength(14));
    expect(remaining).toHaveLength(106 - 28);
  });
});

