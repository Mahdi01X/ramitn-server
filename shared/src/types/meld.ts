import { Card } from './card';

export enum MeldType {
  /** 3+ cards of same rank, different suits */
  Set = 'set',
  /** 3+ consecutive cards of same suit */
  Run = 'run',
}

export interface Meld {
  id: string;
  type: MeldType;
  cards: Card[];
  /** Which card IDs are jokers acting as substitutes */
  jokerSubstitutions: Record<number, { suit: string; rank: number }>;
}

