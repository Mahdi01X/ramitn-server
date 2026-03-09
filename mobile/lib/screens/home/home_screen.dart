import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0906),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CafeBackground(
            overlayOpacity: 0.65,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // ─── Logo + Title ────────────────────────
                    _LogoSection(),
                    const SizedBox(height: 40),

                    // ─── Ornament ────────────────────────────
                    const SuitOrnament(size: 18, opacity: 0.4),
                    const SizedBox(height: 32),

                    // ─── Menu Buttons ────────────────────────
                    _PremiumMenuCard(
                      key: const ValueKey('btn_offline'),
                      icon: Icons.casino_rounded,
                      emoji: '🎲',
                      label: 'Jouer Hors-ligne',
                      subtitle: 'Hot-seat ou contre des bots',
                      gradient: const [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                      onTap: () => context.push('/offline-setup'),
                    ),
                    const SizedBox(height: 14),
                    _PremiumMenuCard(
                      key: const ValueKey('btn_online'),
                      icon: Icons.public_rounded,
                      emoji: '🌐',
                      label: 'Jouer En ligne',
                      subtitle: 'Parties privées entre amis',
                      gradient: const [Color(0xFF0D47A1), Color(0xFF1565C0)],
                      onTap: () => context.push('/quick-online'),
                    ),
                    const SizedBox(height: 14),
                    _PremiumMenuCard(
                      key: const ValueKey('btn_rules'),
                      icon: Icons.auto_stories_rounded,
                      emoji: '📖',
                      label: 'Règles du jeu',
                      subtitle: 'Apprendre à jouer au Rami Tunisien',
                      gradient: const [Color(0xFF4E342E), Color(0xFF6D4C41)],
                      onTap: () => context.push('/rules'),
                    ),

                    const SizedBox(height: 40),

                    // ─── Bottom ornament ─────────────────────
                    const GoldDivider(width: 80),
                    const SizedBox(height: 12),
                    Text(
                      'Le jeu de cartes du café tunisien',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.35),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo Section ────────────────────────────────────────────
class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo image with gold ring
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.6), width: 3),
            boxShadow: [
              BoxShadow(
                color: CafeTunisienColors.gold.withOpacity(0.25),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'unnamed.jpg',
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 140,
                height: 140,
                color: CafeTunisienColors.feltGreen,
                child: const Center(
                  child: Text('🃏', style: TextStyle(fontSize: 60)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // App title
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFFFF8E1),
                Color(0xFFD4A017),
                Color(0xFFFFF8E1),
                Color(0xFFFFD700),
              ],
              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            ).createShader(bounds);
          },
          child: Text(
            'RamiTN',
            style: AppTextStyles.displayLarge.copyWith(
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.6), offset: const Offset(2, 3), blurRadius: 10),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Arabic tagline
        Text('— قهوة و كارطة —', style: AppTextStyles.arabicTagline),
      ],
    );
  }
}

// ─── Premium Menu Card ───────────────────────────────────────
class _PremiumMenuCard extends StatefulWidget {
  final IconData icon;
  final String emoji;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _PremiumMenuCard({
    super.key,
    required this.icon,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_PremiumMenuCard> createState() => _PremiumMenuCardState();
}

class _PremiumMenuCardState extends State<_PremiumMenuCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.gradient[0].withOpacity(0.6),
                widget.gradient[1].withOpacity(0.4),
              ],
            ),
            border: Border.all(
              color: CafeTunisienColors.gold.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradient[0].withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Subtle pattern overlay
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    widget.icon,
                    size: 100,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      // Emoji icon in circle
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
                        ),
                        child: Center(
                          child: Text(widget.emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CafeTunisienColors.gold.withOpacity(0.15),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: CafeTunisienColors.goldLight,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
