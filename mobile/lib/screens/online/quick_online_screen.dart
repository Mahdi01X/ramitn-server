import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';
import '../../core/theme.dart';
/// Quick online play — no account needed.
/// Enter a pseudo → connect to server → create or join a room with a code.
class QuickOnlineScreen extends ConsumerStatefulWidget {
  const QuickOnlineScreen({super.key});

  @override
  ConsumerState<QuickOnlineScreen> createState() => _QuickOnlineScreenState();
}

enum _Step { pseudo, choice, creating, joining, waitingRoom }

class _QuickOnlineScreenState extends ConsumerState<QuickOnlineScreen> {
  final _pseudoCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  _Step _step = _Step.pseudo;
  int _numPlayers = 2;
  bool _connecting = false;
  String? _connectionError;

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String get _pseudo => _pseudoCtrl.text.trim();

  /// Connect to the server, then execute the callback once connected.
  void _connectAndDo(VoidCallback onConnected) {
    setState(() { _connecting = true; _connectionError = null; });

    final notifier = ref.read(gameProvider.notifier);
    notifier.connectOnline(displayName: _pseudo);

    // Wait for registered event or timeout
    final socket = ref.read(socketServiceProvider);
    late final sub;
    sub = socket.on('registered').listen((_) {
      sub.cancel();
      if (mounted) {
        setState(() => _connecting = false);
        onConnected();
      }
    });

    // Also listen for connection error
    // Don't fail on first connect_error — Render free tier has cold starts
    int _errorCount = 0;
    final errSub = socket.on('connect_error').listen((err) {
      _errorCount++;
      // Only fail after multiple errors (give cold start time)
      if (_errorCount >= 3 && mounted) {
        setState(() {
          _connecting = false;
          _connectionError = 'Impossible de se connecter au serveur.\nVérifie ta connexion internet.';
        });
      }
    });

    // Timeout after 20 seconds (Render free tier cold start = ~30s)
    Future.delayed(const Duration(seconds: 20), () {
      if (_connecting && mounted) {
        sub.cancel();
        errSub.cancel();
        setState(() {
          _connecting = false;
          _connectionError = 'Connexion au serveur trop lente.\nLe serveur démarre peut-être (réessaie dans 30s).';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);

    // Listen for room_created → switch to waiting room with real server code
    ref.listen(roomProvider, (prev, next) {
      if (next.roomCode != null && (prev?.roomCode == null) && next.isInRoom) {
        if (_step == _Step.creating || _step == _Step.joining || _step == _Step.pseudo || _step == _Step.choice) {
          setState(() => _step = _Step.waitingRoom);
        }
      }
      // Navigate to lobby when game started
      if (next.gameStarted && !(prev?.gameStarted ?? false)) {
        context.go('/game');
      }
      // Show error from server (e.g. invalid code)
      if (next.error != null && prev?.error != next.error) {
        setState(() {
          _connecting = false;
          _connectionError = next.error;
        });
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3E2723), Color(0xFF1A4D2E), Color(0xFF143D24)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                _Header(
                  onBack: () {
                    if (_step == _Step.pseudo) {
                      context.go('/');
                    } else if (_step == _Step.waitingRoom) {
                      ref.read(gameProvider.notifier).disconnectOnline();
                      ref.read(roomProvider.notifier).reset();
                      setState(() => _step = _Step.choice);
                    } else if (_step == _Step.creating || _step == _Step.joining) {
                      setState(() => _step = _Step.choice);
                    } else {
                      setState(() => _step = _Step.pseudo);
                    }
                  },
                ),

                // Connection error banner
                if (_connectionError != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Text(
                      _connectionError!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Room error banner
                if (room.error != null && _step == _Step.waitingRoom) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.4)),
                    ),
                    child: Text(
                      room.error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Loading overlay
                if (_connecting) ...[
                  const SizedBox(height: 80),
                  const CircularProgressIndicator(color: CafeTunisienColors.gold),
                  const SizedBox(height: 16),
                  Text(
                    'Connexion au serveur...',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                ],

                // ─── STEP 1: Pseudo ──────────────────────────
                if (!_connecting && _step == _Step.pseudo) ...[
                  const Text('🎭', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 16),
                  const Text(
                    'Choisis ton pseudo',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _InputBox(controller: _pseudoCtrl, hintText: 'Ex: Lina', maxLength: 15, fontSize: 20),
                  const SizedBox(height: 20),
                  _BigButton(
                    label: 'Continuer',
                    onTap: () {
                      if (_pseudo.length >= 2) setState(() => _step = _Step.choice);
                    },
                  ),
                ],

                // ─── STEP 2: Choice ──────────────────────────
                if (!_connecting && _step == _Step.choice) ...[
                  _PseudoBadge(pseudo: _pseudo),
                  const SizedBox(height: 32),
                  _OptionCard(
                    icon: Icons.add_circle_outline,
                    title: 'Créer une partie',
                    subtitle: 'Génère un code pour inviter tes amis',
                    onTap: () => setState(() => _step = _Step.creating),
                  ),
                  const SizedBox(height: 14),
                  _OptionCard(
                    icon: Icons.login,
                    title: 'Rejoindre une partie',
                    subtitle: 'Entre le code d\'un ami',
                    onTap: () => setState(() => _step = _Step.joining),
                  ),
                ],

                // ─── STEP 3a: Create ─────────────────────────
                if (!_connecting && _step == _Step.creating) ...[
                  const Text('🏠', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 12),
                  const Text('Créer une partie',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Nombre de joueurs', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [2, 3, 4].map((n) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ChoiceChip(
                        label: Text('$n'),
                        selected: _numPlayers == n,
                        onSelected: (_) => setState(() => _numPlayers = n),
                        selectedColor: CafeTunisienColors.gold,
                        labelStyle: TextStyle(
                          color: _numPlayers == n ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  _BigButton(
                    label: 'Créer & obtenir le code',
                    icon: Icons.rocket_launch,
                    onTap: () {
                      // Connect to server, then create room
                      _connectAndDo(() {
                        ref.read(gameProvider.notifier).createRoom(numPlayers: _numPlayers);
                        // room_created event will be caught by roomProvider → we listen above
                      });
                    },
                  ),
                ],

                // ─── STEP 3b: Join ───────────────────────────
                if (!_connecting && _step == _Step.joining) ...[
                  const Text('🔑', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 12),
                  const Text('Rejoindre une partie',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Code de la partie', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  _InputBox(
                    controller: _codeCtrl, hintText: 'ABC12', maxLength: 6,
                    fontSize: 30, letterSpacing: 8, capitalize: true,
                  ),
                  const SizedBox(height: 24),
                  _BigButton(
                    label: 'Rejoindre',
                    icon: Icons.login,
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      if (_codeCtrl.text.trim().length >= 4) {
                        _connectAndDo(() {
                          ref.read(gameProvider.notifier).joinRoom(_codeCtrl.text.trim().toUpperCase());
                          // Don't switch to waitingRoom yet — wait for room_joined event
                          // The ref.listen(roomProvider) above will handle the transition
                        });
                      }
                    },
                  ),
                  // Error from server (invalid code, etc.)
                  if (room.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(room.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  ],
                ],

                // ─── STEP 4: Waiting Room ─────────────────────
                if (!_connecting && _step == _Step.waitingRoom) ...[
                  const Text('📡', style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 12),
                  Text(
                    room.roomCode != null ? 'Ta partie est prête !' : 'Connexion en cours...',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Partage ce code avec tes amis :',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // THE CODE — big, tappable, copy to clipboard
                  GestureDetector(
                    onTap: () {
                      final code = room.roomCode;
                      if (code != null) {
                        Clipboard.setData(ClipboardData(text: code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Code copié dans le presse-papiers !'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD700), width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            room.roomCode ?? '...',
                            style: const TextStyle(
                              color: Color(0xFFFFD700), fontSize: 40, fontWeight: FontWeight.w900,
                              letterSpacing: 10, fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(Icons.copy, color: Color(0xFFFFD700), size: 24),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Appuyez pour copier', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                  const SizedBox(height: 20),

                  // Players in room
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Joueurs (${room.players.length}/${room.numPlayers})',
                          style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        ...room.players.asMap().entries.map((entry) {
                          final i = entry.key;
                          final p = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.ready
                                        ? const Color(0xFF4CAF50).withOpacity(0.3)
                                        : CafeTunisienColors.gold.withOpacity(0.3),
                                  ),
                                  child: Icon(
                                    p.ready ? Icons.check : Icons.person,
                                    color: p.ready ? const Color(0xFF4CAF50) : CafeTunisienColors.goldLight,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (i == 0 ? const Color(0xFFE8A317) : p.ready ? const Color(0xFF4CAF50) : Colors.white10).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    i == 0 ? 'Hôte' : (p.ready ? 'Prêt ✓' : 'En attente'),
                                    style: TextStyle(
                                      color: i == 0 ? const Color(0xFFE8A317) : (p.ready ? const Color(0xFF4CAF50) : Colors.white38),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Empty slots
                        for (int i = room.players.length; i < room.numPlayers; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 32, height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Icon(Icons.hourglass_empty, color: Colors.white.withOpacity(0.2), size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text('En attente...', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Ready + Start buttons
                  // Determine if I am the host (first player in list) and my ready state
                  Builder(builder: (context) {
                    final socket = ref.read(socketServiceProvider);
                    final myId = socket.playerId;
                    final isHost = room.players.isNotEmpty && room.players.first.id == myId;
                    final myPlayer = room.players.where((p) => p.id == myId).firstOrNull;
                    final iAmReady = myPlayer?.ready ?? false;
                    final allReady = room.players.every((p) => p.ready);
                    final canStart = isHost && room.players.length >= 2 && allReady;

                    return Column(
                      children: [
                        // Ready button — changes appearance based on ready state
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => ref.read(gameProvider.notifier).setReady(),
                            icon: Icon(iAmReady ? Icons.check_circle : Icons.thumb_up, size: 20),
                            label: Text(iAmReady ? 'Prêt ✓' : 'Je suis prêt !', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iAmReady ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: iAmReady ? const BorderSide(color: Color(0xFF66BB6A), width: 2) : BorderSide.none,
                            ),
                          ),
                        ),
                        // Start button — only visible to host
                        if (isHost) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: canStart
                                  ? () => ref.read(gameProvider.notifier).startOnlineGame()
                                  : null,
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: Text(
                                canStart ? '🎮 Lancer la partie !' : 'En attente que tous soient prêts...',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CafeTunisienColors.gold,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.white.withOpacity(0.05),
                                disabledForegroundColor: Colors.white38,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                        if (!isHost) ...[
                          const SizedBox(height: 12),
                          Text(
                            'L\'hôte lancera la partie quand tout le monde sera prêt',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  // Waiting indicator
                  if (room.players.length < room.numPlayers)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: CafeTunisienColors.gold.withOpacity(0.5))),
                        const SizedBox(width: 10),
                        Text('En attente des autres joueurs...', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back, color: CafeTunisienColors.gold), onPressed: onBack),
            const Expanded(
              child: Text('Jouer en ligne',
                style: TextStyle(color: CafeTunisienColors.goldLight, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 4),
        Text('Pas besoin de compte — juste un pseudo !',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PseudoBadge extends StatelessWidget {
  final String pseudo;
  const _PseudoBadge({required this.pseudo});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: CafeTunisienColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text('👋 $pseudo', style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final double fontSize;
  final double letterSpacing;
  final bool capitalize;
  const _InputBox({required this.controller, required this.hintText, this.maxLength = 15, this.fontSize = 20, this.letterSpacing = 0, this.capitalize = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller, textAlign: TextAlign.center,
        textCapitalization: capitalize ? TextCapitalization.characters : TextCapitalization.none,
        maxLength: maxLength,
        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w600, letterSpacing: letterSpacing),
        decoration: InputDecoration(
          border: InputBorder.none, counterText: '', hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), letterSpacing: letterSpacing),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;
  const _BigButton({required this.label, this.icon, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? CafeTunisienColors.gold, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OptionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: CafeTunisienColors.woodBrown.withOpacity(0.4), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 36, color: CafeTunisienColors.goldLight),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right, color: CafeTunisienColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}












