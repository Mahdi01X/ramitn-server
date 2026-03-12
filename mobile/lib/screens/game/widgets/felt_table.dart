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
    return DragTarget<int>(
      // Accept cards dragged from hand for discard (anywhere on the table)
      onWillAcceptWithDetails: (details) =>
          onDropDiscard != null && isMyTurn && turnStep == 'play',
      onAcceptWithDetails: (details) => onDropDiscard?.call(details.data),
      builder: (context, candidateData, rejectedData) {
        final isDroppingOnTable = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                isDroppingOnTable ? const Color(0xFF3E8D42) : const Color(0xFF367D3A),
                const Color(0xFF256B28),
                const Color(0xFF1B5E20),
                const Color(0xFF0D3B13),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
            border: isDroppingOnTable
                ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _FeltTexturePainter())),
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.15), width: 2),
                  ),
                ),
              ),
              // Hint when dragging a card onto the table
              if (isDroppingOnTable)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 12),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Défausser ici',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
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
      },
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
        // Draw pile — Draggable: drag a card from the pile to your hand
        canDraw
            ? LongPressDraggable<String>(
                data: 'drawn_card',
                delay: const Duration(milliseconds: 150),
                hapticFeedbackOnStart: true,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.7),
                            blurRadius: 24,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: PlayingCard(
                        card: const models.Card(id: -1, isJoker: false),
                        width: 56,
                        height: 80,
                        faceDown: true,
                        selected: true,
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _deckStack(true),
                ),
                onDragCompleted: () {
                  // Drag completed → card accepted by hand → trigger draw
                  onDrawDeck?.call();
                },
                child: GestureDetector(
                  onTap: onDrawDeck,
                  child: _deckStack(true),
                ),
              )
            : _deckStack(false),
        const SizedBox(width: 28),
        // Discard pile — also a DragTarget for discarding cards
        DragTarget<int>(
          key: const ValueKey('discard_pile'),
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

  Widget _deckStack(bool glow) {
    return Stack(
      key: const ValueKey('draw_pile'),
      children: [
        if (drawCount > 4) Transform.translate(offset: const Offset(2, 2), child: _deckCard(false)),
        if (drawCount > 2) Transform.translate(offset: const Offset(1, 1), child: _deckCard(false)),
        _deckCard(glow),
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
    );
  }

  Widget _deckCard(bool glow) {
    return Container(
      width: 56,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          if (glow) BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.45), blurRadius: 18, spreadRadius: 3),
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(2, 4)),
        ],
      ),
      child: PlayingCard(
        card: const models.Card(id: -1, isJoker: false),
        width: 56,
        height: 80,
        faceDown: true,
        selected: glow,
      ),
    );
  }
}

// ─── Status Badge (pulsing) ──────────────────────────────────

class _StatusBadge extends StatefulWidget {
  final bool isMyTurn;
  final String turnStep;
  const _StatusBadge({required this.isMyTurn, required this.turnStep});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMyTurn) return const SizedBox.shrink();
    final isDraw = widget.turnStep == 'draw';
    final color = isDraw ? const Color(0xFFE8A317) : const Color(0xFF4CAF50);

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final glow = 0.6 + _pulseCtrl.value * 0.4;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(glow * 0.5),
                blurRadius: 12 * glow,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDraw ? Icons.touch_app_rounded : Icons.style_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                isDraw ? 'Piochez une carte' : 'Sélectionnez et jouez',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ],
          ),
        );
      },
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
    final infoMatches = playerInfos.where((p) => p.id == playerId);
    final info = infoMatches.isNotEmpty ? infoMatches.first : null;
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
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: highlight
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF4CAF50).withOpacity(0.3),
                            const Color(0xFF4CAF50).withOpacity(0.12),
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.22),
                            Colors.black.withOpacity(0.12),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: highlight ? const Color(0xFF4CAF50) : borderColor.withOpacity(0.5),
                    width: highlight ? 2.5 : 1.2,
                  ),
                  boxShadow: [
                    if (highlight)
                      BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.5), blurRadius: 16, spreadRadius: 2)
                    else
                      BoxShadow(color: borderColor.withOpacity(0.12), blurRadius: 6),
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
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
    // Right-leaning diagonal lines (thread texture)
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.03)
      ..strokeWidth = 0.5;
    for (double i = -size.height; i < size.width + size.height; i += 8) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
    // Left-leaning cross-hatch
    final paint2 = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.3;
    for (double i = 0; i < size.width + size.height; i += 11) {
      canvas.drawLine(Offset(i, size.height), Offset(i - size.height, 0), paint2);
    }
    // Subtle center spotlight (warm tone)
    final spotlight = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.55,
        colors: [
          const Color(0xFFFFD700).withOpacity(0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), spotlight);

    // Vignette (dark edges)
    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.15),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




