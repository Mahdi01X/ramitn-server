import 'package:flutter/material.dart';
import '../../../models/card.dart' as models;
import '../../../models/meld.dart';
import '../../../engine/meld_validator.dart';
import '../../../models/game_config.dart';
import '../../../providers/game_provider.dart';
import 'playing_card.dart';

/// Green-felt table area — draw pile, discard area, placed melds
class FeltTable extends StatelessWidget {
  final int drawPileCount;
  final models.Card? topDiscard;
  final List<Meld> tableMelds;
  final List<StagedMeld> stagedMelds;
  final String turnStep;
  final bool isMyTurn;
  final VoidCallback? onDrawDeck;
  final VoidCallback? onDrawDiscard;
  final int openingPoints;
  final bool hasOpened;
  final void Function(int cardId, String meldId)? onDropOnMeld;
  final void Function(int cardId)? onDropDiscard;
  final void Function(String meldId)? onTapMeld;
  final models.Card? selectedCard;
  final GameConfig config;
  // Player info for grouped melds display
  final String currentPlayerId;
  final List<({String id, String name, int openingScore, bool hasOpened})> playerInfos;

  const FeltTable({
    super.key,
    required this.drawPileCount,
    required this.topDiscard,
    required this.tableMelds,
    this.stagedMelds = const [],
    required this.turnStep,
    required this.isMyTurn,
    this.onDrawDeck,
    this.onDrawDiscard,
    this.openingPoints = 0,
    this.hasOpened = false,
    this.onDropOnMeld,
    this.onDropDiscard,
    this.onTapMeld,
    this.selectedCard,
    this.config = const GameConfig(),
    this.currentPlayerId = '',
    this.playerInfos = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.0,
          colors: [
            const Color(0xFF2E7D3A),
            const Color(0xFF1B5E20),
            const Color(0xFF0D3B13),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _FeltTexturePainter())),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 8),
              _PileZone(
                drawCount: drawPileCount,
                topDiscard: topDiscard,
                canDraw: isMyTurn && turnStep == 'draw',
                canDrop: isMyTurn && turnStep == 'play',
                onDrawDeck: onDrawDeck,
                onDrawDiscard: onDrawDiscard,
                onDropDiscard: onDropDiscard,
              ),
              const SizedBox(height: 6),
              _StatusBadge(isMyTurn: isMyTurn, turnStep: turnStep),
              const SizedBox(height: 4),
              if (stagedMelds.isNotEmpty) _StagedMeldsZone(staged: stagedMelds),
              Expanded(
                child: _MeldsZone(
                  melds: tableMelds,
                  hasOpened: hasOpened,
                  isMyTurn: isMyTurn && turnStep == 'play',
                  onDropOnMeld: onDropOnMeld,
                  onDropDiscard: onDropDiscard,
                  onTapMeld: onTapMeld,
                  selectedCard: selectedCard,
                  config: config,
                  currentPlayerId: currentPlayerId,
                  playerInfos: playerInfos,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pile Zone (draw + discard drop target) ──────────────────

class _PileZone extends StatelessWidget {
  final int drawCount;
  final models.Card? topDiscard;
  final bool canDraw;
  final bool canDrop;
  final VoidCallback? onDrawDeck;
  final VoidCallback? onDrawDiscard;
  final void Function(int cardId)? onDropDiscard;

  const _PileZone({
    required this.drawCount,
    required this.topDiscard,
    required this.canDraw,
    required this.canDrop,
    this.onDrawDeck,
    this.onDrawDiscard,
    this.onDropDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Draw pile
        GestureDetector(
          onTap: canDraw ? onDrawDeck : null,
          child: Stack(
            children: [
              if (drawCount > 4) Transform.translate(offset: const Offset(2, 2), child: _deckCard(false)),
              if (drawCount > 2) Transform.translate(offset: const Offset(1, 1), child: _deckCard(false)),
              _deckCard(canDraw),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2113),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD4A017), width: 0.5),
                  ),
                  child: Text('$drawCount',
                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        // Discard pile — also a DragTarget for discarding cards
        DragTarget<int>(
          onWillAcceptWithDetails: (details) => canDrop,
          onAcceptWithDetails: (details) => onDropDiscard?.call(details.data),
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return GestureDetector(
              onTap: canDraw && topDiscard != null ? onDrawDiscard : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isHovering
                        ? const Color(0xFFFFD700)
                        : canDraw && topDiscard != null
                            ? const Color(0xFFFFD700)
                            : Colors.white.withOpacity(0.15),
                    width: isHovering ? 3 : canDraw && topDiscard != null ? 2 : 1,
                  ),
                  boxShadow: isHovering
                      ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 16)]
                      : canDraw && topDiscard != null
                          ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 10)]
                          : null,
                  color: isHovering ? const Color(0xFFFFD700).withOpacity(0.1) : null,
                ),
                child: topDiscard != null
                    ? Stack(
                        children: [
                          PlayingCard(card: topDiscard!, width: 54, height: 78),
                          if (isHovering)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                ),
                                child: const Center(
                                  child: Icon(Icons.arrow_downward, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isHovering ? Icons.arrow_downward : Icons.layers_clear,
                              color: isHovering ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.1),
                              size: 22,
                            ),
                            if (isHovering)
                              const Text('Jeter', style: TextStyle(color: Color(0xFFFFD700), fontSize: 8)),
                          ],
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _deckCard(bool glow) {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFB22222), Color(0xFF8B0000)],
        ),
        border: Border.all(color: glow ? const Color(0xFFFFD700) : Colors.white12, width: glow ? 2 : 0.7),
        boxShadow: [
          if (glow) BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.35), blurRadius: 12, spreadRadius: 1),
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(2, 3)),
        ],
      ),
      child: Center(child: Text('✦', style: TextStyle(fontSize: 20, color: const Color(0xFFFFD700).withOpacity(glow ? 0.9 : 0.4)))),
    );
  }
}

