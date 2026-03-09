import { Card, Suit, Rank } from '../types/card';
import { Meld, MeldType } from '../types/meld';
import { GameConfig, DEFAULT_CONFIG } from '../types/game-config';
import { Player } from '../types/player';
import { GameState, GamePhase, TurnStep } from '../types/game-state';

// ─── Card factories ──────────────────────────────────────────

let nextId = 1000;

export function card(rank: Rank, suit: Suit, id?: number): Card {
  return { id: id ?? nextId++, suit, rank, isJoker: false, deckIndex: 0 };
}

export function joker(id?: number): Card {
  return { id: id ?? nextId++, suit: null, rank: null, isJoker: true, deckIndex: 0 };
}

export function cardFromStr(str: string, id?: number): Card {
  if (str === 'JK' || str === '🃏') return joker(id);
  const rankMap: Record<string, Rank> = {
    'A': Rank.Ace, '2': Rank.Two, '3': Rank.Three, '4': Rank.Four,
    '5': Rank.Five, '6': Rank.Six, '7': Rank.Seven, '8': Rank.Eight,
    '9': Rank.Nine, '10': Rank.Ten, 'J': Rank.Jack, 'Q': Rank.Queen, 'K': Rank.King,
  };
  const suitMap: Record<string, Suit> = {
    '♥': Suit.Hearts, '♦': Suit.Diamonds, '♣': Suit.Clubs, '♠': Suit.Spades,
    'h': Suit.Hearts, 'd': Suit.Diamonds, 'c': Suit.Clubs, 's': Suit.Spades,
  };
  const suitChar = str.slice(-1);
  const rankStr = str.slice(0, -1);
  return card(rankMap[rankStr], suitMap[suitChar], id);
}

// ─── Meld factories ─────────────────────────────────────────

export function makeMeld(type: MeldType, cards: Card[], id?: string): Meld {
  return {
    id: id ?? `test_meld_${nextId++}`,
    type,
    cards,
    jokerSubstitutions: {},
  };
}

export function makeRun(cards: Card[], id?: string): Meld {
  return makeMeld(MeldType.Run, cards, id);
}

export function makeSet(cards: Card[], id?: string): Meld {
  return makeMeld(MeldType.Set, cards, id);
}

// ─── Player factory ─────────────────────────────────────────

export function makePlayer(overrides: Partial<Player> & { id: string }): Player {
  return {
    name: overrides.id,
    hand: [],
    melds: [],
    score: 0,
    totalScore: 0,
    hasOpened: false,
    isBot: false,
    isConnected: true,
    drewFromDiscard: false,
    stagedMelds: [],
    ...overrides,
  };
}

// ─── Game state factory ─────────────────────────────────────

export function makeGameState(overrides: Partial<GameState> = {}): GameState {
  return {
    id: 'test_game',
    config: { ...DEFAULT_CONFIG },
    phase: GamePhase.PlayerTurn,
    turnStep: TurnStep.Play,
    players: [
      makePlayer({ id: 'p1' }),
      makePlayer({ id: 'p2' }),
    ],
    currentPlayerIndex: 0,
    drawPile: [],
    discardPile: [],
    tableMelds: [],
    round: 1,
    turnCount: 0,
    winnerId: null,
    lastAction: null,
    ...overrides,
  };
}

// ─── Reset ID counter (for deterministic tests) ─────────────

export function resetIdCounter(start: number = 1000): void {
  nextId = start;
}
