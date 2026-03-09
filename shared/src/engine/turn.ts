import { Card } from '../types/card';
import { GameState, TurnStep, GameError } from '../types/game-state';
import { Meld } from '../types/meld';
import { validateMeld, buildMeld, canLayoff } from './meld-validator';
import { canOpen, validateOpening } from './opening';

/** Player draws from the draw pile */
export function drawFromDeck(state: GameState, playerId: string): GameState {
  assertCurrentPlayer(state, playerId);
  assertTurnStep(state, TurnStep.Draw);

  if (state.drawPile.length === 0) {
    // Reshuffle discard pile (keep top card)
    if (state.discardPile.length <= 1) {
      throw new GameError('EMPTY_DECK', 'No cards left to draw');
    }
    const topCard = state.discardPile[state.discardPile.length - 1];
    const toShuffle = state.discardPile.slice(0, -1);
    // Simple shuffle
    for (let i = toShuffle.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [toShuffle[i], toShuffle[j]] = [toShuffle[j], toShuffle[i]];
    }
    state = {
      ...state,
      drawPile: toShuffle,
      discardPile: [topCard],
    };
  }

  const drawnCard = state.drawPile[0];
  const newDrawPile = state.drawPile.slice(1);

  const players = state.players.map(p =>
    p.id === playerId
      ? { ...p, hand: [...p.hand, drawnCard], drewFromDiscard: false }
      : p,
  );

  return {
    ...state,
    players,
    drawPile: newDrawPile,
    turnStep: TurnStep.Play,
    lastAction: { type: 'draw_from_deck', playerId },
  };
}

/** Player draws from the discard pile */
export function drawFromDiscard(state: GameState, playerId: string): GameState {
  assertCurrentPlayer(state, playerId);
  assertTurnStep(state, TurnStep.Draw);

  if (state.discardPile.length === 0) {
    throw new GameError('EMPTY_DISCARD', 'Discard pile is empty');
  }

  const drawnCard = state.discardPile[state.discardPile.length - 1];
  const player = state.players.find(p => p.id === playerId)!;

  // Duplicate protection: can't take from discard if you have exact duplicate (same rank+suit)
  if (state.config.duplicateProtection && !drawnCard.isJoker) {
    const hasDuplicate = player.hand.some(
      c => !c.isJoker && c.rank === drawnCard.rank && c.suit === drawnCard.suit,
    );
    if (hasDuplicate) {
      throw new GameError(
        'DUPLICATE_CARD',
        'Cannot draw from discard: you already have a card with the same rank and suit',
      );
    }
  }

  const newDiscard = state.discardPile.slice(0, -1);

  const players = state.players.map(p =>
    p.id === playerId
      ? { ...p, hand: [...p.hand, drawnCard], drewFromDiscard: true }
      : p,
  );

  return {
    ...state,
    players,
    discardPile: newDiscard,
    turnStep: TurnStep.Play,
    lastAction: { type: 'draw_from_discard', playerId },
  };
}

/** Player places a meld — stages it if not yet opened, places directly if already opened */
export function meld(
  state: GameState,
  playerId: string,
  cardIds: number[],
): GameState {
  assertCurrentPlayer(state, playerId);
  assertTurnStep(state, TurnStep.Play);

  const player = state.players.find(p => p.id === playerId)!;
  const cards = cardIds.map(id => {
    const card = player.hand.find(c => c.id === id);
    if (!card) throw new GameError('CARD_NOT_IN_HAND', `Card ${id} not in hand`);
    return card;
  });

  const meldType = validateMeld(cards, state.config);
  if (!meldType) {
    throw new GameError('INVALID_MELD', 'Cards do not form a valid combination');
  }

  const newMeld = buildMeld(
    `meld_${Date.now()}_${Math.random().toString(36).slice(2)}`,
    cards,
    meldType,
  );

  // If player hasn't opened yet, stage the meld for batch opening
  if (!player.hasOpened) {
    // Check that staging this meld still leaves at least 1 card for discard
    const alreadyStagedCardIds = new Set(
      player.stagedMelds.flatMap(m => m.cards.map(c => c.id)),
    );
    const allStagedCardIds = new Set([...alreadyStagedCardIds, ...cardIds]);
    const remainingCards = player.hand.filter(c => !allStagedCardIds.has(c.id));
    if (remainingCards.length < 1) {
      throw new GameError(
        'MUST_KEEP_CARD',
        'You must keep at least 1 card to discard',
      );
    }

    const players = state.players.map(p =>
      p.id === playerId
        ? { ...p, stagedMelds: [...p.stagedMelds, newMeld] }
        : p,
    );

    return {
      ...state,
      players,
      lastAction: { type: 'meld', playerId, cardIds },
    };
  }

  // Already opened — place meld directly
  // Check keep-1-card rule
  const newHand = player.hand.filter(c => !cardIds.includes(c.id));
  if (newHand.length < 1) {
    throw new GameError(
      'MUST_KEEP_CARD',
      'You must keep at least 1 card to discard',
    );
  }

  const players = state.players.map(p =>
    p.id === playerId
      ? { ...p, hand: newHand, melds: [...p.melds, newMeld] }
      : p,
  );

  return {
    ...state,
    players,
    tableMelds: [...state.tableMelds, newMeld],
    lastAction: { type: 'meld', playerId, cardIds },
  };
}

