import 'package:flutter/material.dart';
import '../../../models/card.dart' as models;

/// Premium playing card widget — used everywhere
class PlayingCard extends StatelessWidget {
  final models.Card card;
  final double width;
  final double height;
  final bool selected;
  final bool validHighlight; // green glow = part of valid meld
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
    final borderColor = validHighlight
        ? const Color(0xFF4CAF50)
        : selected
            ? const Color(0xFFFFD700)
            : Colors.grey.shade300;
    final borderWidth = (selected || validHighlight) ? 2.5 : 0.7;

    final glowColor = validHighlight
        ? const Color(0xFF4CAF50).withOpacity(0.5)
        : selected
            ? const Color(0xFFFFD700).withOpacity(0.4)
            : Colors.black.withOpacity(0.25);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.4 : 1.0,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: faceDown ? const Color(0xFF8B0000) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(color: glowColor, blurRadius: selected || validHighlight ? 10 : 4, offset: const Offset(1, 2)),
            ],
          ),
          child: faceDown ? _buildBack() : _buildFace(),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB22222), Color(0xFF8B0000)],
        ),
      ),
      child: const Center(
        child: Text('✦', style: TextStyle(fontSize: 16, color: Color(0xFFFFD700))),
      ),
    );
  }

  Widget _buildFace() {
    if (card.isJoker) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🃏', style: TextStyle(fontSize: width * 0.35)),
            Text('JOKER', style: TextStyle(
              fontSize: width * 0.12,
              fontWeight: FontWeight.w900,
              color: Colors.purple.shade700,
            )),
          ],
        ),
      );
    }

    final color = card.isRed ? const Color(0xFFCC0000) : const Color(0xFF1A1A1A);
    final r = _rank(card.rank!);
    final s = _suit(card.suit!);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r, style: TextStyle(fontSize: width * 0.24, fontWeight: FontWeight.w800, color: color, height: 1.0)),
          Text(s, style: TextStyle(fontSize: width * 0.18, color: color, height: 0.85)),
          const Spacer(),
          Center(child: Text(s, style: TextStyle(fontSize: width * 0.38, color: color))),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r, style: TextStyle(fontSize: width * 0.16, fontWeight: FontWeight.w800, color: color, height: 1.0)),
                  Text(s, style: TextStyle(fontSize: width * 0.13, color: color, height: 0.85)),
                ],
              ),
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

