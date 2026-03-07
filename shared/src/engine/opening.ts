import { Meld, MeldType } from '../types/meld';
import { GameConfig } from '../types/game-config';
import { calculateMeldPoints } from './meld-validator';

/**
 * A "clean run" is a Run (suite) that contains zero jokers.
 */
export function isCleanRun(meld: Meld): boolean {
  return (
    meld.type === MeldType.Run &&
    meld.cards.every(c => !c.isJoker)
  );
}

/**
 * Check if a player can open (meet the opening threshold)
 * with the given melds.
 *
 * Rules:
 * - Total points of melds >= openingThreshold (default 71)
 * - If openingRequiresCleanRun is true (default), at least one meld
 *   must be a clean run (suite without any joker)
 */
export function canOpen(
  melds: Meld[],
  config: GameConfig,
  alreadyOpened: boolean,
): boolean {
  if (alreadyOpened) return true;
  if (config.openingThreshold <= 0) return true;

  const total = melds.reduce(
    (sum, meld) => sum + calculateMeldPoints(meld, config),
    0,
  );

  if (total < config.openingThreshold) return false;

  // Must include at least one clean run (no jokers) if required
  if (config.openingRequiresCleanRun) {
    const hasCleanRun = melds.some(m => isCleanRun(m));
    if (!hasCleanRun) return false;
  }

  return true;
}

/**
 * Validate that a first-time meld meets the opening requirement.
 * Returns the total points of the melds being placed, validity, and failure reason.
 */
export function validateOpening(
  melds: Meld[],
  config: GameConfig,
): { valid: boolean; points: number; reason?: string } {
  const points = melds.reduce(
    (sum, meld) => sum + calculateMeldPoints(meld, config),
    0,
  );

  if (config.openingThreshold > 0 && points < config.openingThreshold) {
    return {
      valid: false,
      points,
      reason: `Il faut ${config.openingThreshold} points pour ouvrir (vous avez ${points})`,
    };
  }

  if (config.openingRequiresCleanRun && !melds.some(m => isCleanRun(m))) {
    return {
      valid: false,
      points,
      reason: 'L\'ouverture nécessite au moins une suite sans joker',
    };
  }

  return { valid: true, points };
}


