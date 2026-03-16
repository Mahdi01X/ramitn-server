import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import 'playing_card.dart';
import '../../../models/card.dart' as models;

/// Info about a single opponent.
class OpponentInfo {
  final String name;
  final int handCount;
  final bool isActive;
  final int totalScore;
  final bool hasOpened;
  final int openingScore;

  const OpponentInfo({
    required this.name,
    required this.handCount,
    this.isActive = false,
    this.totalScore = 0,
    this.hasOpened = false,
    this.openingScore = 0,
  });
}

/// Premium opponent hand display with animated badges, glowing active indicators,
/// and realistic inverted card fan. Multiple opponents side by side.
class OpponentHandWidget extends StatelessWidget {
  final List<OpponentInfo> opponents;

  final int? _cardCount;
  final String? _playerName;
  final bool _isActive;
  final int _totalScore;
  final bool _hasOpened;
  final int _openingScore;

  const OpponentHandWidget.multi({
    super.key,
    required this.opponents,
  })  : _cardCount = null,
        _playerName = null,
        _isActive = false,
        _totalScore = 0,
        _hasOpened = false,
        _openingScore = 0;

  const OpponentHandWidget({
    super.key,
    required int cardCount,
    required String playerName,
    bool isActive = false,
    int totalScore = 0,
    bool hasOpened = false,
    int openingScore = 0,
  })  : opponents = const [],
        _cardCount = cardCount,
        _playerName = playerName,
        _isActive = isActive,
        _totalScore = totalScore,
        _hasOpened = hasOpened,
        _openingScore = openingScore;

  List<OpponentInfo> get _resolvedOpponents {
    if (opponents.isNotEmpty) return opponents;
    if (_playerName != null) {
      return [
        OpponentInfo(
          name: _playerName!,
          handCount: _cardCount ?? 0,
          isActive: _isActive,
          totalScore: _totalScore,
          hasOpened: _hasOpened,
          openingScore: _openingScore,
        ),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final opps = _resolvedOpponents;
    if (opps.isEmpty) return const SizedBox.shrink();

    if (opps.length == 1) {
      return _SingleOpponentSection(opponent: opps.first);
    }

    return Container(
      height: 88,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2C1508).withOpacity(0.9),
            const Color(0xFF1A3D1A).withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < opps.length; i++) ...[
            Expanded(child: _SingleOpponentSection(opponent: opps[i])),
            if (i < opps.length - 1)
              Container(
                width: 1,
                height: 55,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      CafeTunisienColors.gold.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SingleOpponentSection extends StatelessWidget {
  final OpponentInfo opponent;
  const _SingleOpponentSection({required this.opponent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Inverted fan of face-down cards
            if (opponent.handCount > 0)
              ..._buildInvertedFan(opponent.handCount, width),

            // Active turn glow bar
            if (opponent.isActive)
              Positioned(
                top: 0,
                left: width * 0.15,
                right: width * 0.15,
                height: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Colors.transparent, Color(0xFFFFD700), Color(0xFFFFF8E1), Color(0xFFFFD700), Colors.transparent],
                      stops: [0.0, 0.2, 0.5, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),

            // Name badge
            Positioned(
              bottom: 2,
              left: 0,
              right: 0,
              child: Center(
                child: _OpponentBadge(opponent: opponent),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildInvertedFan(int n, double width) {
    final maxCardW = 30.0;
    final minCardW = 18.0;
    final overlapRatio = n <= 5 ? 0.5 : (0.3 + (4 / n) * 0.2).clamp(0.22, 0.5);
    final neededW = n > 1 ? maxCardW + (n - 1) * maxCardW * overlapRatio : maxCardW;
    final available = width - 20;
    final cardW = neededW <= available ? maxCardW : (maxCardW * available / neededW).clamp(minCardW, maxCardW);
    final cardH = cardW * 1.4;

    final centerX = width / 2;
    final maxAngle = (n * 1.8).clamp(8.0, 32.0);
    final fanR = width * (n <= 6 ? 3.0 : 2.0);

    const dummyCard = models.Card(id: -1, isJoker: false);

    return List.generate(n, (i) {
      final t = n > 1 ? (i / (n - 1)) - 0.5 : 0.0;
      final angle = t * maxAngle * (pi / 180);
      final x = centerX + fanR * sin(angle) - cardW / 2;
      final y = 6 + fanR * (1 - cos(angle)) * 0.05;

      return Positioned(
        left: x,
        top: y,
        child: Transform.rotate(
          angle: -angle * 0.5,
          alignment: Alignment.topCenter,
          child: PlayingCard(
            card: dummyCard,
            width: cardW,
            height: cardH,
            faceDown: true,
          ),
        ),
      );
    });
  }
}

/// Premium animated name badge with glass effect
class _OpponentBadge extends StatelessWidget {
  final OpponentInfo opponent;
  const _OpponentBadge({required this.opponent});

  @override
  Widget build(BuildContext context) {
    final isActive = opponent.isActive;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFE8A317)])
            : LinearGradient(colors: [Colors.black.withOpacity(0.6), Colors.black.withOpacity(0.4)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.1),
          width: isActive ? 1.5 : 0.5,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.5),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 4)],
                ),
              ),
            ),
          Text(
            opponent.name,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              shadows: isActive ? [const Shadow(color: Colors.black26, blurRadius: 4)] : null,
            ),
          ),
          const SizedBox(width: 5),
          // Card count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isActive ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${opponent.handCount}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(isActive ? 0.9 : 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 1),
                Text('🃏', style: TextStyle(fontSize: 8)),
              ],
            ),
          ),
          if (opponent.hasOpened) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFF4CAF50).withOpacity(0.4),
                  const Color(0xFF4CAF50).withOpacity(0.2),
                ]),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5), width: 0.5),
              ),
              child: Text(
                '✓${opponent.openingScore}',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