/** Confirm batch opening: validate all staged melds meet opening requirements */
export function confirmOpening(state: GameState, playerId: string): GameState {
  assertCurrentPlayer(state, playerId);
  assertTurnStep(state, TurnStep.Play);

  const player = state.players.find(p => p.id === playerId)!;

  if (player.hasOpened) {
    throw new GameError('ALREADY_OPENED', 'Player has already opened');
  }

  if (player.stagedMelds.length === 0) {
    throw new GameError('NO_STAGED_MELDS', 'No melds staged for opening');
  }

  // Validate opening with all staged melds
  const opening = validateOpening(player.stagedMelds, state.config);
  if (!opening.valid) {
    throw new GameError(
      'OPENING_NOT_MET',
      opening.reason ?? `Need ${state.config.openingThreshold} points to open`,
    );
  }

  // Check keep-1-card rule
  const stagedCardIds = new Set(
    player.stagedMelds.flatMap(m => m.cards.map(c => c.id)),
  );
  const newHand = player.hand.filter(c => !stagedCardIds.has(c.id));
  if (newHand.length < 1) {
    throw new GameError(
      'MUST_KEEP_CARD',
      'You must keep at least 1 card to discard after opening',
    );
  }

  // Commit all staged melds
  const players = state.players.map(p =>
    p.id === playerId
      ? {
          ...p,
          hand: newHand,
          melds: [...p.melds, ...p.stagedMelds],
          stagedMelds: [],
          hasOpened: true,
        }
      : p,
  );

  return {
    ...state,
    players,
    tableMelds: [...state.tableMelds, ...player.stagedMelds],
    lastAction: { type: 'confirm_opening', playerId },
  };
}

/** Cancel all staged melds (cards stay in hand) */
export function cancelStaging(state: GameState, playerId: string): GameState {
  assertCurrentPlayer(state, playerId);

  const players = state.players.map(p =>
    p.id === playerId ? { ...p, stagedMelds: [] } : p,
  );

  return {
    ...state,
    players,
    lastAction: { type: 'cancel_staging', playerId },
  };
}

/** Player lays off a card onto an existing meld */
export function layoff(
  state: GameState,
  playerId: string,
  cardId: number,
  targetMeldId: string,
  position: 'start' | 'end',
): GameState {
  assertCurrentPlayer(state, playerId);
  assertTurnStep(state, TurnStep.Play);

  const player = state.players.find(p => p.id === playerId)!;
  if (!player.hasOpened) {
    throw new GameError('NOT_OPENED', 'Must open before laying off');
  }

  const card = player.hand.find(c => c.id === cardId);
  if (!card) throw new GameError('CARD_NOT_IN_HAND', `Card ${cardId} not in hand`);

  // Check keep-1-card rule
  if (player.hand.length <= 1) {
    throw new GameError('MUST_KEEP_CARD', 'You must keep at least 1 card to discard');
  }

  const meldIdx = state.tableMelds.findIndex(m => m.id === targetMeldId);
  if (meldIdx === -1) throw new GameError('MELD_NOT_FOUND', 'Target meld not found');

  const targetMeld = state.tableMelds[meldIdx];

  if (!canLayoff(card, targetMeld, position, state.config)) {
    throw new GameError('INVALID_LAYOFF', 'Card cannot be added to this meld');
  }

  const newCards = position === 'start'
    ? [card, ...targetMeld.cards]
    : [...targetMeld.cards, card];

  const updatedMeld = { ...targetMeld, cards: newCards };
  const tableMelds = [...state.tableMelds];
  tableMelds[meldIdx] = updatedMeld;

  const newHand = player.hand.filter(c => c.id !== cardId);

  // Update the meld in the owner's melds list too
  const players = state.players.map(p => {
    if (p.id === playerId) {
      return { ...p, hand: newHand };
    }
    const pm = p.melds.findIndex(m => m.id === targetMeldId);
    if (pm !== -1) {
      const pMelds = [...p.melds];
      pMelds[pm] = updatedMeld;
      return { ...p, melds: pMelds };
    }
    return p;
  });

  return {
    ...state,
    players,
    tableMelds,
    lastAction: { type: 'layoff', playerId, cardId, targetMeldId, position },
  };
}

