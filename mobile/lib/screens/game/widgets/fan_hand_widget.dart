import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/card.dart' as models;
import '../../../services/sfx_service.dart';
import 'playing_card.dart';

/// Premium fan/arc hand — cards are laid out in a realistic arc like held in a real hand.
/// Fully adaptive to any screen size: all cards are ALWAYS visible.
/// TAP to select, DRAG to reorder (single or selected group), drag up to discard.
/// Same gesture for all card manipulation — instant touch response.
/// Supports receiving a drawn card via DragTarget.
class FanHandWidget extends StatefulWidget {
  final List<models.Card> cards;
  final Set<int> selectedIds;
  final Set<int> validHighlightIds;
  final int? newlyDrawnCardId;
  final void Function(int cardId) onTapCard;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(List<int> cardIds, int insertIndex)? onReorderGroup;
  final void Function(int cardId)? onDragToDiscard;
  /// Called when a drawn card is dropped onto the hand at a specific insert index.
  final void Function(int insertIndex)? onDropDrawnCard;

  const FanHandWidget({
    super.key,
    required this.cards,
    required this.selectedIds,
    this.validHighlightIds = const {},
    this.newlyDrawnCardId,
    required this.onTapCard,
    required this.onReorder,
    this.onReorderGroup,
    this.onDragToDiscard,
    this.onDropDrawnCard,
  });

  @override
  State<FanHandWidget> createState() => _FanHandWidgetState();
}

