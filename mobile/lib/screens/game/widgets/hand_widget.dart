import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/card.dart' as models;
import '../../../core/theme.dart';
import 'card_widget.dart';

/// Main du joueur en arc (fan) — on peut tap pour sélectionner,
/// long-press + drag pour réorganiser, et glisser vers le haut pour défausser.
class HandWidget extends StatefulWidget {
  final List<models.Card> cards;
  final List<int> selectedIds;
  final void Function(int cardId) onCardTap;
  final void Function(int cardId)? onCardDoubleTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(int cardId)? onDragDiscard;

  const HandWidget({
    super.key,
    required this.cards,
    required this.selectedIds,
    required this.onCardTap,
    this.onCardDoubleTap,
    this.onReorder,
    this.onDragDiscard,
  });

  @override
  State<HandWidget> createState() => _HandWidgetState();
}

class _HandWidgetState extends State<HandWidget> {
  int? _dragIndex;
  Offset _dragOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final count = widget.cards.length;

    if (count == 0) {
      return Container(
        height: 140,
        decoration: _handAreaDecoration(),
        child: const Center(
          child: Text('Pas de cartes', style: TextStyle(color: Colors.white38, fontSize: 14)),
        ),
      );
    }

    // Fan layout parameters
    const cardW = 50.0;
    const cardH = 74.0;
    final maxFanAngle = (count * 2.2).clamp(15.0, 45.0); // Total arc angle in degrees
    final fanRadius = screenWidth * 1.8; // Larger = flatter arc

    return Container(
      height: 155,
      decoration: _handAreaDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          const centerY = 220.0; // Pivot point below the widget

          return Stack(
            clipBehavior: Clip.none,
            children: List.generate(count, (i) {
              final card = widget.cards[i];
              final isSelected = widget.selectedIds.contains(card.id);
              final isDragging = _dragIndex == i;

              // Calculate angle for this card in the fan
              final t = count > 1 ? (i / (count - 1)) - 0.5 : 0.0; // -0.5 to 0.5
              final angle = t * maxFanAngle * (pi / 180); // Convert to radians

              // Position on the arc
              final x = centerX + fanRadius * sin(angle) - cardW / 2;
              final y = 30 + fanRadius * (1 - cos(angle)) * 0.12 + (isSelected ? -16 : 0);

              final cardWidget = Transform.rotate(
                angle: angle * 0.7,
                child: CardWidget(
                  card: card,
                  isSelected: isSelected,
                  width: cardW,
                  height: cardH,
                  onTap: () => widget.onCardTap(card.id),
                  onDoubleTap: widget.onCardDoubleTap != null
                      ? () => widget.onCardDoubleTap!(card.id)
                      : null,
                ),
              );

              // Wrap with drag gesture
              if (widget.onDragDiscard != null || widget.onReorder != null) {
                return Positioned(
                  left: isDragging ? x + _dragOffset.dx : x,
                  top: isDragging ? y + _dragOffset.dy : y,
                  child: GestureDetector(
                    onPanStart: (_) => setState(() {
                      _dragIndex = i;
                      _dragOffset = Offset.zero;
                    }),
                    onPanUpdate: (details) => setState(() {
                      _dragOffset += details.delta;
                    }),
                    onPanEnd: (details) {
                      // If dragged up enough → discard
                      if (_dragOffset.dy < -80 && widget.onDragDiscard != null) {
                        widget.onDragDiscard!(card.id);
                      }
                      // If dragged horizontally enough → reorder
                      else if (_dragOffset.dx.abs() > cardW && widget.onReorder != null) {
                        final moveBy = (_dragOffset.dx / cardW).round();
                        final newIdx = (i + moveBy).clamp(0, count - 1);
                        if (newIdx != i) {
                          widget.onReorder!(i, newIdx > i ? newIdx + 1 : newIdx);
                        }
                      }
                      setState(() {
                        _dragIndex = null;
                        _dragOffset = Offset.zero;
                      });
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: isDragging ? 0.85 : 1.0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 150),
                        scale: isDragging ? 1.15 : 1.0,
                        child: cardWidget,
                      ),
                    ),
                  ),
                );
              }

              return Positioned(left: x, top: y, child: cardWidget);
            }),
          );
        },
      ),
    );
  }

  BoxDecoration _handAreaDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          CafeTunisienColors.woodBrown.withOpacity(0.3),
          CafeTunisienColors.woodBrown.withOpacity(0.7),
          CafeTunisienColors.woodBrown.withOpacity(0.9),
        ],
      ),
      border: const Border(
        top: BorderSide(color: CafeTunisienColors.gold, width: 1.5),
      ),
    );
  }
}
