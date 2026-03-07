import { Card, Suit, Rank } from '../types/card';

const ALL_SUITS = [Suit.Hearts, Suit.Diamonds, Suit.Clubs, Suit.Spades];
const ALL_RANKS = [
  Rank.Ace, Rank.Two, Rank.Three, Rank.Four, Rank.Five, Rank.Six, Rank.Seven,
  Rank.Eight, Rank.Nine, Rank.Ten, Rank.Jack, Rank.Queen, Rank.King,
];

/** Create a full deck: 2×52 + numJokers (default 4) */
export function createDeck(numJokers: number = 4): Card[] {
  const cards: Card[] = [];
  let id = 0;

  for (let deckIndex = 0; deckIndex < 2; deckIndex++) {
    for (const suit of ALL_SUITS) {
      for (const rank of ALL_RANKS) {
        cards.push({ id: id++, suit, rank, isJoker: false, deckIndex });
      }
    }
  }

  for (let j = 0; j < numJokers; j++) {
    cards.push({ id: id++, suit: null, rank: null, isJoker: true, deckIndex: j % 2 });
  }

  return cards;
}

/** Fisher-Yates shuffle (returns new array) */
export function shuffle(cards: Card[], seed?: number): Card[] {
  const arr = [...cards];
  // Simple seeded RNG for reproducibility in tests
  let rng: () => number;
  if (seed !== undefined) {
    let s = seed;
    rng = () => {
      s = (s * 1664525 + 1013904223) & 0xffffffff;
      return (s >>> 0) / 0x100000000;
    };
  } else {
    rng = Math.random;
  }

  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

/** Deal cards to players. Returns [hands[], remainingDeck] */
export function deal(
  deck: Card[],
  numPlayers: number,
  cardsPerPlayer: number,
): [Card[][], Card[]] {
  const hands: Card[][] = Array.from({ length: numPlayers }, () => []);
  let idx = 0;

  for (let c = 0; c < cardsPerPlayer; c++) {
    for (let p = 0; p < numPlayers; p++) {
      if (idx < deck.length) {
        hands[p].push(deck[idx++]);
      }
    }
  }

  return [hands, deck.slice(idx)];
}


