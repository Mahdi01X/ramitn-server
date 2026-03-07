import 'package:flutter/material.dart';
import '../../../models/card.dart' as models;
import '../../../core/theme.dart';

class CardWidget extends StatelessWidget {
  final models.Card card;
  final bool isSelected;
  final bool isFaceDown;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.isFaceDown = false,
    this.onTap,
    this.onDoubleTap,
    this.width = 52,
    this.height = 76,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isFaceDown ? CafeTunisienColors.cardBack : Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected ? CafeTunisienColors.goldLight : Colors.grey.shade400,
            width: isSelected ? 2.5 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? CafeTunisienColors.gold.withOpacity(0.5)
                  : Colors.black.withOpacity(0.35),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(1, 3),
            ),
          ],
        ),
        child: isFaceDown ? _buildCardBack() : _buildCardFace(),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      margin: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB22222), Color(0xFF8B0000), Color(0xFF6B0000)],
          ),
        ),
        child: Center(
          child: Text('✦', style: TextStyle(fontSize: width * 0.3, color: CafeTunisienColors.goldLight)),
        ),
      ),
    );
  }

  Widget _buildCardFace() {
    if (card.isJoker) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🃏', style: TextStyle(fontSize: width * 0.38)),
              Text(
                'JOKER',
                style: TextStyle(
                  fontSize: width * 0.13,
                  fontWeight: FontWeight.w900,
                  color: Colors.purple.shade700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = card.isRed ? const Color(0xFFCC0000) : const Color(0xFF1A1A1A);
    final rankStr = _rankString(card.rank!);
    final suitStr = _suitString(card.suit!);

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top-left rank + suit
          Text(
            rankStr,
            style: TextStyle(
              fontSize: width * 0.24,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
          Text(
            suitStr,
            style: TextStyle(fontSize: width * 0.2, color: color, height: 0.9),
          ),
          const Spacer(),
          Center(
            child: Text(
              suitStr,
              style: TextStyle(fontSize: width * 0.38, color: color),
            ),
          ),
          const Spacer(),
          // Bottom-right (rotated)
          Align(
            alignment: Alignment.bottomRight,
            child: Transform.rotate(
              angle: 3.14159,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rankStr,
                    style: TextStyle(fontSize: width * 0.17, fontWeight: FontWeight.w800, color: color, height: 1.0),
                  ),
                  Text(suitStr, style: TextStyle(fontSize: width * 0.14, color: color, height: 0.9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rankString(models.Rank rank) {
    switch (rank) {
      case models.Rank.ace: return 'A';
      case models.Rank.jack: return 'V';
      case models.Rank.queen: return 'D';
      case models.Rank.king: return 'R';
      default: return '${rank.value}';
    }
  }

  String _suitString(models.Suit suit) {
    switch (suit) {
      case models.Suit.hearts: return '♥';
      case models.Suit.diamonds: return '♦';
      case models.Suit.clubs: return '♣';
      case models.Suit.spades: return '♠';
    }
  }
}

/// Dos de carte stylé
class CardBackWidget extends StatelessWidget {
  final double width;
  final double height;
  final VoidCallback? onTap;

  const CardBackWidget({
    super.key,
    this.width = 52,
    this.height = 76,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CardWidget(
        card: models.Card(id: -1, isJoker: false),
        isFaceDown: true,
        width: width,
        height: height,
      ),
    );
  }
}
