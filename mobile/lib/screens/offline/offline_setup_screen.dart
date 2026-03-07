import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/game_config.dart';
import '../../providers/game_provider.dart';
import '../../core/theme.dart';

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
  final _nameControllers = List.generate(4, (i) => TextEditingController(text: 'Joueur ${i + 1}'));

  int get _totalPlayers => _numHumans + _numBots;

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CafeTunisienColors.tableGreen,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: CafeTunisienColors.woodBrown.withOpacity(0.95),
                border: const Border(bottom: BorderSide(color: CafeTunisienColors.gold, width: 1.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: CafeTunisienColors.goldLight),
                    onPressed: () => context.go('/'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '☕ Nouvelle Partie',
                    style: TextStyle(
                      color: CafeTunisienColors.goldLight,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Players Section
                    _SectionTitle(title: '👥 Joueurs', subtitle: 'Choisissez le nombre de joueurs'),
                    const SizedBox(height: 10),
                    _ChoiceCard(
                      children: [
                        _OptionRow(
                          icon: Icons.person,
                          label: 'Humains',
                          value: _numHumans,
                          min: 1,
                          max: 4,
                          onChanged: (v) => setState(() {
                            _numHumans = v;
                            if (_totalPlayers > 4) _numBots = 4 - _numHumans;
                            if (_totalPlayers < 2 && _numBots == 0) _numBots = 1;
                          }),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _OptionRow(
                          icon: Icons.smart_toy,
                          label: 'Bots',
                          value: _numBots,
                          min: 0,
                          max: 4 - _numHumans,
                          onChanged: (v) => setState(() => _numBots = v),
                        ),
                      ],
                    ),
                    if (_totalPlayers < 2)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: CafeTunisienColors.warmRed, size: 16),
                            SizedBox(width: 4),
                            Text('Il faut au moins 2 joueurs', style: TextStyle(color: CafeTunisienColors.warmRed, fontSize: 12)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Player names
                    _SectionTitle(title: '✏️ Noms', subtitle: 'Personnalisez les noms des joueurs'),
                    const SizedBox(height: 10),
                    _ChoiceCard(
                      children: List.generate(_numHumans, (i) => Padding(
                        padding: EdgeInsets.only(bottom: i < _numHumans - 1 ? 0 : 0),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: CafeTunisienColors.gold.withOpacity(0.2),
                                      border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.4)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _nameControllers[i],
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        hintText: 'Joueur ${i + 1}',
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: CafeTunisienColors.gold),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.05),
                                      ),
                                      onChanged: (v) => _playerNames[i] = v.isEmpty ? 'Joueur ${i + 1}' : v,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < _numHumans - 1)
                              const Divider(color: Colors.white10, height: 1),
                          ],
                        ),
                      )),
                    ),
                    const SizedBox(height: 16),

                    // Game Rules
                    _SectionTitle(title: '⚙️ Règles', subtitle: 'Paramètres de la partie'),
                    const SizedBox(height: 10),
                    _ChoiceCard(
                      children: [
                        _OptionRow(
                          icon: Icons.lock_open,
                          label: 'Seuil d\'ouverture',
                          value: _openingThreshold,
                          min: 0,
                          max: 151,
                          step: 10,
                          suffix: ' pts',
                          onChanged: (v) => setState(() => _openingThreshold = v),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _OptionRow(
                          icon: Icons.repeat,
                          label: 'Manches',
                          value: _maxRounds,
                          min: 1,
                          max: 20,
                          onChanged: (v) => setState(() => _maxRounds = v),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _OptionRow(
                          icon: Icons.style,
                          label: 'Jokers',
                          value: _numJokers,
                          min: 0,
                          max: 8,
                          onChanged: (v) => setState(() => _numJokers = v),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: CafeTunisienColors.gold, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Suite sans joker obligatoire',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ),
                              Switch(
                                value: _openingRequiresCleanRun,
                                onChanged: (v) => setState(() => _openingRequiresCleanRun = v),
                                activeColor: CafeTunisienColors.gold,
                                inactiveThumbColor: Colors.white38,
                                inactiveTrackColor: Colors.white10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Summary
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CafeTunisienColors.gold.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.25)),
                      ),
                      child: Column(
                        children: [
                          const Text('📋 Résumé', style: TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(
                            '$_numHumans humain${_numHumans > 1 ? 's' : ''} + $_numBots bot${_numBots > 1 ? 's' : ''} • $_maxRounds manches • Ouverture $_openingThreshold pts • $_numJokers jokers',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Start button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: CafeTunisienColors.woodBrown.withOpacity(0.95),
                border: const Border(top: BorderSide(color: CafeTunisienColors.gold, width: 1)),
              ),
              child: ElevatedButton.icon(
                onPressed: _totalPlayers >= 2 ? _startGame : null,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text('🎲 Lancer la partie', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CafeTunisienColors.gold,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
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

// ─── Section Title ───────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
      ],
    );
  }
}

// ─── Choice Card Container ───────────────────────────────────

class _ChoiceCard extends StatelessWidget {
  final List<Widget> children;
  const _ChoiceCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ─── Option Row (increment/decrement) ────────────────────────

class _OptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _OptionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    this.suffix = '',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: CafeTunisienColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          // Minus button
          GestureDetector(
            onTap: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value > min ? CafeTunisienColors.warmRed.withOpacity(0.2) : Colors.white.withOpacity(0.03),
                border: Border.all(
                  color: value > min ? CafeTunisienColors.warmRed.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Icon(
                Icons.remove,
                size: 16,
                color: value > min ? CafeTunisienColors.warmRed : Colors.white12,
              ),
            ),
          ),
          Container(
            width: 52,
            alignment: Alignment.center,
            child: Text(
              '$value$suffix',
              style: const TextStyle(
                color: CafeTunisienColors.goldLight,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          // Plus button
          GestureDetector(
            onTap: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value < max ? const Color(0xFF4CAF50).withOpacity(0.2) : Colors.white.withOpacity(0.03),
                border: Border.all(
                  color: value < max ? const Color(0xFF4CAF50).withOpacity(0.5) : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Icon(
                Icons.add,
                size: 16,
                color: value < max ? const Color(0xFF4CAF50) : Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
