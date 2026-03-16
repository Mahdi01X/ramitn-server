import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Premium background with café tunisien image + dark overlay + vignette + floating particles.
class CafeBackground extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;
  final bool showVignette;
  final bool showParticles;

  const CafeBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.75,
    this.showVignette = true,
    this.showParticles = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.asset(
          'assets/1772912871079.webp',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3E2723), Color(0xFF1A4D2E), Color(0xFF0D3B13)],
              ),
            ),
          ),
        ),

        // Dark overlay for readability
        Container(
          color: Colors.black.withOpacity(overlayOpacity),
        ),

        // Warm tint overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CafeTunisienColors.espresso.withOpacity(0.4),
                Colors.transparent,
                CafeTunisienColors.tableGreen.withOpacity(0.2),
              ],
            ),
          ),
        ),

        // Subtle golden spotlight from top
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.6),
              radius: 1.5,
              colors: [
                CafeTunisienColors.gold.withOpacity(0.04),
                Colors.transparent,
              ],
            ),
          ),
        ),

        // Floating dust particles
        if (showParticles) const _FloatingParticles(),

        // Vignette effect
        if (showVignette)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),

        // Child content
        child,
      ],
    );
  }
}

/// Animated floating dust/gold particles
class _FloatingParticles extends StatefulWidget {
  const _FloatingParticles();

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _particles = <_Particle>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 1.0 + _rng.nextDouble() * 2.5,
        speed: 0.2 + _rng.nextDouble() * 0.5,
        opacity: 0.1 + _rng.nextDouble() * 0.25,
        phase: _rng.nextDouble() * 2 * pi,
      ));
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _ctrl.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double x, y, size, speed, opacity, phase;
  const _Particle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.opacity, required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final x = (p.x + sin(t * 2 * pi * p.speed + p.phase) * 0.03) * size.width;
      final y = (p.y - t * p.speed * 0.3 + 1.0) % 1.0 * size.height;
      final shimmer = (sin(t * 2 * pi * 3 + p.phase) * 0.5 + 0.5);
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFD700),
          Colors.white,
          shimmer * 0.5,
        )!.withOpacity(p.opacity * (0.5 + shimmer * 0.5));
      canvas.drawCircle(Offset(x, y), p.size * (0.8 + shimmer * 0.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

/// Frosted glass card container — premium glassmorphism with optional inner glow
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool innerGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 12,
    this.borderColor,
    this.backgroundColor,
    this.innerGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xCC1A1210),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? CafeTunisienColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          if (innerGlow)
            BoxShadow(
              color: CafeTunisienColors.gold.withOpacity(0.06),
              blurRadius: 40,
              spreadRadius: -4,
            ),
        ],
      ),
      child: child,
    );
  }
}

/// Gold divider line with enhanced shimmer
class GoldDivider extends StatelessWidget {
  final double width;
  const GoldDivider({super.key, this.width = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            CafeTunisienColors.brass.withOpacity(0.5),
            CafeTunisienColors.gold.withOpacity(0.9),
            CafeTunisienColors.goldLight,
            CafeTunisienColors.gold.withOpacity(0.9),
            CafeTunisienColors.brass.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: CafeTunisienColors.gold.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Ornamental suit symbols row
class SuitOrnament extends StatelessWidget {
  final double size;
  final double opacity;
  const SuitOrnament({super.key, this.size = 14, this.opacity = 0.3});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('♠', style: TextStyle(color: CafeTunisienColors.gold.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.6),
        Text('♥', style: TextStyle(color: CafeTunisienColors.warmRed.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.6),
        Text('♦', style: TextStyle(color: CafeTunisienColors.warmRed.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.6),
        Text('♣', style: TextStyle(color: CafeTunisienColors.gold.withOpacity(opacity), fontSize: size)),
      ],
    );
  }
}

/// Premium animated button with gold gradient + glow + shimmer sweep
class PremiumButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSecondary;
  final bool isLoading;
  final double? width;

  const PremiumButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isSecondary = false,
    this.isLoading = false,
    this.width,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> with TickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat();
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnim, _shimmerCtrl]),
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: enabled ? (_) => _pressCtrl.forward() : null,
        onTapUp: enabled ? (_) { _pressCtrl.reverse(); widget.onTap?.call(); } : null,
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (context, _) {
            return Container(
              width: widget.width ?? double.infinity,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: widget.isSecondary
                    ? LinearGradient(colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.04),
                      ])
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFE8A317),
                          Color(0xFFD4A017),
                          Color(0xFFB8860B),
                          Color(0xFFD4A017),
                        ],
                      ),
                border: Border.all(
                  color: widget.isSecondary
                      ? CafeTunisienColors.glassBorder
                      : CafeTunisienColors.goldLight.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: widget.isSecondary
                              ? Colors.transparent
                              : CafeTunisienColors.gold.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                        if (!widget.isSecondary)
                          BoxShadow(
                            color: CafeTunisienColors.gold.withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Shimmer sweep (only for primary buttons)
                    if (!widget.isSecondary && enabled)
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            final val = _shimmerCtrl.value;
                            return LinearGradient(
                              begin: Alignment(val * 3 - 1.5, 0),
                              end: Alignment(val * 3 - 0.5, 0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.15),
                                Colors.transparent,
                              ],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Container(color: Colors.white),
                        ),
                      ),
                    // Content
                    Center(
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.icon != null) ...[
                                  Icon(widget.icon, color: enabled ? Colors.white : Colors.white38, size: 22),
                                  const SizedBox(width: 10),
                                ],
                                Text(
                                  widget.label,
                                  style: AppTextStyles.buttonText.copyWith(
                                    color: enabled ? Colors.white : Colors.white38,
                                    shadows: enabled && !widget.isSecondary
                                        ? [const Shadow(color: Colors.black38, blurRadius: 4)]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Ornamental corner flourish for premium frames
class CornerFlourish extends StatelessWidget {
  final double size;
  final bool flipH;
  final bool flipV;

  const CornerFlourish({
    super.key,
    this.size = 24,
    this.flipH = false,
    this.flipV = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
      child: CustomPaint(
        size: Size(size, size),
        painter: _FlourishPainter(),
      ),
    );
  }
}

class _FlourishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CafeTunisienColors.gold.withOpacity(0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h * 0.8)
      ..quadraticBezierTo(w * 0.1, h * 0.1, w * 0.8, 0)
      ..moveTo(0, h * 0.6)
      ..quadraticBezierTo(w * 0.2, h * 0.2, w * 0.6, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
