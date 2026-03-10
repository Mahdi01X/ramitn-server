import { Card } from '../types/card';
import { GameConfig } from '../types/game-config';
import { GameState } from '../types/game-state';
import { getCardPoints } from './meld-validator';

/** Calculate the penalty points for a hand of cards */
export function calculateHandPenalty(hand: Card[], config: GameConfig): number {
  return hand.reduce((sum, card) => sum + getCardPoints(card, config), 0);
}

/** Calculate round scores for all players */
export function calculateRoundScores(state: GameState): Record<string, number> {
  const scores: Record<string, number> = {};
  for (const player of state.players) {
    if (player.hand.length === 0) {
      // Winner: 0 points
      scores[player.id] = 0;
    } else if (!player.hasOpened) {
      // Never opened → minimum 100 pts penalty (or more if accumulated from discard draw penalties)
      scores[player.id] = Math.max(100, player.score);
    } else {
      // Opened but has remaining cards → count card points + any accumulated penalties
      scores[player.id] = player.score + calculateHandPenalty(player.hand, state.config);
    }
  }
  return scores;
}

/** Check if game should end based on config */
export function checkGameEnd(state: GameState): {
  isEnd: boolean;
  winnerId: string | null;
  reason?: string;
} {
  if (state.round < state.config.maxRounds) {
    if (state.config.scoringMode === 'elimination') {
      // Check if only one player remains under threshold
      const alive = state.players.filter(
        p => p.totalScore < state.config.eliminationThreshold,
      );
      if (alive.length <= 1) {
        return {
          isEnd: true,
          winnerId: alive[0]?.id ?? null,
          reason: 'elimination',
        };
      }
    }
    return { isEnd: false, winnerId: null };
  }

  // Max rounds reached: lowest total score wins
  const sorted = [...state.players].sort((a, b) => a.totalScore - b.totalScore);
  return {
    isEnd: true,
    winnerId: sorted[0].id,
    reason: 'max_rounds',
  };
}


