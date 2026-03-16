import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/card.dart' as models;

/// Premium playing card widget with realistic depth, shine, textures, and smooth animations.
/// Studio-quality card visuals matching top card game apps.
class PlayingCard extends StatelessWidget {
  final models.Card card;
  final double width;
  final double height;
  final bool selected;
  final bool validHighlight;
  final bool faceDown;
  final bool dimmed;
  final VoidCallback? onTap;

  const PlayingCard({
    super.key,
    required this.card,
    this.width = 52,
    this.height = 76,
    this.selected = false,
    this.validHighlight = false,
    this.faceDown = false,
    this.dimmed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = validHighlight
        ? const Color(0xFF4CAF50).withOpacity(0.7)
        : selected
            ? const Color(0xFFFFD700).withOpacity(0.6)
            : Colors.transparent;

    final borderColor = validHighlight
        ? const Color(0xFF4CAF50)
        : selected
            ? const Color(0xFFFFD700)
            : faceDown
                ? const Color(0xFFD4A017).withOpacity(0.25)
                : const Color(0xFFBBBBBB).withOpacity(0.4);
    final borderW = (selected || validHighlight) ? 2.0 : 0.8;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.12),
          border: Border.all(color: borderColor, width: borderW),
          boxShadow: [
            // Base shadow — 3D depth
            BoxShadow(
              color: Colors.black.withOpacity(faceDown ? 0.6 : 0.4),
              blurRadius: selected ? 14 : 7,
              offset: Offset(selected ? 0 : 1.5, selected ? 5 : 3),
              spreadRadius: selected ? 1 : 0,
            ),
            // Edge shadow for thickness illusion
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 1,
              offset: const Offset(0.5, 1.5),
            ),
            // Glow when selected / valid
            if (glowColor != Colors.transparent)
              BoxShadow(
                color: glowColor,
                blurRadius: 18,
                spreadRadius: 3,
              ),
          ],
        ),
        child: Opacity(
          opacity: dimmed ? 0.35 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width * 0.12),
            child: Stack(
              children: [
                // Card base (face or back)
                faceDown ? _buildBack() : _buildFace(),

                // Top-left corner shine (simulates glossy finish)
                Positioned(
                  top: -height * 0.15,
                  left: -width * 0.15,
                  child: Container(
                    width: width * 0.7,
                    height: height * 0.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(faceDown ? 0.05 : 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom edge highlight (thickness effect)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          (faceDown ? Colors.white : Colors.grey).withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B0000), Color(0xFF6B0000)],
        ),
      ),
      child: Stack(
        children: [
          // Inner frame
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.all(width * 0.06),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.08),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFCC1111), Color(0xFF8B0000), Color(0xFFAA0000), Color(0xFF6B0000)],
                  stops: [0.0, 0.4, 0.7, 1.0],
                ),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.35),
                  width: 0.8,
                ),
              ),
            ),
          ),
          // Diamond lattice pattern
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.all(width * 0.06),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(width * 0.08),
                child: CustomPaint(painter: _CardBackPatternPainter(width)),
              ),
            ),
          ),
          // Center ornament with enhanced glow
          Center(
            child: Container(
              width: width * 0.5,
              height: width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.45),
                  width: 1.0,
                ),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.2),
                    const Color(0xFFFFD700).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: width * 0.22,
                    color: const Color(0xFFFFD700).withOpacity(0.8),
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFace() {
    if (card.isJoker) return _buildJokerFace();
    if (card.suit == null || card.rank == null) return const SizedBox.shrink();

    final color = card.isRed ? const Color(0xFFCC0000) : const Color(0xFF1A1A2E);
    final r = _rank(card.rank!);
    final s = _suit(card.suit!);
    final rankSize = width * 0.25;
    final suitSize = width * 0.18;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEFB), Color(0xFFF8F5F0), Color(0xFFFFFEFB)],
        ),
      ),
      child: Stack(
        children: [
          // Subtle paper texture overlay
          Positioned.fill(
            child: CustomPaint(painter: _CardTexturePainter()),
          ),

          // Top-left rank + suit
          Positioned(
            top: width * 0.06,
            left: width * 0.08,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(r, style: TextStyle(
                  fontSize: rankSize,
                  fontWeight: FontWeight.w900,
                  color: color,
                  height: 1.0,
                  shadows: [Shadow(color: color.withOpacity(0.15), blurRadius: 1, offset: const Offset(0.5, 0.5))],
                )),
                Text(s, style: TextStyle(fontSize: suitSize, color: color, height: 0.8)),
              ],
            ),
          ),

          // Center suit (large) with decorative shadow
          Center(
            child: Text(s, style: TextStyle(
              fontSize: width * 0.44,
              color: color,
              shadows: [
                Shadow(color: color.withOpacity(0.08), blurRadius: 3, offset: const Offset(1, 1)),
              ],
            )),
          ),

          // Bottom-right rank + suit (inverted)
          Positioned(
            bottom: width * 0.06,
            right: width * 0.08,
            child: Transform.rotate(
              angle: pi,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(r, style: TextStyle(
                    fontSize: width * 0.17,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  )),
                  Text(s, style: TextStyle(fontSize: width * 0.13, color: color, height: 0.8)),
                ],
              ),
            ),
          ),

          // Thin inner frame line
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.06),
                border: Border.all(
                  color: color.withOpacity(0.06),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJokerFace() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEFB), Color(0xFFF5F0EA)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CardTexturePainter()),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🃏', style: TextStyle(fontSize: width * 0.4)),
                const SizedBox(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.06, vertical: 1),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    ),
                    borderRadius: BorderRadius.circular(width * 0.04),
                  ),
                  child: Text('JOKER', style: TextStyle(
                    fontSize: width * 0.11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _rank(models.Rank rank) => switch (rank) {
    models.Rank.ace => 'A',
    models.Rank.jack => 'J',
    models.Rank.queen => 'Q',
    models.Rank.king => 'K',
    _ => '${rank.value}',
  };

  static String _suit(models.Suit suit) => switch (suit) {
    models.Suit.hearts => '♥',
    models.Suit.diamonds => '♦',
    models.Suit.clubs => '♣',
    models.Suit.spades => '♠',
  };
}

/// Diamond lattice pattern for card backs
class _CardBackPatternPainter extends CustomPainter {
  final double cardWidth;
  _CardBackPatternPainter(this.cardWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final step = size.width * 0.22;
    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - step * 0.5)
          ..lineTo(x + step * 0.5, y)
          ..lineTo(x, y + step * 0.5)
          ..lineTo(x - step * 0.5, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }

    // Subtle inner border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.12)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle paper/linen texture for card face
class _CardTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(42); // Fixed seed for consistent texture
    final paint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.01)
      ..strokeWidth = 0.3;

    for (int i = 0; i < 80; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.3 + rng.nextDouble() * 0.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
