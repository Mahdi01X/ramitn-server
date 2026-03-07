export interface GameConfig {
  numPlayers: number;
  numJokers: number;
  cardsPerPlayer: number;
  openingThreshold: number;
  /** Opening must include at least one clean run (no jokers) */
  openingRequiresCleanRun: boolean;
  jokerValue: number;
  aceHighValue: number;
  maxRounds: number;
  scoringMode: 'cumulative' | 'elimination';
  eliminationThreshold: number;
  jokerLocked: boolean;
  maxJokersPerMeld: number;
  turnTimeoutSeconds: number; // 0 = no timer
}

export const DEFAULT_CONFIG: GameConfig = {
  numPlayers: 4,
  numJokers: 4,
  cardsPerPlayer: 14,
  openingThreshold: 71,
  openingRequiresCleanRun: true,
  jokerValue: 30,
  aceHighValue: 11,
  maxRounds: 5,
  scoringMode: 'cumulative',
  eliminationThreshold: 100,
  jokerLocked: false,
  maxJokersPerMeld: 1,
  turnTimeoutSeconds: 60,
};


