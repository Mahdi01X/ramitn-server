import { Card } from '../types/card';
import { Meld, MeldType } from '../types/meld';
import { Player } from '../types/player';
import { GameConfig, DEFAULT_CONFIG } from '../types/game-config';
import { GameState, GamePhase, TurnStep, GameAction, GameError } from '../types/game-state';
import { createDeck, shuffle, deal } from './deck';
import { drawFromDeck, drawFromDiscard, meld, confirmOpening, cancelStaging, layoff, replaceJoker, discard } from './turn';
import { calculateRoundScores, checkGameEnd } from './scoring';

let gameIdCounter = 0;

/** Create a new game with initial state */
export function createGame(
  playerInfos: { id: string; name: string; isBot: boolean }[],
  config: Partial<GameConfig> = {},
): GameState {
  const fullConfig: GameConfig = { ...DEFAULT_CONFIG, ...config, numPlayers: playerInfos.length };

  const players: Player[] = playerInfos.map(info => ({
    id: info.id,
    name: info.name,
    hand: [],
    melds: [],
    score: 0,
    totalScore: 0,
    hasOpened: false,
    isBot: info.isBot,
    isConnected: true,
    drewFromDiscard: false,
    stagedMelds: [],
  }));

  const state: GameState = {
    id: `game_${++gameIdCounter}_${Date.now()}`,
    config: fullConfig,
    phase: GamePhase.Waiting,
    turnStep: TurnStep.Draw,
    players,
    currentPlayerIndex: 0,
    drawPile: [],
    discardPile: [],
    tableMelds: [],
    round: 0,
    turnCount: 0,
    winnerId: null,
    lastAction: null,
  };

  return state;
}

/** Start a new round (deal cards, etc.) */
export function startRound(state: GameState, seed?: number): GameState {
  const deck = shuffle(createDeck(state.config.numJokers), seed);
  const [hands, remaining] = deal(deck, state.players.length, state.config.cardsPerPlayer);

  // First player rotates each round: (round) % numPlayers
  const firstPlayerIdx = state.round % state.players.length;

  // First player gets 1 extra card (15 instead of 14) — Rami Tunisien rule
  const firstPlayerExtraCard = remaining.length > 0 ? remaining[0] : null;
  const drawPile = remaining.slice(1);

  const players = state.players.map((p, i) => ({
    ...p,
    hand: i === firstPlayerIdx && firstPlayerExtraCard
      ? [...hands[i], firstPlayerExtraCard]
      : hands[i],
    melds: [],
    hasOpened: false,
    score: 0,
    drewFromDiscard: false,
    stagedMelds: [],
  }));

  return {
    ...state,
    phase: GamePhase.PlayerTurn,
    turnStep: TurnStep.Play, // First player already has 15 cards → must play/discard
    players,
    drawPile,
    discardPile: [], // No initial discard — first player's discard creates it
    tableMelds: [],
    round: state.round + 1,
    turnCount: 0,
    currentPlayerIndex: firstPlayerIdx,
    lastAction: null,
  };
}

/**
 * Normalize action type aliases sent by different clients.
 * Flutter/simple-server use draw_deck / draw_discard,
 * shared/ canonical names are draw_from_deck / draw_from_discard.
 */
function normalizeAction(action: GameAction): GameAction {
  const aliases: Record<string, string> = {
    draw_deck: 'draw_from_deck',
    draw_discard: 'draw_from_discard',
  };
  const canonical = aliases[(action as any).type];
  if (canonical) {
    return { ...action, type: canonical } as GameAction;
  }
  return action;
}

/** Apply a game action and return the new state */
export function applyAction(state: GameState, rawAction: GameAction): GameState {
  const action = normalizeAction(rawAction);

  if (state.phase === GamePhase.GameEnd) {
    throw new GameError('GAME_ENDED', 'Game has already ended');
  }
  if (state.phase !== GamePhase.PlayerTurn) {
    throw new GameError('WRONG_PHASE', 'Game is not in play phase');
  }

  let newState: GameState;

  switch (action.type) {
    case 'draw_from_deck':
      newState = drawFromDeck(state, action.playerId);
      break;

    case 'draw_from_discard':
      newState = drawFromDiscard(state, action.playerId);
      break;

    case 'meld':
      newState = meld(state, action.playerId, action.cardIds);
      break;

    case 'confirm_opening':
      newState = confirmOpening(state, action.playerId);
      break;

    case 'cancel_staging':
      newState = cancelStaging(state, action.playerId);
      break;

    case 'layoff':
      newState = layoff(state, action.playerId, action.cardId, action.targetMeldId, action.position);
      break;

    case 'replace_joker':
      newState = replaceJoker(state, action.playerId, action.cardId, action.targetMeldId, action.jokerCardId);
      break;

    case 'discard':
      newState = discard(state, action.playerId, action.cardId);
      // After discard, apply penalty and check round end, advance turn
      newState = afterDiscard(newState, action.playerId);
      break;

    default:
      throw new GameError('UNKNOWN_ACTION', `Unknown action type: ${(action as any).type}`);
  }

  return newState;
}

