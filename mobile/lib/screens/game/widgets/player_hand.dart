import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/card.dart' as models;
import 'playing_card.dart';

/// Player hand with:
/// - TAP to select/deselect
/// - LONG PRESS + DRAG to reorder (overlay card follows finger, white bar shows insertion point)
/// - Auto-scroll near edges while dragging
///
/// Key design: the Row layout NEVER changes during drag (no inserted bars that shift positions).
/// The insertion bar is drawn as a positioned overlay on top of the cards.
class PlayerHandWidget extends StatefulWidget {
  final List<models.Card> cards;
  final Set<int> selectedIds;
  final Set<int> validHighlightIds;
  final void Function(int cardId) onTapCard;
  final void Function(int oldIndex, int newIndex) onReorder;

  const PlayerHandWidget({
    super.key,
    required this.cards,
    required this.selectedIds,
    this.validHighlightIds = const {},
    required this.onTapCard,
    required this.onReorder,
  });

  @override
  State<PlayerHandWidget> createState() => _PlayerHandWidgetState();
}

class _PlayerHandWidgetState extends State<PlayerHandWidget> with WidgetsBindingObserver {
  final _scrollCtrl = ScrollController();
  final _stackKey = GlobalKey();

  static const double _cardW = 52;
  static const double _cardH = 76;
  static const double _gap = 4;
  static const double _padH = 10;
  static const double _step = _cardW + _gap; // 56px per card slot
  static const double _autoZone = 60;
  static const double _autoSpeed = 8;

  int _dragIndex = -1;
  int _insertSlot = -1;
  Offset _fingerGlobal = Offset.zero;
  OverlayEntry? _floatingCard;
  Timer? _scrollTimer;