class _FanHandWidgetState extends State<FanHandWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Drag reorder state
  int _dragIndex = -1;
  int _insertSlot = -1;
  Offset _fingerGlobal = Offset.zero;
  OverlayEntry? _floatingCard;
  bool _dragStartedUpward = false;
  bool _isDraggingGroup = false; // true when dragging selected group

  // Layout cache
  final _stackKey = GlobalKey();
  // Key to locate the hand area for discard zone detection
  final _handAreaKey = GlobalKey();

  bool get _isDragging => _dragIndex >= 0;

  // Animation for initial deal
  late AnimationController _dealController;
  late Animation<double> _dealAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dealController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _dealAnimation = CurvedAnimation(
      parent: _dealController,
      curve: Curves.easeOutBack,
    );
    _dealController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelDragSafely();
    _dealController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Cancel any drag in progress when app goes to background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _cancelDragSafely();
    }
  }

  @override
  void deactivate() {
    // Cancel drag when widget is removed from tree (navigation, etc.)
    _cancelDragSafely();
    super.deactivate();
  }

  /// Safely cancel any drag in progress and clean up overlay
  void _cancelDragSafely() {
    _floatingCard?.remove();
    _floatingCard = null;
    _dragIndex = -1;
    _insertSlot = -1;
    _isDraggingGroup = false;
    _dragStartedUpward = false;
  }

  @override
  void didUpdateWidget(covariant FanHandWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the cards have changed (different length or different card set), cancel any active drag
    // This prevents ghost overlay cards when a discard/draw changes the hand
    if (widget.cards.length != oldWidget.cards.length ||
        (widget.cards.isNotEmpty && oldWidget.cards.isNotEmpty &&
         widget.cards.first.id != oldWidget.cards.first.id)) {
      if (_isDragging) {
        _cancelDragSafely();
        if (mounted) setState(() {});
      }
    }
  }

  void _tearDown() {
    _floatingCard?.remove();
    _floatingCard = null;
  }

  // ─── Adaptive card dimensions ────────────────────────────
  double _cardWidth(double screenWidth, int cardCount) {
    const maxW = 52.0;
    const minW = 28.0;
    final available = screenWidth - 20;
    final overlapRatio = cardCount <= 5 ? 0.6 : (0.38 + (5 / cardCount) * 0.22).clamp(0.25, 0.6);
    final neededWidth = cardCount > 1
        ? maxW + (cardCount - 1) * maxW * overlapRatio
        : maxW;
    if (neededWidth <= available) return maxW;
    final scale = available / neededWidth;
    return (maxW * scale).clamp(minW, maxW);
  }

  double _cardHeight(double cardW) => cardW * 1.45;

  // ─── Fan layout math — wider arc ─────────────────────────
  _CardLayout _layoutForCard(int i, int n, double width, double cardW, double cardH) {
    if (n == 0) return const _CardLayout(0, 0, 0);

    final centerX = width / 2;

    // WIDER arc angle — ensures all cards are clearly visible and spread
    final maxAngleDeg = (n * 3.2).clamp(14.0, 65.0);
    // Fan radius: adaptive — smaller radius = more curvature
    final fanR = width * (n <= 5 ? 2.2 : n <= 8 ? 1.6 : n <= 12 ? 1.2 : 0.95);
    final baseY = cardH * 0.28;

    final t = n > 1 ? (i / (n - 1)) - 0.5 : 0.0;
    final angle = t * maxAngleDeg * (pi / 180);

    final x = centerX + fanR * sin(angle) - cardW / 2;
    final y = baseY + fanR * (1 - cos(angle)) * 0.15;

    return _CardLayout(x, y, angle * 0.55);
  }

  // ─── Determine insert slot from finger X ─────────────────
  int _xToSlot(double globalX, double width, double cardW, double cardH) {
    final n = widget.cards.length;
    if (n <= 1) return 0;

    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return _dragIndex;
    final localX = box.globalToLocal(Offset(globalX, 0)).dx;

    double minDist = double.infinity;
    int best = 0;
    for (int s = 0; s <= n; s++) {
      double sx;
      if (s < n) {
        final lay = _layoutForCard(s, n, width, cardW, cardH);
        sx = lay.x + cardW / 2;
      } else {
        final lay = _layoutForCard(n - 1, n, width, cardW, cardH);
        sx = lay.x + cardW;
      }
      final d = (localX - sx).abs();
      if (d < minDist) { minDist = d; best = s; }
    }
    return best;
  }

  // ─── Drag lifecycle ──────────────────────────────────────
  void _beginDrag(int index, Offset globalPos, double cardW, double cardH) {
    SfxService.instance.cardPickUp();
    final card = widget.cards[index];
    final isSelectedCard = widget.selectedIds.contains(card.id);
    final hasGroupSelection = widget.selectedIds.length > 1;

    _dragIndex = index;
    _insertSlot = index;
    _fingerGlobal = globalPos;
    _dragStartedUpward = false;
    _isDraggingGroup = isSelectedCard && hasGroupSelection;
    setState(() {});

    // Build floating card(s)
    _floatingCard = OverlayEntry(builder: (_) {
      // Detect if finger is above the hand area (discard zone)
      final handBox = _handAreaKey.currentContext?.findRenderObject() as RenderBox?;
      bool isDragUp;
      if (handBox != null && handBox.attached) {
        final handTopGlobal = handBox.localToGlobal(Offset.zero).dy;
        isDragUp = _fingerGlobal.dy < (handTopGlobal - 30);
      } else {
        isDragUp = _fingerGlobal.dy < (MediaQuery.of(context).size.height - 200);
      }
      final groupCards = _isDraggingGroup
          ? widget.cards.where((c) => widget.selectedIds.contains(c.id)).toList()
          : [card];

      return Positioned(
        left: _fingerGlobal.dx - cardW * 0.5,
        top: _fingerGlobal.dy - cardH - 24,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.18,
              child: SizedBox(
                width: cardW + (groupCards.length - 1) * 14,
                height: cardH + 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Glow behind
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(cardW * 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: isDragUp
                                  ? Colors.redAccent.withOpacity(0.7)
                                  : const Color(0xFFFFD700).withOpacity(0.7),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Stacked cards (fanned slightly for group)
                    for (int gi = 0; gi < groupCards.length; gi++)
                      Positioned(
                        left: gi * 14.0,
                        top: gi * 1.0,
                        child: PlayingCard(
                          card: groupCards[gi],
                          width: cardW,
                          height: cardH,
                          selected: true,
                        ),
                      ),
                    // Group badge
                    if (groupCards.length > 1)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFD700),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4)],
                          ),
                          child: Center(
                            child: Text('${groupCards.length}',
                              style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
    Overlay.of(context).insert(_floatingCard!);
  }

  void _moveDrag(Offset globalPos, double width, double cardW, double cardH) {
    _fingerGlobal = globalPos;
    _floatingCard?.markNeedsBuild();

    // Detect if finger is above the hand area (= in the table zone = discard)
    final handBox = _handAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (handBox != null && handBox.attached) {
      final handTopGlobal = handBox.localToGlobal(Offset.zero).dy;
      // Card is "out of hand" if the finger is above the hand area top edge (with 30px tolerance)
      _dragStartedUpward = globalPos.dy < (handTopGlobal - 30);
    } else {
      // Fallback to screen-based detection
      final screenH = MediaQuery.of(context).size.height;
      _dragStartedUpward = globalPos.dy < (screenH - 220);
    }

    final s = _xToSlot(globalPos.dx, width, cardW, cardH);
    if (s != _insertSlot) {
      _insertSlot = s;
      SfxService.instance.cardSlide();
      setState(() {});
    }
  }

  void _finishDrag(double width) {
    _floatingCard?.remove();
    _floatingCard = null;

    final from = _dragIndex;
    final slot = _insertSlot;
    final wasDraggingGroup = _isDraggingGroup;
    _dragIndex = -1;
    _insertSlot = -1;
    _isDraggingGroup = false;

    // If dragged upward → discard
    if (_dragStartedUpward && widget.onDragToDiscard != null) {
      final card = widget.cards[from];
      SfxService.instance.cardDiscard();
      widget.onDragToDiscard!(card.id);
      _dragStartedUpward = false;
      if (mounted) setState(() {});
      return;
    }

    // Group move
    if (wasDraggingGroup && widget.onReorderGroup != null) {
      final selectedIds = widget.selectedIds.toList();
      if (slot >= 0) {
        SfxService.instance.cardSlide();
        widget.onReorderGroup!(selectedIds, slot);
      }
      _dragStartedUpward = false;
      if (mounted) setState(() {});
      return;
    }

    // Single card reorder
    if (from >= 0 && slot >= 0 && slot != from && slot != from + 1) {
      final newIdx = slot > from ? slot - 1 : slot;
      if (newIdx != from) {
        SfxService.instance.cardSlide();
        widget.onReorder(from, newIdx);
      }
    }
    _dragStartedUpward = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.cards.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardW = _cardWidth(screenWidth, n);
    final cardH = _cardHeight(cardW);

    return DragTarget<String>(
      // Accept "drawn_card" type drags
      onWillAcceptWithDetails: (details) => details.data == 'drawn_card',
      onAcceptWithDetails: (details) {
        // When a drawn card is dropped on hand, find insert slot from position
        final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.attached) {
          final localX = box.globalToLocal(details.offset).dx;
          final slot = _xToSlot(details.offset.dx, screenWidth, cardW, cardH);
          widget.onDropDrawnCard?.call(slot);
        } else {
          widget.onDropDrawnCard?.call(n); // append at end
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isReceiving = candidateData.isNotEmpty;
        return Container(
          key: _handAreaKey,
          height: cardH + 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF5A3015),
                Color(0xFF4E2B12),
                Color(0xFF42220E),
                Color(0xFF3A1E0C),
                Color(0xFF2C1508),
              ],
              stops: [0.0, 0.2, 0.5, 0.75, 1.0],
            ),
            border: Border(
              top: BorderSide(
                color: isReceiving
                    ? const Color(0xFF4CAF50).withOpacity(0.8)
                    : const Color(0xFFD4A017).withOpacity(0.65),
                width: isReceiving ? 3 : 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isReceiving
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : Colors.black.withOpacity(0.65),
                blurRadius: isReceiving ? 22 : 18,
                offset: const Offset(0, -6),
              ),
              // Inner warm glow from the top edge
              BoxShadow(
                color: const Color(0xFFD4A017).withOpacity(isReceiving ? 0.0 : 0.06),
                blurRadius: 30,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: n == 0 && !isReceiving
              ? Center(
                  child: Text(
                    'Pas de cartes',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.15),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : AnimatedBuilder(
                  animation: _dealAnimation,
                  builder: (context, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return Stack(
                          key: _stackKey,
                          clipBehavior: Clip.none,
                          children: [
                            // Receiving hint
                            if (isReceiving)
                              Positioned(
                                top: 4, left: 0, right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('↓ Placez ici', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),

                            // Discard hint zone — visible when card is dragged out of hand area
                            if (_isDragging && _dragStartedUpward && widget.onDragToDiscard != null)
                              Positioned(
                                top: -40, left: 0, right: 0, height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Colors.redAccent.withOpacity(0.5), Colors.redAccent.withOpacity(0.1)],
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.9), size: 14),
                                        const SizedBox(width: 4),
                                        const Text('Défausser', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // All cards in fan layout
                            for (int i = 0; i < n; i++)
                              _buildFanCard(i, n, width, cardW, cardH),

                            // Insertion indicator bar
                            if (_isDragging &&
                                _insertSlot >= 0 &&
                                _insertSlot != _dragIndex &&
                                (_isDraggingGroup || _insertSlot != _dragIndex + 1) &&
                                !_dragStartedUpward)
                              _buildInsertionBar(n, width, cardW, cardH),
                          ],
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildFanCard(int i, int n, double width, double cardW, double cardH) {
    final card = widget.cards[i];
    final isSelected = widget.selectedIds.contains(card.id);
    final isValid = widget.validHighlightIds.contains(card.id);
    final isNewlyDrawn = widget.newlyDrawnCardId == card.id;
    final isDragging = _dragIndex == i;
    // If dragging group, hide all selected cards
    final isHiddenByGroupDrag = _isDraggingGroup && isSelected && _dragIndex != i;
    final lay = _layoutForCard(i, n, width, cardW, cardH);

    final yOffset = isNewlyDrawn ? -22.0 : (isSelected && !isDragging && !_isDraggingGroup ? -16.0 : 0.0);

    // Deal animation
    final dealProgress = _dealAnimation.value;
    final cardDelay = (i / max(n, 1)).clamp(0.0, 1.0);
    final cardProgress = ((dealProgress - cardDelay * 0.3) / 0.7).clamp(0.0, 1.0);
    final dealY = (1 - cardProgress) * 80;
    final dealOpacity = cardProgress;

    return Positioned(
      left: lay.x,
      top: lay.y + yOffset + dealY,
      child: Opacity(
        opacity: (isDragging || isHiddenByGroupDrag) ? 0.1 : dealOpacity,
        child: GestureDetector(
          // Tap = select card
          onTap: !_isDragging
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onTapCard(card.id);
                }
              : null,
          // Short long-press (150ms) = start drag for reorder or discard
          onLongPressStart: (d) => _beginDrag(i, d.globalPosition, cardW, cardH),
          onLongPressMoveUpdate: (d) {
            if (_isDragging) _moveDrag(d.globalPosition, width, cardW, cardH);
          },
          onLongPressEnd: (_) {
            if (_isDragging) _finishDrag(width);
          },
          onLongPressCancel: () {
            if (_isDragging) {
              _cancelDragSafely();
              if (mounted) setState(() {});
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..rotateZ(lay.rotation)
              ..translate(0.0, isSelected && !isDragging && !_isDraggingGroup ? -2.0 : 0.0),
            transformAlignment: Alignment.bottomCenter,
            child: SizedBox(
              width: cardW,
              height: cardH,
              child: (isDragging || isHiddenByGroupDrag)
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(cardW * 0.12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                    )
                  : Draggable<int>(
                      data: card.id,
                      maxSimultaneousDrags: 1,
                      onDragEnd: (_) {
                        // Ensure no stale state after native drag ends
                        if (mounted) setState(() {});
                      },
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.scale(
                          scale: 1.15,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(cardW * 0.12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: PlayingCard(
                              card: card,
                              width: cardW,
                              height: cardH,
                              selected: true,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.15,
                        child: PlayingCard(card: card, width: cardW, height: cardH),
                      ),
                      child: _wrapNewlyDrawn(
                        isNewlyDrawn: isNewlyDrawn,
                        cardW: cardW,
                        cardH: cardH,
                        child: PlayingCard(
                          card: card,
                          width: cardW,
                          height: cardH,
                          selected: isSelected || isNewlyDrawn,
                          validHighlight: isValid,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Wraps a newly drawn card with a pulsing green glow + "Place-moi" label
  Widget _wrapNewlyDrawn({required bool isNewlyDrawn, required double cardW, required double cardH, required Widget child}) {
    if (!isNewlyDrawn) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Green glow behind
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardW * 0.12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.7),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF81C784).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        // The card itself
        child,
        // Label badge on top
        Positioned(
          top: -10,
          left: -6,
          right: -6,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4)],
              ),
              child: const Text('↕', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsertionBar(int n, double width, double cardW, double cardH) {
    double barX;
    if (_insertSlot < n) {
      final lay = _layoutForCard(_insertSlot, n, width, cardW, cardH);
      barX = lay.x - 3;
    } else {
      final lay = _layoutForCard(n - 1, n, width, cardW, cardH);
      barX = lay.x + cardW + 3;
    }

    return Positioned(
      left: barX,
      top: cardH * 0.15,
      child: Container(
        width: 4,
        height: cardH - 6,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD700), Color(0xFFFFF8E1), Colors.white, Color(0xFFFFF8E1), Color(0xFFFFD700)],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 16, spreadRadius: 5),
            BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.8), blurRadius: 24, spreadRadius: 4),
            BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 40, spreadRadius: 6),
          ],
        ),
      ),
    );
  }
}

class _CardLayout {
  final double x, y, rotation;
  const _CardLayout(this.x, this.y, this.rotation);
}