/** Handle post-discard logic: apply penalty, check round end, advance turn */
function afterDiscard(state: GameState, playerId: string): GameState {
  const player = state.players.find(p => p.id === playerId)!;

  // Apply discard-draw penalty: drew from discard but didn't open → +penalty
  if (player.drewFromDiscard && !player.hasOpened && state.config.discardDrawPenalty > 0) {
    const players = state.players.map(p =>
      p.id === playerId
        ? { ...p, totalScore: p.totalScore + state.config.discardDrawPenalty, drewFromDiscard: false }
        : p,
    );
    state = { ...state, players };
  }

  // Reset drewFromDiscard for next turn
  const resetPlayers = state.players.map(p =>
    p.id === playerId ? { ...p, drewFromDiscard: false } : p,
  );
  state = { ...state, players: resetPlayers };

  // Check if player has emptied their hand (round win)
  const updatedPlayer = state.players.find(p => p.id === playerId)!;
  if (updatedPlayer.hand.length === 0) {
    return endRound(state, playerId);
  }

  // Advance to next player
  return advanceTurn(state);
}

/** End the current round, calculate scores */
function endRound(state: GameState, roundWinnerId: string): GameState {
  const roundScores = calculateRoundScores(state);

  const players = state.players.map(p => ({
    ...p,
    score: roundScores[p.id],
    totalScore: p.totalScore + roundScores[p.id],
  }));

  let newState: GameState = {
    ...state,
    players,
    phase: GamePhase.RoundEnd,
    winnerId: roundWinnerId,
  };

  // Check game end
  const endCheck = checkGameEnd(newState);
  if (endCheck.isEnd) {
    return {
      ...newState,
      phase: GamePhase.GameEnd,
      winnerId: endCheck.winnerId,
    };
  }

  return newState;
}

/** Advance to the next player's turn */
function advanceTurn(state: GameState): GameState {
  let nextIdx = (state.currentPlayerIndex + 1) % state.players.length;

  // Skip eliminated players (in elimination mode)
  if (state.config.scoringMode === 'elimination') {
    let attempts = 0;
    while (
      state.players[nextIdx].totalScore >= state.config.eliminationThreshold &&
      attempts < state.players.length
    ) {
      nextIdx = (nextIdx + 1) % state.players.length;
      attempts++;
    }
  }

  return {
    ...state,
    currentPlayerIndex: nextIdx,
    turnStep: TurnStep.Draw,
    turnCount: state.turnCount + 1,
  };
}

/** Get valid actions for the current player */
export function getValidActions(state: GameState): GameAction['type'][] {
  if (state.phase !== GamePhase.PlayerTurn) return [];

  const player = state.players[state.currentPlayerIndex];
  const actions: GameAction['type'][] = [];

  if (state.turnStep === TurnStep.Draw) {
    if (state.drawPile.length > 0 || state.discardPile.length > 1) {
      actions.push('draw_from_deck');
    }
    if (state.discardPile.length > 0) {
      actions.push('draw_from_discard');
    }
  }

  if (state.turnStep === TurnStep.Play) {
    actions.push('meld', 'discard');
    if (player.hasOpened) {
      actions.push('layoff');
      if (!state.config.jokerLocked) {
        actions.push('replace_joker');
      }
    } else if (player.stagedMelds.length > 0) {
      actions.push('confirm_opening', 'cancel_staging');
    }
  }

  return actions;
}

/** Sanitize state for a specific player (hide other hands) */
export function sanitizeStateForPlayer(
  state: GameState,
  playerId: string,
): import('../types/events').SanitizedGameState {
  const myPlayer = state.players.find(p => p.id === playerId);

  return {
    id: state.id,
    phase: state.phase,
    turnStep: state.turnStep,
    currentPlayerIndex: state.currentPlayerIndex,
    players: state.players.map(p => ({
      id: p.id,
      name: p.name,
      handCount: p.hand.length,
      melds: p.melds,
      totalScore: p.totalScore,
      hasOpened: p.hasOpened,
      isBot: p.isBot,
      isConnected: p.isConnected,
    })),
    myHand: myPlayer?.hand ?? [],
    drawPileCount: state.drawPile.length,
    discardPile: state.discardPile,
    tableMelds: state.tableMelds,
    round: state.round,
    turnCount: state.turnCount,
    config: state.config,
  };
}


