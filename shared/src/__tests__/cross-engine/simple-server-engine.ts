/**
 * Extracted pure-function engine from simple-server/server.js
 * for cross-engine comparison testing.
 * Card IDs are re-based to start at 0 (shared/ convention).
 */

// ─── Types ──────────────────────────────────────────────────

export interface SSCard {
  id: number;
  suit: string;
  rank: string;
  isJoker: boolean;
}

// ─── Constants ──────────────────────────────────────────────

const SUITS = ['hearts', 'diamonds', 'clubs', 'spades'];
const RANKS = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

export function rankValue(rank: string): number {
  if (rank === 'A') return 1;
  if (rank === 'J' || rank === 'Q' || rank === 'K') return 10;
  return parseInt(rank);
}

export function rankIndex(rank: string): number {
  return RANKS.indexOf(rank);
}

// ─── Meld Validation (exact port from simple-server/server.js) ─

export function ssIsValidSet(cards: SSCard[]): boolean {
  if (cards.length < 3 || cards.length > 4) return false;
  const nonJokers = cards.filter(c => !c.isJoker);
  if (nonJokers.length === 0) return false;
  const rank = nonJokers[0].rank;
  if (!nonJokers.every(c => c.rank === rank)) return false;
  const suits = nonJokers.map(c => c.suit);
  if (new Set(suits).size !== suits.length) return false;
  return true;
}

export function ssIsValidRun(cards: SSCard[]): boolean {
  if (cards.length < 3) return false;
  const nonJokers = cards.filter(c => !c.isJoker);
  if (nonJokers.length === 0) return false;
  const suit = nonJokers[0].suit;
  if (!nonJokers.every(c => c.suit === suit)) return false;

  const sorted = [...cards].sort((a, b) => {
    if (a.isJoker) return 1;
    if (b.isJoker) return -1;
    return rankIndex(a.rank) - rankIndex(b.rank);
  });

  let jokerCount = cards.filter(c => c.isJoker).length;
  const positions: number[] = [];
  for (const c of sorted) {
    if (!c.isJoker) positions.push(rankIndex(c.rank));
  }
  positions.sort((a, b) => a - b);

  for (let i = 1; i < positions.length; i++) {
    const gap = positions[i] - positions[i - 1] - 1;
    if (gap < 0) return false;
    jokerCount -= gap;
    if (jokerCount < 0) return false;
  }
  return true;
}

export function ssIsValidMeld(cards: SSCard[]): boolean {
  return ssIsValidSet(cards) || ssIsValidRun(cards);
}

export function ssGetMeldType(cards: SSCard[]): 'set' | 'run' | null {
  if (ssIsValidSet(cards)) return 'set';
  if (ssIsValidRun(cards)) return 'run';
  return null;
}

// ─── Point Calculation (exact port from simple-server/server.js) ─

export function ssCalculateMeldPoints(cards: SSCard[]): number {
  let pts = 0;
  const type = ssGetMeldType(cards);
  if (type === 'run') {
    const nonJokers = cards.filter(c => !c.isJoker)
      .sort((a, b) => rankIndex(a.rank) - rankIndex(b.rank));
    const minIdx = rankIndex(nonJokers[0].rank);
    for (let i = 0; i < cards.length; i++) {
      const rIdx = minIdx + i;
      if (rIdx < RANKS.length) {
        pts += rankValue(RANKS[rIdx]);
      }
    }
  } else {
    const nonJokers = cards.filter(c => !c.isJoker);
    const val = rankValue(nonJokers[0].rank);
    pts = val * cards.length;
  }
  return pts;
}

export function ssCalculateHandPenalty(hand: SSCard[]): number {
  let total = 0;
  for (const c of hand) {
    if (c.isJoker) { total += 30; continue; }
    if (c.rank === 'A') { total += 11; continue; }
    total += rankValue(c.rank);
  }
  return total;
}

// ─── Card Factories (for test scenarios) ─────────────────────

let ssNextId = 0;

export function ssCard(rank: string, suit: string, id?: number): SSCard {
  return { id: id ?? ssNextId++, suit, rank, isJoker: false };
}

export function ssJoker(id?: number): SSCard {
  return { id: id ?? ssNextId++, suit: 'joker', rank: 'JOKER', isJoker: true };
}

export function ssResetId(start = 0): void {
  ssNextId = start;
}
