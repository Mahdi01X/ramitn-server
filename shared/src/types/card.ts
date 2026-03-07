// ─── Card Types ───────────────────────────────────────────────

export enum Suit {
  Hearts = 'hearts',
  Diamonds = 'diamonds',
  Clubs = 'clubs',
  Spades = 'spades',
}

export enum Rank {
  Ace = 1,
  Two = 2,
  Three = 3,
  Four = 4,
  Five = 5,
  Six = 6,
  Seven = 7,
  Eight = 8,
  Nine = 9,
  Ten = 10,
  Jack = 11,
  Queen = 12,
  King = 13,
}

export interface Card {
  /** Unique id within the deck (0..107 for 2×52+jokers) */
  id: number;
  suit: Suit | null;    // null for jokers
  rank: Rank | null;    // null for jokers
  isJoker: boolean;
  /** Which deck copy (0 or 1) */
  deckIndex: number;
}

export const RANK_NAMES: Record<number, string> = {
  1: 'A', 2: '2', 3: '3', 4: '4', 5: '5', 6: '6', 7: '7',
  8: '8', 9: '9', 10: '10', 11: 'J', 12: 'Q', 13: 'K',
};

export const SUIT_SYMBOLS: Record<string, string> = {
  hearts: '♥', diamonds: '♦', clubs: '♣', spades: '♠',
};

export function cardToString(card: Card): string {
  if (card.isJoker) return `🃏(${card.id})`;
  return `${RANK_NAMES[card.rank!]}${SUIT_SYMBOLS[card.suit!]}`;
}

