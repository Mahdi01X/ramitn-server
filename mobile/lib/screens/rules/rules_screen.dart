import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
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
            overlayOpacity: 0.82,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(color: CafeTunisienColors.glassBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: CafeTunisienColors.goldLight, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('📖', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: 8),
                          Text('Règles du Rami', style: AppTextStyles.titleLarge.copyWith(
                            color: CafeTunisienColors.goldLight,
                            shadows: [Shadow(color: CafeTunisienColors.gold.withOpacity(0.3), blurRadius: 8)],
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const GoldDivider(width: 100),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (context, _) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRule(0, emoji: '🎴', title: 'Matériel',
                            content: '• 2 jeux de 52 cartes + 4 jokers (108 cartes)\n• 2 à 4 joueurs'),
                          _buildRule(1, emoji: '🎯', title: 'But du jeu',
                            content: 'Se débarrasser de toutes ses cartes en posant des combinaisons valides sur la table.'),
                          _buildRule(2, emoji: '🃏', title: 'Distribution',
                            content: 'Le premier joueur reçoit 15 cartes, les autres 14. Le premier joueur commence par défausser une carte.'),
                          _buildRule(3, emoji: '📋', title: 'Combinaisons', children: [
                            _SubRule(title: 'Suite (Run)', text: '3 cartes ou plus consécutives de la même couleur.\nExemple : 5♥ 6♥ 7♥'),
                            _SubRule(title: 'Tierce (Set)', text: '3 ou 4 cartes de même rang, couleurs différentes.\nExemple : 7♥ 7♠ 7♦'),
                          ]),
                          _buildRule(4, emoji: '🔄', title: 'Tour de jeu',
                            content: '1. Piocher : prendre de la pioche ou du talon\n2. Poser : combinaisons ou compléter existantes\n3. Défausser : poser une carte sur le talon'),
                          _buildRule(5, emoji: '🔓', title: 'Ouverture',
                            content: 'Pour poser la première fois :\n\n• Somme ≥ 71 points (configurable)\n• Au moins une suite SANS joker\n\nExemple : 10♥ J♥ Q♥ K♥ (40 pts) + A♥ A♠ A♦ (33 pts) = 73 pts ✓'),
                          _buildRule(6, emoji: '🃏', title: 'Jokers',
                            content: '• Remplace n\'importe quelle carte\n• Récupérable en posant la carte exacte qu\'il remplace (seulement quand le paquet est complet)\n• Vaut 30 pts en main à la fin'),
                          _buildRule(7, emoji: '📊', title: 'Valeurs des cartes',
                            content: '• As : 11 points\n• 2-10 : valeur faciale\n• J, Q, K : 10 points\n• Joker : 30 points (en main)'),
                          _buildRule(8, emoji: '⚠️', title: 'Pioche de la défausse',
                            content: 'Si tu prends la carte jetée par l\'adversaire et que tu ne réussis pas l\'ouverture, tu perds la manche avec 100 points de pénalité !'),
                          _buildRule(9, emoji: '🏁', title: 'Fin de manche',
                            content: 'Quand un joueur n\'a plus de cartes, les autres comptent les points en main. Le joueur avec le score le plus bas après N manches gagne !'),
                          const SizedBox(height: 20),
                          Center(child: SuitOrnament(size: 16, opacity: 0.25)),
                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildRule(int index, {required String emoji, required String title, String? content, List<Widget>? children}) {
    final delay = index * 0.06;
    final progress = CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    ).value;

    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 15 * (1 - progress)),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CafeTunisienColors.gold.withOpacity(0.08),
                        border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.15)),
                      ),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title, style: AppTextStyles.titleMedium.copyWith(
                        color: CafeTunisienColors.goldLight,
                        fontSize: 16,
                        shadows: [Shadow(color: CafeTunisienColors.gold.withOpacity(0.15), blurRadius: 4)],
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (content != null)
                  Text(content, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                if (children != null) ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubRule extends StatelessWidget {
  final String title;
  final String text;
  const _SubRule({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.labelGold.copyWith(fontSize: 14)),
            const SizedBox(height: 4),
            Text(text, style: AppTextStyles.bodyMedium.copyWith(height: 1.4)),
          ],
        ),
      ),
    );
  }
}
