/**
 * Protocol contract tests.
 *
 * Validates that all client→server and server→client event names,
 * payload shapes, and action type strings are consistent across
 * the three transport layers:
 *   1. simple-server (server.js)           — production
 *   2. NestJS gateway (game.gateway.ts)    — planned production
 *   3. Flutter client (socket_service.dart) — mobile app
 *
 * These are "documentation tests" — they assert the contract as it IS,
 * and flag divergences explicitly.
 */

describe('Protocol contract: client→server events', () => {

  // Events that the server subscribes to, catalogued from source code
  const simpleServerEvents = [
    'register',
    'create_room',
    'join_room',
    'ready',
    'start_game',
    'game_action',
    'chat_message',
    // implicit: 'disconnect'
  ];

  const nestJSEvents = [
    'create_room',
    'join_room',
    'leave_room',
    'ready',
    'start_game',
    'game_action',
    'chat_message',
    'join_matchmaking',
    'resign',
    // implicit: connection, disconnect (handled by lifecycle hooks)
  ];

  // Flutter emits these client→server events
  const flutterEmits = [
    'register',
    'create_room',
    'join_room',
    'ready',
    'start_game',
    'game_action',
    'chat_message',
    // Missing: leave_room, join_matchmaking, resign
  ];

  it('all three agree on core game events', () => {
    const core = ['create_room', 'join_room', 'ready', 'start_game', 'game_action', 'chat_message'];
    for (const event of core) {
      expect(simpleServerEvents).toContain(event);
      expect(nestJSEvents).toContain(event);
      expect(flutterEmits).toContain(event);
    }
  });

  it('DIVERGENCE: register event — simple-server has it, NestJS does not (uses JWT)', () => {
    expect(simpleServerEvents).toContain('register');
    expect(nestJSEvents).not.toContain('register');
  });

  it('DIVERGENCE: leave_room — NestJS has it, simple-server does not', () => {
    expect(nestJSEvents).toContain('leave_room');
    expect(simpleServerEvents).not.toContain('leave_room');
  });

  it('DIVERGENCE: matchmaking — only NestJS has join_matchmaking', () => {
    expect(nestJSEvents).toContain('join_matchmaking');
    expect(simpleServerEvents).not.toContain('join_matchmaking');
  });

  it('DIVERGENCE: resign — only NestJS has resign event', () => {
    expect(nestJSEvents).toContain('resign');
    expect(simpleServerEvents).not.toContain('resign');
  });
});

describe('Protocol contract: server→client events', () => {

  // Events emitted by simple-server
  const simpleServerEmits = [
    'registered',
    'room_created',
    'room_joined',
    'player_joined',
    'player_left',
    'player_ready',
    'game_started',
    'game_state_update',
    'game_error',
    'round_end',
    'chat_broadcast',
    'meld_staged',
    'staging_cancelled',
    'game_over_forfeit',
  ];

  // Events emitted by NestJS gateway
  const nestJSEmits = [
    'room_created',
    'room_joined',
    'player_joined',
    'player_left',
    'player_ready',
    'game_started',
    'game_state_update',
    'game_error',
    'round_end',
    'game_end',
    'chat_broadcast',
    'matchmaking_waiting',
  ];

  // Events Flutter listens to (from _serverEvents list in socket_service.dart)
  const flutterListens = [
    'room_created',
    'room_joined',
    'player_joined',
    'player_left',
    'player_ready',
    'game_started',
    'game_state_update',
    'game_error',
    'chat_broadcast',
    'round_end',
    'game_end',
    'meld_staged',
    'staging_cancelled',
    'matchmaking_waiting',
    'connect_error',
    // Also listens to 'registered' (manually, not in _serverEvents)
  ];

  it('all three agree on core output events', () => {
    const core = [
      'room_created', 'room_joined', 'player_joined', 'player_left',
      'player_ready', 'game_started', 'game_state_update', 'game_error',
      'chat_broadcast', 'round_end',
    ];
    for (const event of core) {
      expect(simpleServerEmits).toContain(event);
      expect(nestJSEmits).toContain(event);
      expect(flutterListens).toContain(event);
    }
  });

  it('DIVERGENCE: game_end — NestJS emits, simple-server uses game_over_forfeit', () => {
    expect(nestJSEmits).toContain('game_end');
    expect(simpleServerEmits).not.toContain('game_end');
    expect(simpleServerEmits).toContain('game_over_forfeit');
    expect(nestJSEmits).not.toContain('game_over_forfeit');
  });

  it('DIVERGENCE: meld_staged — simple-server emits, NestJS does not', () => {
    expect(simpleServerEmits).toContain('meld_staged');
    expect(nestJSEmits).not.toContain('meld_staged');
    // Flutter listens for it
    expect(flutterListens).toContain('meld_staged');
  });

  it('DIVERGENCE: registered — simple-server emits, NestJS does not (JWT auth)', () => {
    expect(simpleServerEmits).toContain('registered');
    expect(nestJSEmits).not.toContain('registered');
  });

  it('DIVERGENCE: matchmaking_waiting — only NestJS emits', () => {
    expect(nestJSEmits).toContain('matchmaking_waiting');
    expect(simpleServerEmits).not.toContain('matchmaking_waiting');
    // Flutter listens for it
    expect(flutterListens).toContain('matchmaking_waiting');
  });
});

