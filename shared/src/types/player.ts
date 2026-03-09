import { Card } from './card';
import { Meld } from './meld';

export interface Player {
  id: string;
  name: string;
  hand: Card[];
  melds: Meld[];
  score: number;
  /** Cumulative score across all rounds */
  totalScore: number;
  hasOpened: boolean;
  isBot: boolean;
  isConnected: boolean;
  /** True if player drew from discard this turn (for penalty tracking) */
  drewFromDiscard: boolean;
  /** Melds staged for batch opening (not yet committed) */
  stagedMelds: Meld[];
}

