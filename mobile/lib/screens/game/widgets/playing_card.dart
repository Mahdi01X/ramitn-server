import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/card.dart' as models;

/// Premium playing card widget with 3D shadow, shine effect, and smooth animations.
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
                : Colors.grey.shade400;
    final borderW = (selected || validHighlight) ? 2.0 : 0.8;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: faceDown ? const Color(0xFF7B0A0A) : const Color(0xFFFFFEF9),
          borderRadius: BorderRadius.circular(width * 0.12),
          border: Border.all(color: borderColor, width: borderW),
          boxShadow: [
            // Main shadow — 3D depth
            BoxShadow(
              color: Colors.black.withOpacity(faceDown ? 0.5 : 0.35),
              blurRadius: selected ? 12 : 6,
              offset: Offset(selected ? 0 : 1, selected ? 4 : 3),
              spreadRadius: selected ? 1 : 0,
            ),
            // Glow when selected / valid
            if (glowColor != Colors.transparent)
              BoxShadow(
                color: glowColor,
                blurRadius: 16,
                spreadRadius: 2,
              ),
            // Subtle inner light for face-up cards
            if (!faceDown)
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 1,
                offset: const Offset(-0.5, -0.5),
              ),
          ],
        ),
        child: Opacity(
          opacity: dimmed ? 0.35 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width * 0.12),
            child: Stack(
              children: [
                // Card content
                faceDown ? _buildBack() : _buildFace(),
                // Shine overlay — top-left corner gloss
                Positioned(
                  top: -height * 0.2,
                  left: -width * 0.2,
                  child: Container(
                    width: width * 0.8,
                    height: height * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(faceDown ? 0.06 : 0.12),
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
      child: Stack(
        children: [
          // Diamond pattern
          Positioned.fill(
            child: CustomPaint(painter: _CardBackPatternPainter(width)),
          ),
          // Center ornament
          Center(
            child: Container(
              width: width * 0.45,
              height: width * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  width: 0.8,
                ),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  '✦',
                  style: TextStyle(
                    fontSize: width * 0.2,
                    color: const Color(0xFFFFD700).withOpacity(0.7),
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
    if (card.isJoker) {
      return _buildJokerFace();
    }
    if (card.suit == null || card.rank == null) return const SizedBox.shrink();

    final color = card.isRed ? const Color(0xFFCC0000) : const Color(0xFF1A1A2E);
    final r = _rank(card.rank!);
    final s = _suit(card.suit!);
    final fontSize = width * 0.24;

    return Padding(
      padding: EdgeInsets.all(width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top-left rank + suit
          Text(r, style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.0,
            shadows: [Shadow(color: color.withOpacity(0.15), blurRadius: 1, offset: const Offset(0.5, 0.5))],
          )),
          Text(s, style: TextStyle(fontSize: width * 0.18, color: color, height: 0.85)),
          const Spacer(),
          // Center suit (large)
          Center(
            child: Text(s, style: TextStyle(
              fontSize: width * 0.42,
              color: color,
              shadows: [Shadow(color: color.withOpacity(0.1), blurRadius: 2, offset: const Offset(1, 1))],
            )),
          ),
          const Spacer(),
          // Bottom-right rank + suit (inverted)
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: pi,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r, style: TextStyle(
                    fontSize: width * 0.16,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1.0,
                  )),
                  Text(s, style: TextStyle(fontSize: width * 0.13, color: color, height: 0.85)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJokerFace() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🃏', style: TextStyle(fontSize: width * 0.38)),
          Text('JOKER', style: TextStyle(
            fontSize: width * 0.12,
            fontWeight: FontWeight.w900,
            color: Colors.purple.shade700,
            letterSpacing: 1,
          )),
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

/// Paints a subtle diamond lattice pattern on the card back.
class _CardBackPatternPainter extends CustomPainter {
  final double cardWidth;
  _CardBackPatternPainter(this.cardWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final step = size.width * 0.25;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - step * 0.5)
          ..lineTo(x + step * 0.5, y)
          ..lineTo(x, y + step * 0.5)
          ..lineTo(x - step * 0.5, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