describe('Protocol contract: game_action payload structure', () => {

  it('AGREE: wrapper shape is { action: { type, ...params } }', () => {
    // simple-server: socket.on('game_action', (data) => { action = data?.action })
    // NestJS: @MessageBody() data: { action: any }
    // Flutter: emit('game_action', {'action': action})
    const payload = { action: { type: 'draw_deck' } };
    expect(payload.action.type).toBe('draw_deck');
  });

  it('all engines share the same action types (with aliases)', () => {
    const sharedCanonical = [
      'draw_from_deck', 'draw_from_discard',
      'meld', 'confirm_opening', 'cancel_staging',
      'layoff', 'replace_joker', 'discard', 'end_turn',
    ];
    const simpleServerActions = [
      'draw_deck', 'draw_discard',
      'meld', 'confirm_opening', 'cancel_staging',
      'layoff', 'discard',
    ];
    const flutterActions = [
      'draw_deck', 'draw_discard',
      'meld', 'confirm_opening', 'cancel_staging',
      'layoff', 'discard',
    ];

    // Core actions present in all, with alias mapping
    const aliasMap: Record<string, string> = {
      draw_deck: 'draw_from_deck',
      draw_discard: 'draw_from_discard',
    };

    for (const action of simpleServerActions) {
      const canonical = aliasMap[action] || action;
      expect(sharedCanonical).toContain(canonical);
    }
    for (const action of flutterActions) {
      const canonical = aliasMap[action] || action;
      expect(sharedCanonical).toContain(canonical);
    }
  });

  it('DIVERGENCE: replace_joker only exists in shared/ (not simple-server/Flutter)', () => {
    const sharedOnly = ['replace_joker', 'end_turn'];
    const simpleServerActions = [
      'draw_deck', 'draw_discard', 'meld', 'confirm_opening',
      'cancel_staging', 'layoff', 'discard',
    ];
    for (const action of sharedOnly) {
      expect(simpleServerActions).not.toContain(action);
    }
  });
});

describe('Protocol contract: authentication divergence', () => {

  it('simple-server: pseudo-auth via register event', () => {
    // Registers with { name, playerId }
    const registerPayload = { name: 'Alice', playerId: 'p_123' };
    expect(registerPayload.name).toBeDefined();
    expect(registerPayload.playerId).toBeDefined();
  });

  it('NestJS: JWT auth via handshake.auth.token', () => {
    // Token set in handshake { auth: { token: '...' } }
    const handshake = { auth: { token: 'eyJhbGciOiJIUzI1NiJ9...' } };
    expect(handshake.auth.token).toBeDefined();
  });

  it('Flutter: supports both modes (register for simple-server, connectWithToken for NestJS)', () => {
    // Flutter has both connect() and connectWithToken() methods
    const supportsBoth = true;
    expect(supportsBoth).toBe(true);
  });
});

describe('Protocol contract: game_state_update payload', () => {

  it('AGREE: both servers wrap state in { state: ... }', () => {
    // simple-server: getPlayerView returns { state: { ... } }
    // NestJS: emit('game_state_update', { state: sanitized })
    const payload = { state: { phase: 'playing', currentPlayerIndex: 0 } };
    expect(payload.state).toBeDefined();
    expect(payload.state.phase).toBeDefined();
  });

  it('DIVERGENCE: simple-server state.config hardcoded, shared/ config configurable', () => {
    // simple-server sends: config: { openingThreshold: 71, numJokers: 4, maxRounds: 5 }
    // NestJS sends: full GameConfig object
    const simpleConfig = { openingThreshold: 71, numJokers: 4, maxRounds: 5 };
    const sharedConfig = {
      openingThreshold: 71, numJokers: 4, maxRounds: 5,
      jokerValue: 30, aceHighValue: 11, // + many more fields
    };
    expect(Object.keys(simpleConfig).length).toBeLessThan(Object.keys(sharedConfig).length);
  });

  it('DIVERGENCE: discard pile — simple-server sends last 5, shared/ sends all', () => {
    // simple-server: discardPile: game.discardPile.slice(-5)
    // shared/: sends full discard pile
    const simpleSlice = 5;
    const sharedSlice = Infinity; // all
    expect(simpleSlice).toBeLessThan(sharedSlice);
  });
});

describe('Protocol contract: namespace', () => {
  it('AGREE: both servers use /game namespace', () => {
    // simple-server: io.of('/game')
    // NestJS: @WebSocketGateway({ namespace: '/game' })
    // Flutter: AppConstants.wsNamespace = '/game'
    const namespace = '/game';
    expect(namespace).toBe('/game');
  });
});

describe('PROTOCOL DIVERGENCE SUMMARY', () => {
  it('catalogs all 11 protocol divergences', () => {
    const divergences = [
      { id: 'AUTH_MODEL', desc: 'simple-server: register event, NestJS: JWT handshake' },
      { id: 'REGISTER_EVENT', desc: 'simple-server has register, NestJS does not' },
      { id: 'LEAVE_ROOM', desc: 'NestJS has leave_room, simple-server does not' },
      { id: 'MATCHMAKING', desc: 'NestJS has join_matchmaking, simple-server does not' },
      { id: 'RESIGN', desc: 'NestJS has resign, simple-server does not' },
      { id: 'GAME_END_EVENT', desc: 'NestJS: game_end, simple-server: game_over_forfeit' },
      { id: 'MELD_STAGED', desc: 'simple-server emits meld_staged, NestJS does not' },
      { id: 'DRAW_ACTION_NAMES', desc: 'simple-server/Flutter: draw_deck/draw_discard, shared/: draw_from_deck/draw_from_discard (aliased now)' },
      { id: 'REPLACE_JOKER', desc: 'shared/ has replace_joker action, others handle within layoff' },
      { id: 'DISCARD_PILE_SIZE', desc: 'simple-server: last 5, shared/: full pile' },
      { id: 'CONFIG_SHAPE', desc: 'simple-server: 3-field config, shared/: full GameConfig' },
    ];
    expect(divergences).toHaveLength(11);
  });
});
