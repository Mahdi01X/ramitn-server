import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Premium background with café tunisien image + dark overlay + vignette.
/// Used on every screen EXCEPT the game table.
class CafeBackground extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;
  final bool showVignette;

  const CafeBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.75,
    this.showVignette = true,
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

        // Vignette effect
        if (showVignette)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
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

/// Frosted glass card container — premium glassmorphism
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 12,
    this.borderColor,
    this.backgroundColor,
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
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Gold divider line
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
            CafeTunisienColors.gold.withOpacity(0.8),
            CafeTunisienColors.goldLight,
            CafeTunisienColors.gold.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
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
        SizedBox(width: size * 0.8),
        Text('♥', style: TextStyle(color: CafeTunisienColors.warmRed.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.8),
        Text('♦', style: TextStyle(color: CafeTunisienColors.warmRed.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.8),
        Text('♣', style: TextStyle(color: CafeTunisienColors.gold.withOpacity(opacity), fontSize: size)),
      ],
    );
  }
}

/// Premium animated button with gold gradient + glow
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

class _PremiumButtonState extends State<PremiumButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: enabled ? (_) => _ctrl.forward() : null,
        onTapUp: enabled ? (_) { _ctrl.reverse(); widget.onTap?.call(); } : null,
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: widget.width ?? double.infinity,
          height: 56,
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
                          : CafeTunisienColors.gold.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
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
                        Icon(widget.icon, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: AppTextStyles.buttonText.copyWith(
                          color: enabled ? Colors.white : Colors.white38,
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