// ─── Status Badge ────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isMyTurn;
  final String turnStep;
  const _StatusBadge({required this.isMyTurn, required this.turnStep});

  @override
  Widget build(BuildContext context) {
    if (!isMyTurn) return const SizedBox.shrink();
    final isDraw = turnStep == 'draw';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (isDraw ? const Color(0xFFE8A317) : const Color(0xFF4CAF50)).withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        isDraw ? '☝ Piochez une carte' : '🃏 Sélectionnez vos cartes — posez ou défaussez',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }
}

// ─── Staged Melds Zone ───────────────────────────────────────

class _StagedMeldsZone extends StatelessWidget {
  final List<StagedMeld> staged;
  const _StagedMeldsZone({required this.staged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔓 Paquets en attente d\'ouverture',
            style: TextStyle(color: const Color(0xFFFFD700).withOpacity(0.7), fontSize: 10)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8, runSpacing: 4, alignment: WrapAlignment.center,
            children: staged.map((m) => Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: m.cards.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: PlayingCard(card: c, width: 28, height: 42),
                )).toList(),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Melds Zone (each meld is a DragTarget) ──────────────────

class _MeldsZone extends StatelessWidget {
  final List<Meld> melds;
  final bool hasOpened;
  final bool isMyTurn;
  final void Function(int cardId, String meldId)? onDropOnMeld;
  final void Function(int cardId)? onDropDiscard;
  final void Function(String meldId)? onTapMeld;
  final models.Card? selectedCard;
  final GameConfig config;
  final String currentPlayerId;
  final List<({String id, String name, int openingScore, bool hasOpened})> playerInfos;

  const _MeldsZone({
    required this.melds,
    required this.hasOpened,
    required this.isMyTurn,
    this.onDropOnMeld,
    this.onDropDiscard,
    this.onTapMeld,
    this.selectedCard,
    this.config = const GameConfig(),
    this.currentPlayerId = '',
    this.playerInfos = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (melds.isEmpty) {
      return Center(
        child: Text(
          '☕ Table vide — posez vos combinaisons',
          style: TextStyle(color: Colors.white.withOpacity(0.12), fontSize: 13),
        ),
      );
    }

    // Group melds by owner
    final otherMelds = <String, List<Meld>>{}; // ownerId -> melds
    final myMelds = <Meld>[];
    final unknownMelds = <Meld>[];

    for (final m in melds) {
      if (m.ownerId == currentPlayerId) {
        myMelds.add(m);
      } else if (m.ownerId != null) {
        otherMelds.putIfAbsent(m.ownerId!, () => []).add(m);
      } else {
        unknownMelds.add(m);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          // Other players' melds (top)
          for (final entry in otherMelds.entries)
            _buildPlayerMeldsSection(entry.key, entry.value, false),

          // Unknown melds (legacy)
          if (unknownMelds.isNotEmpty)
            _buildMeldsWrap(unknownMelds),

          // My melds (bottom, closer to my hand)
          if (myMelds.isNotEmpty)
            _buildPlayerMeldsSection(currentPlayerId, myMelds, true),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPlayerMeldsSection(String playerId, List<Meld> playerMelds, bool isMe) {
    final info = playerInfos.where((p) => p.id == playerId).firstOrNull;
    final name = isMe ? 'Mes paquets' : (info?.name ?? 'Joueur');
    final openScore = info?.openingScore ?? 0;
    final opened = info?.hasOpened ?? false;
    final color = isMe ? const Color(0xFF4CAF50) : const Color(0xFFE8A317);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: player name + opening score
          Row(
            children: [
              Icon(isMe ? Icons.person : Icons.person_outline,
                  color: color.withOpacity(0.7), size: 14),
              const SizedBox(width: 4),
              Text(name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (opened)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ouverture: ${openScore}pts',
                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _buildMeldsWrap(playerMelds),
        ],
      ),
    );
  }

  Widget _buildMeldsWrap(List<Meld> meldsList) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: meldsList.map((m) {
        final canLayoffHere = selectedCard != null && hasOpened && isMyTurn
            && canLayoffAny(selectedCard!, m, config);
        return _MeldDropTarget(
          meld: m,
          canAccept: hasOpened && isMyTurn,
          onDrop: onDropOnMeld,
          onTap: canLayoffHere && onTapMeld != null ? () => onTapMeld!(m.id) : null,
          isLayoffTarget: canLayoffHere,
          config: config,
        );
      }).toList(),
    );
  }
}

/// Each meld on the table — colored border by type (blue=run, orange=set)
/// When a compatible card is selected, glows green and is tappable for layoff
class _MeldDropTarget extends StatelessWidget {
  final Meld meld;
  final bool canAccept;
  final void Function(int cardId, String meldId)? onDrop;
  final VoidCallback? onTap;
  final bool isLayoffTarget;
  final GameConfig config;

  const _MeldDropTarget({
    required this.meld,
    required this.canAccept,
    this.onDrop,
    this.onTap,
    this.isLayoffTarget = false,
    this.config = const GameConfig(),
  });

  @override
  Widget build(BuildContext context) {
    final isRun = meld.type == MeldType.run;
    final borderColor = isLayoffTarget
        ? const Color(0xFF4CAF50)
        : isRun ? const Color(0xFF42A5F5) : const Color(0xFFFF9800);
    final labelText = isRun ? 'Suite' : 'Tierce';

    return GestureDetector(
      onTap: onTap,
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => canAccept,
        onAcceptWithDetails: (details) => onDrop?.call(details.data, meld.id),
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          final highlight = isLayoffTarget || isHovering;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: highlight
                      ? const Color(0xFF4CAF50).withOpacity(0.25)
                      : Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: highlight ? const Color(0xFF4CAF50) : borderColor.withOpacity(0.6),
                    width: highlight ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    if (highlight)
                      BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.5), blurRadius: 14, spreadRadius: 1)
                    else
                      BoxShadow(color: borderColor.withOpacity(0.15), blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...meld.cards.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: PlayingCard(card: c, width: 30, height: 44),
                    )),
                    if (highlight)
                      Container(
                        width: 30, height: 44,
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                          color: const Color(0xFF4CAF50).withOpacity(0.2),
                        ),
                        child: const Center(child: Icon(Icons.add, color: Color(0xFF4CAF50), size: 16)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: borderColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(labelText, style: TextStyle(color: borderColor, fontSize: 8, fontWeight: FontWeight.w600)),
                  ),
                  if (isLayoffTarget) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('TAP +', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Felt Texture Painter ────────────────────────────────────

class _FeltTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 0.5;
    // Subtle diagonal lines for texture
    for (double i = -size.height; i < size.width + size.height; i += 12) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




