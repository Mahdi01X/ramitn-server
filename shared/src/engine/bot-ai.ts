import { Card } from '../types/card';
import { Meld, MeldType } from '../types/meld';
import { GameState, GameAction, TurnStep } from '../types/game-state';
import { GameConfig } from '../types/game-config';
import { validateMeld, buildMeld, canLayoff, getCardPoints } from './meld-validator';
import { canOpen } from './opening';

/**
 * Simple greedy bot AI.
 * Strategy:
 * 1. Draw phase: prefer discard pile if it helps form a meld, else draw from deck
 * 2. Play phase: meld any valid combinations, layoff where possible
 * 3. Discard: highest-value card that doesn't break a potential meld
 */
export function computeBotMove(state: GameState, playerId: string): GameAction {
  const player = state.players.find(p => p.id === playerId)!;

  if (state.turnStep === TurnStep.Draw) {
    return decideDraw(state, player);
  }

  // Play phase: try to meld, then discard
  const meldAction = tryMeld(state, player);
  if (meldAction) return meldAction;

  const layoffAction = tryLayoff(state, player);
  if (layoffAction) return layoffAction;

  // Must discard
  return decideDiscard(state, player);
}

function decideDraw(state: GameState, player: import('../types/player').Player): GameAction {
  // Simple: check if top of discard helps form a meld
  if (state.discardPile.length > 0) {
    const topDiscard = state.discardPile[state.discardPile.length - 1];
    const handWithDiscard = [...player.hand, topDiscard];

    // Check if adding this card creates any 3-card meld
    if (findMeldWithCard(handWithDiscard, topDiscard, state.config)) {
      return { type: 'draw_from_discard', playerId: player.id };
    }
  }

  return { type: 'draw_from_deck', playerId: player.id };
}

function tryMeld(state: GameState, player: import('../types/player').Player): GameAction | null {
  const hand = player.hand;
  if (hand.length < 3) return null;

  // Try all 3-card combinations (greedy, not optimal)
  for (let i = 0; i < hand.length - 2; i++) {
    for (let j = i + 1; j < hand.length - 1; j++) {
      for (let k = j + 1; k < hand.length; k++) {
        const cards = [hand[i], hand[j], hand[k]];
        const type = validateMeld(cards, state.config);
        if (type) {
          // Check opening requirement (threshold + clean run)
          if (!player.hasOpened && state.config.openingThreshold > 0) {
            const tempMeld = buildMeld('temp', cards, type);
            if (!canOpen([tempMeld], state.config, false)) continue;
          }
          return {
            type: 'meld',
            playerId: player.id,
            cardIds: cards.map(c => c.id),
          };
        }
      }
    }
  }

  // Try 4-card combos
  for (let i = 0; i < hand.length - 3; i++) {
    for (let j = i + 1; j < hand.length - 2; j++) {
      for (let k = j + 1; k < hand.length - 1; k++) {
        for (let l = k + 1; l < hand.length; l++) {
          const cards = [hand[i], hand[j], hand[k], hand[l]];
          const type = validateMeld(cards, state.config);
          if (type) {
            if (!player.hasOpened && state.config.openingThreshold > 0) {
              const tempMeld = buildMeld('temp', cards, type);
              if (!canOpen([tempMeld], state.config, false)) continue;
            }
            return {
              type: 'meld',
              playerId: player.id,
              cardIds: cards.map(c => c.id),
            };
          }
        }
      }
    }
  }

  return null;
}

function tryLayoff(state: GameState, player: import('../types/player').Player): GameAction | null {
  if (!player.hasOpened) return null;

  for (const card of player.hand) {
    for (const tableMeld of state.tableMelds) {
      if (canLayoff(card, tableMeld, 'end', state.config)) {
        return {
          type: 'layoff',
          playerId: player.id,
          cardId: card.id,
          targetMeldId: tableMeld.id,
          position: 'end',
        };
      }
      if (canLayoff(card, tableMeld, 'start', state.config)) {
        return {
          type: 'layoff',
          playerId: player.id,
          cardId: card.id,
          targetMeldId: tableMeld.id,
          position: 'start',
        };
      }
    }
  }
  return null;
}

function decideDiscard(_state: GameState, player: import('../types/player').Player): GameAction {
  // Discard the highest-value card
  const config = _state.config;
  const sorted = [...player.hand].sort(
    (a, b) => getCardPoints(b, config) - getCardPoints(a, config),
  );
  return {
    type: 'discard',
    playerId: player.id,
    cardId: sorted[0].id,
  };
}

function findMeldWithCard(hand: Card[], targetCard: Card, config: GameConfig): boolean {
  for (let i = 0; i < hand.length - 1; i++) {
    for (let j = i + 1; j < hand.length; j++) {
      const cards = [targetCard, hand[i], hand[j]];
      // Avoid using the same card twice
      const ids = new Set(cards.map(c => c.id));
      if (ids.size < 3) continue;
      if (validateMeld(cards, config)) return true;
    }
  }
  return false;
}



