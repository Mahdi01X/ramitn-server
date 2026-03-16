import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../providers/game_provider.dart';
import '../../../core/theme.dart';

/// Premium action bar with rich gradients, animated buttons, and glass morphism.
/// Two modes: pre-opening (stage → confirm) and post-opening (direct meld + discard).
class GameActionBar extends StatelessWidget {
  final int selectedCount;
  final bool selectionIsValid;
  final int selectionPoints;
  final String? selectionType;
  final List<StagedMeld> stagedMelds;
  final int stagedTotalPoints;
  final bool stagedHasCleanRun;
  final bool canConfirmOpening;
  final bool hasOpened;
  final int openingRequired;
  final bool canDiscard;
  final VoidCallback? onStageMeld;
  final VoidCallback? onConfirmOpen;
  final VoidCallback? onDirectMeld;
  final VoidCallback? onDiscard;
  final VoidCallback onClear;
  final void Function(String id)? onUnstageMeld;

  const GameActionBar({
    super.key,
    required this.selectedCount,
    required this.selectionIsValid,
    required this.selectionPoints,
    this.selectionType,
    required this.stagedMelds,
    required this.stagedTotalPoints,
    required this.stagedHasCleanRun,
    required this.canConfirmOpening,
    required this.hasOpened,
    required this.openingRequired,
    required this.canDiscard,
    this.onStageMeld,
    this.onConfirmOpen,
    this.onDirectMeld,
    this.onDiscard,
    required this.onClear,
    this.onUnstageMeld,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A2510),
            Color(0xFF3A1C0D),
            Color(0xFF2C1508),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border(
          top: BorderSide(
            color: CafeTunisienColors.gold.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, -3)),
          BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stagedMelds.isNotEmpty) _buildStagedRow(),
            _buildActionRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStagedRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: stagedMelds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 5),
          itemBuilder: (_, i) {
            final m = stagedMelds[i];
            final label = m.type == 'run' ? 'Suite' : 'Tierce';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4CAF50).withOpacity(0.35),
                    const Color(0xFF4CAF50).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.6), width: 1),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.15), blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$label ${m.points}pts',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  if (m.hasJoker)
                    const Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: Text('🃏', style: TextStyle(fontSize: 10)),
                    ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => onUnstageMeld?.call(m.id),
                    child: Container(
                      width: 16, height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.close, size: 11, color: Colors.white60),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        // Points display
        if (selectedCount >= 2)
          _PointsBadge(
            text: '$selectionPoints pts',
            color: selectionIsValid ? const Color(0xFF4CAF50) : const Color(0xFF666666),
            isValid: selectionIsValid,
          ),

        if (selectedCount >= 2) const SizedBox(width: 6),

        // Opening tracker
        if (!hasOpened)
          _OpeningTracker(
            current: stagedTotalPoints + (selectionIsValid ? selectionPoints : 0),
            required_: openingRequired,
          ),

        const Spacer(),

        // Clear selection
        if (selectedCount > 0)
          _ActionButton(
            key: const ValueKey('btn_clear'),
            icon: Icons.close,
            label: 'Annuler',
            color: Colors.white54,
            onTap: onClear,
          ),

        // PRE-OPENING: "Ajouter" button
        if (!hasOpened && selectedCount >= 3 && selectionIsValid)
          _ActionButton(
            key: const ValueKey('btn_stage_meld'),
            icon: Icons.add_box_outlined,
            label: 'Ajouter',
            color: const Color(0xFF4CAF50),
            onTap: onStageMeld,
            highlighted: true,
          ),

        // PRE-OPENING: "Ouvrir!" button
        if (!hasOpened && canConfirmOpening)
          _ActionButton(
            key: const ValueKey('btn_confirm_opening'),
            icon: Icons.check_circle,
            label: 'Ouvrir!',
            color: const Color(0xFF4CAF50),
            onTap: onConfirmOpen,
            highlighted: true,
            big: true,
          ),

        // POST-OPENING: "Poser" directly
        if (hasOpened && selectedCount >= 3 && selectionIsValid)
          _ActionButton(
            key: const ValueKey('btn_direct_meld'),
            icon: Icons.layers,
            label: 'Poser',
            color: const Color(0xFF4CAF50),
            onTap: onDirectMeld,
            highlighted: true,
          ),

        // POST-OPENING: hint when 1 card selected
        if (hasOpened && selectedCount == 1)
          _PointsBadge(text: '👆 Paquet', color: const Color(0xFF42A5F5), isValid: true),

        // Discard hint
        if (selectedCount == 0 && stagedMelds.isEmpty)
          Opacity(
            opacity: 0.35,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swipe_up_rounded, color: Colors.white.withOpacity(0.3), size: 14),
                const SizedBox(width: 3),
                Text('Glisser ↑', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 9)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Animated points badge with glow
class _PointsBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isValid;

  const _PointsBadge({required this.text, required this.color, required this.isValid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isValid ? [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
        ] : null,
      ),
      child: Text(text, style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        shadows: [Shadow(color: Colors.black26, blurRadius: 3)],
      )),
    );
  }
}

/// Opening progress tracker with animated fill
class _OpeningTracker extends StatelessWidget {
  final int current;
  final int required_;

  const _OpeningTracker({required this.current, required this.required_});

  @override
  Widget build(BuildContext context) {
    final met = current >= required_;
    final color = met ? const Color(0xFF4CAF50) : const Color(0xFFE8A317);
    final progress = required_ > 0 ? (current / required_).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini progress bar
          Container(
            width: 24, height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withOpacity(0.1),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('$current/$required_', style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          )),
        ],
      ),
    );
  }
}

/// Premium action button with haptic feedback and glow
class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool big;

  const _ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.highlighted = false,
    this.big = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween(begin: 1.0, end: 0.92).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: widget.big ? 16 : 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: widget.highlighted
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [widget.color.withOpacity(0.35), widget.color.withOpacity(0.12)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: widget.highlighted
                  ? Border.all(color: widget.color.withOpacity(0.8), width: 1.5)
                  : null,
              boxShadow: widget.highlighted
                  ? [
                      BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 10, spreadRadius: 1),
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.color, size: widget.big ? 24 : 20),
                const SizedBox(height: 1),
                Text(widget.label, style: TextStyle(
                  color: widget.color,
                  fontSize: widget.big ? 10 : 9,
                  fontWeight: FontWeight.w700,
                  shadows: widget.highlighted ? [Shadow(color: widget.color.withOpacity(0.3), blurRadius: 4)] : null,
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
