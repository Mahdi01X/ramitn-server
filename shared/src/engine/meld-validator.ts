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

  // Sort by rank
  const sorted = [...normals].sort((a, b) => a.rank! - b.rank!);

  // Check for duplicates
  for (let i = 1; i < sorted.length; i++) {
    if (sorted[i].rank === sorted[i - 1].rank) return false;
  }

  // Check consecutive with jokers filling gaps
  const minRank = sorted[0].rank!;
  const maxRank = sorted[sorted.length - 1].rank!;
  const span = maxRank - minRank + 1;

  // The span should equal normal cards + jokers used to fill
  if (span > normals.length + jokers.length) return false;
  // Total cards should match span (no extra jokers appended beyond the run)
  // Actually jokers can extend a run beyond the normal card bounds
  // So total cards = normals.length + jokers.length, span <= total cards
  if (cards.length < 3) return false;

  // More precise: try to place all cards in a consecutive sequence
  return canFormConsecutiveRun(sorted, jokers.length);
}

function canFormConsecutiveRun(sortedNormals: Card[], jokerCount: number): boolean {
  if (sortedNormals.length === 0) return jokerCount >= 3;

  let jokersUsed = 0;
  let prev = sortedNormals[0].rank!;

  for (let i = 1; i < sortedNormals.length; i++) {
    const curr = sortedNormals[i].rank!;
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
  let total = 0;
  for (const card of meld.cards) {
    total += getCardPoints(card, config);
  }
  return total;
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

