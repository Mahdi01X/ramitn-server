import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _breatheCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _breathe;

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _breathe = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
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
            overlayOpacity: 0.65,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (context, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // ─── Logo + Title ────────────────────────
                        _buildLogo(),
                        const SizedBox(height: 36),

                        // ─── Ornament ────────────────────────────
                        _buildOrnamentRow(),
                        const SizedBox(height: 28),

                        // ─── Menu Buttons ────────────────────────
                        _buildMenuCard(
                          index: 0,
                          icon: Icons.casino_rounded,
                          emoji: '🎲',
                          label: 'Jouer Hors-ligne',
                          subtitle: 'Hot-seat ou contre des bots',
                          gradientColors: const [Color(0xFF0B3D0B), Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          onTap: () => context.push('/offline-setup'),
                        ),
                        const SizedBox(height: 14),
                        _buildMenuCard(
                          index: 1,
                          icon: Icons.public_rounded,
                          emoji: '🌐',
                          label: 'Jouer En ligne',
                          subtitle: 'Parties privées entre amis',
                          gradientColors: const [Color(0xFF0A2D5E), Color(0xFF0D47A1), Color(0xFF1565C0)],
                          onTap: () => context.push('/quick-online'),
                        ),
                        const SizedBox(height: 14),
                        _buildMenuCard(
                          index: 2,
                          icon: Icons.auto_stories_rounded,
                          emoji: '📖',
                          label: 'Règles du jeu',
                          subtitle: 'Apprendre à jouer au Rami Tunisien',
                          gradientColors: const [Color(0xFF2C1810), Color(0xFF4E342E), Color(0xFF6D4C41)],
                          onTap: () => context.push('/rules'),
                        ),

                        const SizedBox(height: 36),

                        // ─── Bottom ornament ─────────────────────
                        _buildFooter(),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    final entryProgress = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ).value;

    return Opacity(
      opacity: entryProgress.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.5 + entryProgress * 0.5,
        child: Column(
          children: [
            // Logo image with animated gold ring + glow
            AnimatedBuilder(
              animation: _breathe,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CafeTunisienColors.gold.withOpacity(0.6),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CafeTunisienColors.gold.withOpacity(_breathe.value * 0.3),
                        blurRadius: 35 * _breathe.value,
                        spreadRadius: 8 * _breathe.value,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 25,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
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
                    child: const Center(child: Text('🃏', style: TextStyle(fontSize: 60))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // App title with gold gradient shimmer
            Shimmer.fromColors(
              baseColor: CafeTunisienColors.goldLight,
              highlightColor: CafeTunisienColors.champagne,
              period: const Duration(milliseconds: 3000),
              child: Text(
                'RamiTN',
                style: AppTextStyles.displayLarge.copyWith(
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.7), offset: const Offset(2, 3), blurRadius: 12),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Arabic tagline
            Text('— قهوة و كارطة —', style: AppTextStyles.arabicTagline),
          ],
        ),
      ),
    );
  }

  Widget _buildOrnamentRow() {
    final entryProgress = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
    ).value;

    return Opacity(
      opacity: entryProgress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOrnamentLine(),
          const SizedBox(width: 12),
          const SuitOrnament(size: 16, opacity: 0.45),
          const SizedBox(width: 12),
          _buildOrnamentLine(),
        ],
      ),
    );
  }

  Widget _buildOrnamentLine() {
    return Container(
      width: 40,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            CafeTunisienColors.gold.withOpacity(0.4),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required int index,
    required IconData icon,
    required String emoji,
    required String label,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final delay = 0.3 + index * 0.12;
    final entryProgress = CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(delay, (delay + 0.35).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    ).value;

    return Opacity(
      opacity: entryProgress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 30 * (1 - entryProgress)),
        child: _PremiumMenuCard(
          key: ValueKey('btn_menu_$index'),
          icon: icon,
          emoji: emoji,
          label: label,
          subtitle: subtitle,
          gradientColors: gradientColors,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final entryProgress = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ).value;

    return Opacity(
      opacity: entryProgress * 0.6,
      child: Column(
        children: [
          const GoldDivider(width: 80),
          const SizedBox(height: 12),
          Text(
            'Le jeu de cartes du café tunisien',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.3),
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Menu Card ───────────────────────────────────────
class _PremiumMenuCard extends StatefulWidget {
  final IconData icon;
  final String emoji;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _PremiumMenuCard({
    super.key,
    required this.icon,
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
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
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.gradientColors[0].withOpacity(0.7),
                widget.gradientColors[1].withOpacity(0.5),
                widget.gradientColors[2].withOpacity(0.35),
              ],
            ),
            border: Border.all(
              color: CafeTunisienColors.gold.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[1].withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Background icon watermark
                Positioned(
                  right: -15,
                  top: -15,
                  child: Icon(
                    widget.icon,
                    size: 110,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
                // Inner highlight at top
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      // Emoji icon in circle with glow
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradientColors[1].withOpacity(0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(widget.emoji, style: const TextStyle(fontSize: 26)),
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
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: CafeTunisienColors.gold.withOpacity(0.12),
                          border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.2)),
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
