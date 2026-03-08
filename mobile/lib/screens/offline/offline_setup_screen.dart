import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/game_config.dart';
import '../../providers/game_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class OfflineSetupScreen extends ConsumerStatefulWidget {
  const OfflineSetupScreen({super.key});

  @override
  ConsumerState<OfflineSetupScreen> createState() => _OfflineSetupScreenState();
}

class _OfflineSetupScreenState extends ConsumerState<OfflineSetupScreen> {
  int _numHumans = 2;
  int _numBots = 0;
  int _openingThreshold = 71;
  int _maxRounds = 5;
  int _numJokers = 4;
  bool _openingRequiresCleanRun = true;
  final _playerNames = List.generate(4, (i) => 'Joueur ${i + 1}');
  final _nameControllers = List.generate(4, (i) => TextEditingController(text: ''));

  int get _totalPlayers => _numHumans + _numBots;

  @override
  void dispose() {
    for (final c in _nameControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0906),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CafeBackground(
            overlayOpacity: 0.78,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
            children: [
              // ─── Header ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/'),
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('☕ Nouvelle Partie', style: AppTextStyles.titleLarge.copyWith(color: CafeTunisienColors.goldLight)),
                    ),
                  ],
                ),
              ),
              const GoldDivider(width: 120),
              const SizedBox(height: 8),

              // ─── Body ────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Players Section
                      _SectionHeader(icon: '👥', title: 'Joueurs'),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(
                          children: [
                            _StepperRow(icon: Icons.person, label: 'Humains', value: _numHumans, min: 1, max: 4,
                              onChanged: (v) => setState(() {
                                _numHumans = v;
                                if (_totalPlayers > 4) _numBots = 4 - _numHumans;
                                if (_totalPlayers < 2 && _numBots == 0) _numBots = 1;
                              }),
                            ),
                            Divider(color: Colors.white.withOpacity(0.06), height: 1),
                            _StepperRow(icon: Icons.smart_toy, label: 'Bots', value: _numBots, min: 0, max: 4 - _numHumans,
                              onChanged: (v) => setState(() => _numBots = v),
                            ),
                          ],
                        ),
                      ),
                      if (_totalPlayers < 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: CafeTunisienColors.warmRed, size: 15),
                              const SizedBox(width: 6),
                              Text('Il faut au moins 2 joueurs', style: AppTextStyles.bodySmall.copyWith(color: CafeTunisienColors.warmRed)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Names Section
                      _SectionHeader(icon: '✏️', title: 'Pseudos'),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: List.generate(_numHumans, (i) => Padding(
                            padding: EdgeInsets.only(bottom: i < _numHumans - 1 ? 10 : 0),
                            child: Row(
                              children: [
                                Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [CafeTunisienColors.gold.withOpacity(0.3), CafeTunisienColors.gold.withOpacity(0.1)],
                                    ),
                                  ),
                                  child: Center(child: Text('${i + 1}', style: AppTextStyles.labelGold.copyWith(fontSize: 12))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _nameControllers[i],
                                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      hintText: 'Ton pseudo',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.15)),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.05),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CafeTunisienColors.gold, width: 1.5)),
                                    ),
                                    onChanged: (v) => _playerNames[i] = v.isEmpty ? 'Joueur ${i + 1}' : v,
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Rules Section
                      _SectionHeader(icon: '⚙️', title: 'Paramètres'),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(
                          children: [
                            _StepperRow(icon: Icons.lock_open, label: 'Seuil d\'ouverture', value: _openingThreshold, min: 0, max: 151, step: 10, suffix: ' pts',
                              onChanged: (v) => setState(() => _openingThreshold = v)),
                            Divider(color: Colors.white.withOpacity(0.06), height: 1),
                            _StepperRow(icon: Icons.repeat, label: 'Manches', value: _maxRounds, min: 1, max: 20,
                              onChanged: (v) => setState(() => _maxRounds = v)),
                            Divider(color: Colors.white.withOpacity(0.06), height: 1),
                            _StepperRow(icon: Icons.style, label: 'Jokers', value: _numJokers, min: 0, max: 8,
                              onChanged: (v) => setState(() => _numJokers = v)),
                            Divider(color: Colors.white.withOpacity(0.06), height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_outlined, color: CafeTunisienColors.gold, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('Suite sans joker', style: AppTextStyles.bodyMedium)),
                                  Switch.adaptive(
                                    value: _openingRequiresCleanRun,
                                    onChanged: (v) => setState(() => _openingRequiresCleanRun = v),
                                    activeColor: CafeTunisienColors.gold,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Summary
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        borderColor: CafeTunisienColors.gold.withOpacity(0.2),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.summarize_outlined, color: CafeTunisienColors.goldLight, size: 16),
                                const SizedBox(width: 6),
                                Text('Résumé', style: AppTextStyles.labelGold),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_numHumans humain${_numHumans > 1 ? 's' : ''} + $_numBots bot${_numBots > 1 ? 's' : ''}\n$_maxRounds manches • Ouverture $_openingThreshold pts • $_numJokers jokers',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.5)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ─── Start Button ────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: PremiumButton(
                  label: '🎲 Lancer la partie',
                  icon: Icons.play_arrow_rounded,
                  onTap: _totalPlayers >= 2 ? _startGame : null,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  void _startGame() {
    final players = <({String id, String name, bool isBot})>[];
    for (int i = 0; i < _numHumans; i++) {
      final name = _nameControllers[i].text.isEmpty ? 'Joueur ${i + 1}' : _nameControllers[i].text;
      players.add((id: 'human_$i', name: name, isBot: false));
    }
    for (int i = 0; i < _numBots; i++) {
      players.add((id: 'bot_$i', name: 'Bot ${i + 1}', isBot: true));
    }
    final config = GameConfig(
      numPlayers: _totalPlayers,
      openingThreshold: _openingThreshold,
      maxRounds: _maxRounds,
      numJokers: _numJokers,
      openingRequiresCleanRun: _openingRequiresCleanRun,
    );
    ref.read(gameProvider.notifier).startOfflineGame(players: players, config: config);
    context.go('/game');
  }
}

// ─── Section Header ──────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleMedium.copyWith(color: CafeTunisienColors.goldLight, fontSize: 17)),
      ],
    );
  }
}

// ─── Stepper Row ─────────────────────────────────────────────
class _StepperRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int min, max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.icon, required this.label, required this.value,
    required this.min, required this.max, this.step = 1, this.suffix = '',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: CafeTunisienColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          // Minus
          _StepButton(
            icon: Icons.remove,
            enabled: value > min,
            color: CafeTunisienColors.warmRed,
            onTap: () => onChanged((value - step).clamp(min, max)),
          ),
          Container(
            width: 52,
            alignment: Alignment.center,
            child: Text('$value$suffix', style: AppTextStyles.labelGold.copyWith(fontSize: 15)),
          ),
          // Plus
          _StepButton(
            icon: Icons.add,
            enabled: value < max,
            color: const Color(0xFF4CAF50),
            onTap: () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.enabled, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? color.withOpacity(0.15) : Colors.white.withOpacity(0.03),
          border: Border.all(color: enabled ? color.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
        ),
        child: Icon(icon, size: 16, color: enabled ? color : Colors.white12),
      ),
    );
  }
}
