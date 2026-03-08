import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../providers/room_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Quick online play — no account needed.
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

  void _connectAndDo(VoidCallback onConnected) {
    setState(() { _connecting = true; _connectionError = null; });
    final notifier = ref.read(gameProvider.notifier);
    notifier.connectOnline(displayName: _pseudo);
    final socket = ref.read(socketServiceProvider);
    late final sub;
    sub = socket.on('registered').listen((_) {
      sub.cancel();
      if (mounted) { setState(() => _connecting = false); onConnected(); }
    });
    int _errorCount = 0;
    final errSub = socket.on('connect_error').listen((err) {
      _errorCount++;
      if (_errorCount >= 3 && mounted) {
        setState(() { _connecting = false; _connectionError = 'Impossible de se connecter.'; });
      }
    });
    Future.delayed(const Duration(seconds: 20), () {
      if (_connecting && mounted) {
        sub.cancel(); errSub.cancel();
        setState(() { _connecting = false; _connectionError = 'Connexion trop lente.\nLe serveur démarre peut-être.'; });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(roomProvider);

    ref.listen(roomProvider, (prev, next) {
      if (next.roomCode != null && (prev?.roomCode == null) && next.isInRoom) {
        if (_step != _Step.waitingRoom) setState(() => _step = _Step.waitingRoom);
      }
      if (next.gameStarted && !(prev?.gameStarted ?? false)) context.go('/game');
      if (next.error != null && prev?.error != next.error) {
        setState(() { _connecting = false; _connectionError = next.error; });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0906),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fixed background that covers EVERYTHING
          CafeBackground(
            overlayOpacity: 0.78,
            child: const SizedBox.expand(),
          ),
          // Scrollable content on top
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(),

                  // Error banners
                  if (_connectionError != null) _ErrorBanner(text: _connectionError!),
                  if (room.error != null && _step == _Step.waitingRoom) _ErrorBanner(text: room.error!),

                  // Loading
                  if (_connecting) ...[
                    const SizedBox(height: 80),
                    const CircularProgressIndicator(color: CafeTunisienColors.gold, strokeWidth: 2.5),
                    const SizedBox(height: 16),
                    Text('Connexion au serveur...', style: AppTextStyles.bodySmall),
                  ],

                  // Steps
                  if (!_connecting && _step == _Step.pseudo) _buildPseudoStep(),
                  if (!_connecting && _step == _Step.choice) _buildChoiceStep(),
                  if (!_connecting && _step == _Step.creating) _buildCreatingStep(),
                  if (!_connecting && _step == _Step.joining) _buildJoiningStep(room),
                  if (!_connecting && _step == _Step.waitingRoom) _buildWaitingRoom(room),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_step == _Step.pseudo) { context.go('/'); }
                else if (_step == _Step.waitingRoom) {
                  ref.read(gameProvider.notifier).disconnectOnline();
                  ref.read(roomProvider.notifier).reset();
                  setState(() => _step = _Step.choice);
                } else if (_step == _Step.creating || _step == _Step.joining) {
                  setState(() => _step = _Step.choice);
                } else { setState(() => _step = _Step.pseudo); }
              },
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(color: CafeTunisienColors.glassBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: CafeTunisienColors.goldLight, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Jouer en ligne', style: AppTextStyles.titleLarge.copyWith(color: CafeTunisienColors.goldLight)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Pas besoin de compte — juste un pseudo !', style: AppTextStyles.bodySmall.copyWith(color: Colors.white38)),
        const SizedBox(height: 12),
        const GoldDivider(width: 80),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPseudoStep() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CafeTunisienColors.gold.withOpacity(0.1),
            border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
          ),
          child: const Center(child: Text('🎭', style: TextStyle(fontSize: 36))),
        ),
        const SizedBox(height: 20),
        Text('Choisis ton pseudo', style: AppTextStyles.titleMedium),
        const SizedBox(height: 20),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: TextField(
            controller: _pseudoCtrl,
            textAlign: TextAlign.center,
            maxLength: 15,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.bodyLarge.copyWith(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1),
            decoration: InputDecoration(
              border: InputBorder.none,
              counterText: '',
              hintText: 'Ton pseudo',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        PremiumButton(
          label: 'Continuer',
          icon: Icons.arrow_forward_rounded,
          onTap: _pseudo.length >= 2 ? () => setState(() => _step = _Step.choice) : null,
        ),
      ],
    );
  }

  Widget _buildChoiceStep() {
    return Column(
      children: [
        const SizedBox(height: 8),
        _PseudoBadge(pseudo: _pseudo),
        const SizedBox(height: 32),
        _PremiumOptionCard(
          emoji: '🏠',
          title: 'Créer une partie',
          subtitle: 'Génère un code pour inviter tes amis',
          gradient: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          onTap: () => setState(() => _step = _Step.creating),
        ),
        const SizedBox(height: 14),
        _PremiumOptionCard(
          emoji: '🔑',
          title: 'Rejoindre une partie',
          subtitle: 'Entre le code d\'un ami',
          gradient: const [Color(0xFF0D47A1), Color(0xFF1565C0)],
          onTap: () => setState(() => _step = _Step.joining),
        ),
      ],
    );
  }

  Widget _buildCreatingStep() {
    return Column(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CafeTunisienColors.gold.withOpacity(0.1),
            border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
          ),
          child: const Center(child: Text('🏠', style: TextStyle(fontSize: 32))),
        ),
        const SizedBox(height: 16),
        Text('Créer une partie', style: AppTextStyles.titleMedium),
        const SizedBox(height: 24),
        Text('Nombre de joueurs', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [2, 3, 4].map((n) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => setState(() => _numPlayers = n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _numPlayers == n ? CafeTunisienColors.gold : Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: _numPlayers == n ? CafeTunisienColors.goldLight : CafeTunisienColors.glassBorder,
                    width: _numPlayers == n ? 2 : 1,
                  ),
                  boxShadow: _numPlayers == n ? [BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.3), blurRadius: 12)] : null,
                ),
                child: Center(
                  child: Text('$n', style: AppTextStyles.titleMedium.copyWith(
                    color: _numPlayers == n ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w700,
                  )),
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 28),
        PremiumButton(
          label: 'Créer & obtenir le code',
          icon: Icons.rocket_launch_rounded,
          onTap: () => _connectAndDo(() => ref.read(gameProvider.notifier).createRoom(numPlayers: _numPlayers)),
        ),
      ],
    );
  }

  Widget _buildJoiningStep(RoomState room) {
    return Column(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0D47A1).withOpacity(0.2),
            border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.4)),
          ),
          child: const Center(child: Text('🔑', style: TextStyle(fontSize: 32))),
        ),
        const SizedBox(height: 16),
        Text('Rejoindre une partie', style: AppTextStyles.titleMedium),
        const SizedBox(height: 24),
        Text('Code de la partie', style: AppTextStyles.bodyMedium),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: TextField(
            controller: _codeCtrl,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.displayMedium.copyWith(fontSize: 34, letterSpacing: 10, fontFamily: 'monospace', color: CafeTunisienColors.goldLight),
            decoration: InputDecoration(
              border: InputBorder.none, counterText: '',
              hintText: 'ABC12',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.12), letterSpacing: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
        PremiumButton(
          label: 'Rejoindre',
          icon: Icons.login_rounded,
          onTap: _codeCtrl.text.trim().length >= 4 ? () {
            final code = _codeCtrl.text.trim().toUpperCase();
            _connectAndDo(() {
              ref.read(gameProvider.notifier).joinRoom(code);
            });
          } : null,
        ),
        if (room.error != null) ...[
          const SizedBox(height: 16),
          _ErrorBanner(text: room.error!),
        ],
      ],
    );
  }

  Widget _buildWaitingRoom(RoomState room) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('📡', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(room.roomCode != null ? 'Ta partie est prête !' : 'Connexion...', style: AppTextStyles.titleMedium),
        const SizedBox(height: 6),
        Text('Partage ce code avec tes amis :', style: AppTextStyles.bodySmall),
        const SizedBox(height: 20),

        // Code display
        GestureDetector(
          onTap: () {
            if (room.roomCode != null) {
              Clipboard.setData(ClipboardData(text: room.roomCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Code copié !'), backgroundColor: Color(0xFF4CAF50)),
              );
            }
          },
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            borderColor: CafeTunisienColors.gold.withOpacity(0.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(room.roomCode ?? '...',
                  style: AppTextStyles.displayMedium.copyWith(
                    fontSize: 38, letterSpacing: 10, fontFamily: 'monospace', color: CafeTunisienColors.goldLight,
                  )),
                const SizedBox(width: 14),
                Icon(Icons.copy_rounded, color: CafeTunisienColors.gold.withOpacity(0.7), size: 22),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Appuyez pour copier', style: AppTextStyles.bodySmall.copyWith(color: Colors.white24)),
        const SizedBox(height: 20),

        // Players list
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Joueurs (${room.players.length}/${room.numPlayers})', style: AppTextStyles.labelGold),
              const SizedBox(height: 12),
              ...room.players.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.ready ? const Color(0xFF4CAF50).withOpacity(0.2) : CafeTunisienColors.gold.withOpacity(0.15),
                          border: Border.all(color: p.ready ? const Color(0xFF4CAF50).withOpacity(0.5) : CafeTunisienColors.gold.withOpacity(0.3)),
                        ),
                        child: Icon(p.ready ? Icons.check : Icons.person, color: p.ready ? const Color(0xFF4CAF50) : CafeTunisienColors.goldLight, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(p.name, style: AppTextStyles.bodyLarge.copyWith(fontSize: 15)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: (i == 0 ? CafeTunisienColors.amber : p.ready ? const Color(0xFF4CAF50) : Colors.white10).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          i == 0 ? 'Hôte' : (p.ready ? 'Prêt ✓' : 'En attente'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: i == 0 ? CafeTunisienColors.amber : (p.ready ? const Color(0xFF4CAF50) : Colors.white38),
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
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Icon(Icons.hourglass_empty, color: Colors.white.withOpacity(0.15), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text('En attente...', style: AppTextStyles.bodySmall.copyWith(color: Colors.white24, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Ready + Start buttons
        Builder(builder: (context) {
          final socket = ref.read(socketServiceProvider);
          final myId = socket.playerId;
          final isHost = room.players.isNotEmpty && room.players.first.id == myId;
          final myPlayerMatches = room.players.where((p) => p.id == myId);
          final myPlayer = myPlayerMatches.isNotEmpty ? myPlayerMatches.first : null;
          final iAmReady = myPlayer?.ready ?? false;
          final allReady = room.players.every((p) => p.ready);
          final canStart = isHost && room.players.length >= 2 && allReady;

          return Column(
            children: [
              // Non-host: show ready button
              if (!isHost)
                PremiumButton(
                  label: iAmReady ? 'Prêt ✓' : 'Je suis prêt !',
                  icon: iAmReady ? Icons.check_circle : Icons.thumb_up,
                  isSecondary: iAmReady,
                  onTap: iAmReady ? null : () => ref.read(gameProvider.notifier).setReady(),
                ),

              // Host: show start button
              if (isHost) ...[
                PremiumButton(
                  label: canStart ? '🎮 Lancer la partie !' : 'En attente des joueurs...',
                  icon: Icons.play_arrow_rounded,
                  onTap: canStart ? () => ref.read(gameProvider.notifier).startOnlineGame() : null,
                ),
              ],

              // Info text
              if (!isHost && iAmReady) ...[
                const SizedBox(height: 12),
                Text('En attente du lancement par l\'hôte...', style: AppTextStyles.bodySmall.copyWith(color: Colors.white30)),
              ],
              if (isHost && !canStart) ...[
                const SizedBox(height: 8),
                Text(
                  room.players.length < room.numPlayers
                      ? 'En attente de joueurs...'
                      : 'Tous les joueurs doivent être prêts',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white30),
                ),
              ],
            ],
          );
        }),

        const SizedBox(height: 16),
        if (room.players.length < room.numPlayers)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: CafeTunisienColors.gold.withOpacity(0.4))),
              const SizedBox(width: 10),
              Text('En attente des joueurs...', style: AppTextStyles.bodySmall.copyWith(color: Colors.white30)),
            ],
          ),
      ],
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String text;
  const _ErrorBanner({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CafeTunisienColors.warmRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CafeTunisienColors.warmRed.withOpacity(0.3)),
      ),
      child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: Colors.redAccent), textAlign: TextAlign.center),
    );
  }
}

class _PseudoBadge extends StatelessWidget {
  final String pseudo;
  const _PseudoBadge({required this.pseudo});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: CafeTunisienColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
      ),
      child: Text('👋 $pseudo', style: AppTextStyles.labelGold.copyWith(fontSize: 16)),
    );
  }
}

class _PremiumOptionCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _PremiumOptionCard({required this.emoji, required this.title, required this.subtitle, required this.gradient, required this.onTap});

  @override
  State<_PremiumOptionCard> createState() => _PremiumOptionCardState();
}

class _PremiumOptionCardState extends State<_PremiumOptionCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [widget.gradient[0].withOpacity(0.5), widget.gradient[1].withOpacity(0.3)],
            ),
            border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: widget.gradient[0].withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
                ),
                child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(widget.subtitle, style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.45))),
              ])),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle, color: CafeTunisienColors.gold.withOpacity(0.15)),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: CafeTunisienColors.goldLight, size: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