  bool get _isDragging => _dragIndex >= 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tearDown();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _cancelDragSafely();
    }
  }

  @override
  void deactivate() {
    _cancelDragSafely();
    super.deactivate();
  }

  void _cancelDragSafely() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _floatingCard?.remove();
    _floatingCard = null;
    _dragIndex = -1;
    _insertSlot = -1;
  }

  void _tearDown() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _floatingCard?.remove();
    _floatingCard = null;
  }

  // ── Convert finger global-X to a slot index (0..N) ─────
  int _xToSlot(double globalX) {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return _dragIndex;
    // localX inside the scroll content
    final localX = box.globalToLocal(Offset(globalX, 0)).dx;
    // slot = which gap the finger is closest to
    // gap i is at x = i * _step (left edge of card i)
    final slot = ((localX + _step * 0.5) / _step).floor();
    return slot.clamp(0, widget.cards.length);
  }

  // ── Auto-scroll near left/right edges ──────────────────
  void _updateScroll(double globalX) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final lx = box.globalToLocal(Offset(globalX, 0)).dx;
    final w = box.size.width;

    double speed = 0;
    if (lx < _autoZone) speed = -_autoSpeed * (1 - (lx / _autoZone).clamp(0.0, 1.0));
    else if (lx > w - _autoZone) speed = _autoSpeed * (1 - ((w - lx) / _autoZone).clamp(0.0, 1.0));

    if (speed.abs() < 0.3) {
      _scrollTimer?.cancel();
      _scrollTimer = null;
      return;
    }
    if (_scrollTimer != null) return;
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_scrollCtrl.hasClients) return;
      final p = _scrollCtrl.position;
      _scrollCtrl.jumpTo((_scrollCtrl.offset + speed).clamp(p.minScrollExtent, p.maxScrollExtent));
      // recalc slot while scrolling
      final s = _xToSlot(_fingerGlobal.dx);
      if (s != _insertSlot) { _insertSlot = s; if (mounted) setState(() {}); }
    });
  }

  // ── Drag start / move / end ────────────────────────────
  void _beginDrag(int index, Offset globalPos) {
    HapticFeedback.mediumImpact();
    _dragIndex = index;
    _insertSlot = index;
    _fingerGlobal = globalPos;
    setState(() {});

    final card = widget.cards[index];
    _floatingCard = OverlayEntry(builder: (_) => Positioned(
      left: _fingerGlobal.dx - _cardW * 0.5,
      top: _fingerGlobal.dy - _cardH - 10,
      child: IgnorePointer(child: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.15, child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.6), blurRadius: 24, spreadRadius: 4),
              BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: PlayingCard(card: card, width: _cardW, height: _cardH, selected: true),
        )),
      )),
    ));
    Overlay.of(context).insert(_floatingCard!);
  }

  void _moveDrag(Offset globalPos) {
    _fingerGlobal = globalPos;
    _floatingCard?.markNeedsBuild();
    final s = _xToSlot(globalPos.dx);
    if (s != _insertSlot) { _insertSlot = s; setState(() {}); }
    _updateScroll(globalPos.dx);
  }

  void _finishDrag() {
    _scrollTimer?.cancel(); _scrollTimer = null;
    _floatingCard?.remove(); _floatingCard = null;

    final from = _dragIndex;
    final slot = _insertSlot;
    _dragIndex = -1;
    _insertSlot = -1;

    if (from >= 0 && slot >= 0 && slot != from && slot != from + 1) {
      final newIdx = slot > from ? slot - 1 : slot;
      if (newIdx != from) {
        HapticFeedback.lightImpact();
        widget.onReorder(from, newIdx);
      }
    }
    if (mounted) setState(() {});
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final n = widget.cards.length;
    // Total content width
    final contentW = _padH * 2 + n * _step;

    return Container(
      height: _cardH + 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF5C3317), Color(0xFF3E1F00), Color(0xFF2C1810)],
        ),
        border: Border(top: BorderSide(color: const Color(0xFFD4A017).withOpacity(0.6), width: 1.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, -3)),
        ],
      ),
      child: SingleChildScrollView(
        controller: _scrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: _isDragging ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
        child: SizedBox(
          width: contentW,
          height: _cardH + 28,
          child: Stack(
            key: _stackKey,
            clipBehavior: Clip.none,
            children: [
              // ── All cards at fixed positions ──
              for (int i = 0; i < n; i++)
                Positioned(
                  left: _padH + i * _step,
                  top: 6 + (widget.selectedIds.contains(widget.cards[i].id) && _dragIndex != i ? -10.0 : 0.0),
                  child: _cardWidget(i),
                ),

              // ── Insertion bar (only during drag) ──
              if (_isDragging && _insertSlot >= 0 && _insertSlot != _dragIndex && _insertSlot != _dragIndex + 1)
                Positioned(
                  left: _padH + _insertSlot * _step - 5,
                  top: 4,
                  child: Container(
                    width: 6,
                    height: _cardH + 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFD700), Colors.white, Color(0xFFFFD700)],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(color: Colors.white.withOpacity(0.95), blurRadius: 14, spreadRadius: 4),
                        BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.7), blurRadius: 22, spreadRadius: 3),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardWidget(int i) {
    final card = widget.cards[i];
    final selected = widget.selectedIds.contains(card.id);
    final valid = widget.validHighlightIds.contains(card.id);
    final dragging = _dragIndex == i;

    return GestureDetector(
      onTap: !_isDragging ? () { HapticFeedback.selectionClick(); widget.onTapCard(card.id); } : null,
      onLongPressStart: (d) => _beginDrag(i, d.globalPosition),
      onLongPressMoveUpdate: (d) { if (_isDragging) _moveDrag(d.globalPosition); },
      onLongPressEnd: (_) { if (_isDragging) _finishDrag(); },
      onLongPressCancel: () { if (_isDragging) { _tearDown(); _dragIndex = -1; _insertSlot = -1; if (mounted) setState(() {}); } },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: dragging ? 0.15 : 1.0,
        child: SizedBox(
          width: _cardW,
          height: _cardH,
          child: dragging
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ))
              : PlayingCard(card: card, width: _cardW, height: _cardH, selected: selected, validHighlight: valid),
        ),
      ),
    );
  }
}
