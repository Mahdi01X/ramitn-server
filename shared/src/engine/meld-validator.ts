import { Card, Rank, Suit } from '../types/card';
import { Meld, MeldType } from '../types/meld';
import { GameConfig } from '../types/game-config';

/** Check if cards form a valid set (3-4 same rank, different suits) */
export function isValidSet(cards: Card[], config: GameConfig): boolean {
  if (cards.length < 3 || cards.length > 4) return false;

  const jokers = cards.filter(c => c.isJoker);
  const normals = cards.filter(c => !c.isJoker);

  if (jokers.length > config.maxJokersPerMeld) return false;
  if (normals.length === 0) return false;

  // All normal cards must have the same rank
  const rank = normals[0].rank!;
  if (!normals.every(c => c.rank === rank)) return false;

  // All suits must be different (among normal cards)
  const suits = new Set(normals.map(c => c.suit!));
  if (suits.size !== normals.length) return false;

  return true;
}

/** Check if cards form a valid run (3+ consecutive, same suit) */
export function isValidRun(cards: Card[], config: GameConfig): boolean {
  if (cards.length < 3) return false;

  const jokers = cards.filter(c => c.isJoker);
  const normals = cards.filter(c => !c.isJoker);

  if (jokers.length > config.maxJokersPerMeld) return false;
  if (normals.length === 0) return false;

  // All normal cards must have the same suit
  const suit = normals[0].suit!;
  if (!normals.every(c => c.suit === suit)) return false;

  // Try Ace as low (rank 1) first
  if (tryRunWithAceValue(normals, jokers.length, false)) return true;

  // If any Ace present, retry with Ace as high (rank 14)
  const hasAce = normals.some(c => c.rank === Rank.Ace);
  if (hasAce && tryRunWithAceValue(normals, jokers.length, true)) return true;

  return false;
}

function tryRunWithAceValue(normals: Card[], jokerCount: number, aceHigh: boolean): boolean {
  const getRank = (c: Card) => aceHigh && c.rank === Rank.Ace ? 14 : c.rank!;

  const sorted = [...normals].sort((a, b) => getRank(a) - getRank(b));

  // Check for duplicates
  for (let i = 1; i < sorted.length; i++) {
    if (getRank(sorted[i]) === getRank(sorted[i - 1])) return false;
  }

  // Check consecutive with jokers filling gaps
  return canFormConsecutiveRun(sorted.map(c => getRank(c)), jokerCount);
}

function canFormConsecutiveRun(sortedRanks: number[], jokerCount: number): boolean {
  if (sortedRanks.length === 0) return jokerCount >= 3;

  let jokersUsed = 0;
  let prev = sortedRanks[0];

  for (let i = 1; i < sortedRanks.length; i++) {
    const curr = sortedRanks[i];
    const gap = curr - prev - 1;
    if (gap < 0) return false; // duplicate
    jokersUsed += gap;
    if (jokersUsed > jokerCount) return false;
    prev = curr;
  }

  return true;
}

/** Validate a meld (auto-detect type) */
export function validateMeld(cards: Card[], config: GameConfig): MeldType | null {
  if (isValidSet(cards, config)) return MeldType.Set;
  if (isValidRun(cards, config)) return MeldType.Run;
  return null;
}

/** Calculate the point value of a meld (for opening threshold) */
export function calculateMeldPoints(meld: Meld, config: GameConfig): number {
  if (meld.type === MeldType.Run) {
    return calculateRunMeldPoints(meld, config);
  }
  let total = 0;
  for (const card of meld.cards) {
    total += getCardPoints(card, config);
  }
  return total;
}

/**
 * Calculate run meld points with context-aware Ace value:
 * A-2-3 → Ace = 1 (low); Q-K-A → Ace = 11 (high)
 * Jokers take the point value of the position they fill.
 */
function calculateRunMeldPoints(meld: Meld, config: GameConfig): number {
  const normals = meld.cards.filter(c => !c.isJoker);
  const jokerCount = meld.cards.length - normals.length;

  if (normals.length === 0) {
    return jokerCount * config.jokerValue;
  }

  const hasAce = normals.some(c => c.rank === Rank.Ace);

  // Determine if Ace is high: if any non-ace normal card has rank >= Queen
  let aceIsHigh = false;
  if (hasAce) {
    const nonAceRanks = normals.filter(c => c.rank !== Rank.Ace).map(c => c.rank!);
    aceIsHigh = nonAceRanks.length > 0 && Math.max(...nonAceRanks) >= Rank.Queen;
  }

  const getRank = (c: Card) => aceIsHigh && c.rank === Rank.Ace ? 14 : c.rank!;

  // Build sorted normal rank values
  const sortedRanks = normals.map(c => getRank(c)).sort((a, b) => a - b);

  // Build full sequence of rank positions (fill joker gaps)
  const minRank = sortedRanks[0];
  const positions: number[] = [];
  let idx = 0;
  let r = minRank;
  while (positions.length < meld.cards.length) {
    if (idx < sortedRanks.length && sortedRanks[idx] === r) {
      positions.push(r);
      idx++;
    } else {
      positions.push(r); // joker fills this position
    }
    r++;
  }

  // Sum values for each position
  const rankPointValue = (rank: number): number => {
    if (rank === 14) return config.aceHighValue; // Ace high
    if (rank >= Rank.Jack) return 10; // J/Q/K
    return rank; // 1-10
  };

  return positions.reduce((sum, pos) => sum + rankPointValue(pos), 0);
}

/** Get point value of a single card */
export function getCardPoints(card: Card, config: GameConfig): number {
  if (card.isJoker) return config.jokerValue;
  const rank = card.rank!;
  if (rank === Rank.Ace) return config.aceHighValue;
  if (rank >= Rank.Jack) return 10;
  return rank;
}

/** Build a Meld object from validated cards */
export function buildMeld(
  id: string,
  cards: Card[],
  type: MeldType,
): Meld {
  const jokerSubs: Record<number, { suit: string; rank: number }> = {};
  // For now, joker substitutions are computed when needed
  return { id, type, cards, jokerSubstitutions: jokerSubs };
}

/** Check if a card can be appended to an existing meld */
export function canLayoff(
  card: Card,
  meld: Meld,
  position: 'start' | 'end',
  config: GameConfig,
): boolean {
  const newCards = position === 'start'
    ? [card, ...meld.cards]
    : [...meld.cards, card];

  if (meld.type === MeldType.Set) return isValidSet(newCards, config);
  if (meld.type === MeldType.Run) return isValidRun(newCards, config);
  return false;
}