/** Player replaces a joker in a meld with the actual card */
export function replaceJoker(
  state: GameState,
  playerId: string,
  cardId: number,
  targetMeldId: string,
  jokerCardId: number,
): GameState {
  assertCurrentPlayer(state, playerId);
  assertTurnStep(state, TurnStep.Play);

  if (state.config.jokerLocked) {
    throw new GameError('JOKER_LOCKED', 'Jokers cannot be retrieved in this game');
  }

  const player = state.players.find(p => p.id === playerId)!;
  if (!player.hasOpened) {
    throw new GameError('NOT_OPENED', 'Must open before replacing jokers');
  }

  const card = player.hand.find(c => c.id === cardId);
  if (!card) throw new GameError('CARD_NOT_IN_HAND', `Card ${cardId} not in hand`);

  const meldIdx = state.tableMelds.findIndex(m => m.id === targetMeldId);
  if (meldIdx === -1) throw new GameError('MELD_NOT_FOUND', 'Target meld not found');

  const targetMeld = state.tableMelds[meldIdx];
  const jokerIdx = targetMeld.cards.findIndex(c => c.id === jokerCardId && c.isJoker);
  if (jokerIdx === -1) throw new GameError('JOKER_NOT_FOUND', 'Joker not found in meld');

  // Replace joker with the card
  const jokerCard = targetMeld.cards[jokerIdx];
  const newCards = [...targetMeld.cards];
  newCards[jokerIdx] = card;

  // Validate the meld is still valid after replacement
  if (!validateMeld(newCards, state.config)) {
    throw new GameError('INVALID_REPLACEMENT', 'Replacement does not produce a valid meld');
  }

  const updatedMeld = { ...targetMeld, cards: newCards };
  const tableMelds = [...state.tableMelds];
  tableMelds[meldIdx] = updatedMeld;

  // Remove played card from hand, add joker to hand
  const newHand = player.hand.filter(c => c.id !== cardId);
  newHand.push(jokerCard);

  const players = state.players.map(p => {
    if (p.id === playerId) return { ...p, hand: newHand };
    const pm = p.melds.findIndex(m => m.id === targetMeldId);
    if (pm !== -1) {
      const pMelds = [...p.melds];
      pMelds[pm] = updatedMeld;
      return { ...p, melds: pMelds };
    }
    return p;
  });

  return {
    ...state,
    players,
    tableMelds,
    lastAction: { type: 'replace_joker', playerId, cardId, targetMeldId, jokerCardId },
  };
}

/** Player discards a card to end their play phase */
export function discard(
  state: GameState,
  playerId: string,
  cardId: number,
): GameState {
  assertCurrentPlayer(state, playerId);
  assertTurnStep(state, TurnStep.Play);

  const player = state.players.find(p => p.id === playerId)!;
  const card = player.hand.find(c => c.id === cardId);
  if (!card) throw new GameError('CARD_NOT_IN_HAND', `Card ${cardId} not in hand`);

  const newHand = player.hand.filter(c => c.id !== cardId);
  const players = state.players.map(p =>
    p.id === playerId ? { ...p, hand: newHand } : p,
  );

  return {
    ...state,
    players,
    discardPile: [...state.discardPile, card],
    lastAction: { type: 'discard', playerId, cardId },
  };
}

// ─── Helpers ─────────────────────────────────────────────────

function assertCurrentPlayer(state: GameState, playerId: string): void {
  const current = state.players[state.currentPlayerIndex];
  if (current.id !== playerId) {
    throw new GameError('NOT_YOUR_TURN', 'It is not your turn');
  }
}

function assertTurnStep(state: GameState, expected: TurnStep): void {
  if (state.turnStep !== expected) {
    throw new GameError(
      'WRONG_STEP',
      `Expected turn step '${expected}', got '${state.turnStep}'`,
    );
  }
}




