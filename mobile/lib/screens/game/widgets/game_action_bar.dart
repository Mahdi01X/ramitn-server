import 'package:flutter/material.dart';
import '../../../providers/game_provider.dart';
import '../../../core/theme.dart';

/// Action bar with 2 modes:
/// - Pre-opening: "Poser temp" → accumulate paquets → "Confirmer ouverture"
/// - Post-opening: "Poser" directly + "Jeter"
class GameActionBar extends StatelessWidget {
  // Selection state
  final int selectedCount;
  final bool selectionIsValid;
  final int selectionPoints;
  final String? selectionType; // 'run', 'set', or null

  // Staging state
  final List<StagedMeld> stagedMelds;
  final int stagedTotalPoints;
  final bool stagedHasCleanRun;
  final bool canConfirmOpening;

  // Game state
  final bool hasOpened;
  final int openingRequired;
  final bool canDiscard;

  // Callbacks
  final VoidCallback? onStageMeld;     // Pre-opening: add to staging
  final VoidCallback? onConfirmOpen;   // Pre-opening: confirm all staged
  final VoidCallback? onDirectMeld;    // Post-opening: place directly
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3E1F00).withOpacity(0.98),
            const Color(0xFF2C1810).withOpacity(0.95),
          ],
        ),
        border: Border(
          top: BorderSide(color: CafeTunisienColors.gold.withOpacity(0.5), width: 1),
          bottom: BorderSide(color: CafeTunisienColors.gold.withOpacity(0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Staged melds chips (removable)
          if (stagedMelds.isNotEmpty) _buildStagedRow(),

          // Main action row
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildStagedRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: stagedMelds.length,
          separatorBuilder: (_, __) => const SizedBox(width: 4),
          itemBuilder: (_, i) {
            final m = stagedMelds[i];
            final label = m.type == 'run' ? 'Suite' : 'Tierce';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50), width: 1),
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
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onUnstageMeld?.call(m.id),
                    child: const Icon(Icons.close, size: 14, color: Colors.white60),
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
          _badge(
            '$selectionPoints pts',
            selectionIsValid ? const Color(0xFF4CAF50) : const Color(0xFF666666),
          ),

        if (selectedCount >= 2) const SizedBox(width: 6),

        // Opening tracker
        if (!hasOpened)
          _badge(
            '${stagedTotalPoints + (selectionIsValid ? selectionPoints : 0)}/$openingRequired',
            (stagedTotalPoints + (selectionIsValid ? selectionPoints : 0)) >= openingRequired
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE8A317),
          ),

        const Spacer(),

        // Clear selection
        if (selectedCount > 0)
          _btn(Icons.close, 'Annuler', Colors.white54, onClear, key: 'btn_clear'),

        // PRE-OPENING: "Poser temp" button
        if (!hasOpened && selectedCount >= 3 && selectionIsValid)
          _btn(Icons.add_box_outlined, 'Ajouter', const Color(0xFF4CAF50), onStageMeld, highlighted: true, key: 'btn_stage_meld'),

        // PRE-OPENING: "Confirmer ouverture" button
        if (!hasOpened && canConfirmOpening)
          _btn(Icons.check_circle, 'Ouvrir!', const Color(0xFF4CAF50), onConfirmOpen, highlighted: true, big: true, key: 'btn_confirm_opening'),

        // POST-OPENING: "Poser" directly
        if (hasOpened && selectedCount >= 3 && selectionIsValid)
          _btn(Icons.layers, 'Poser', const Color(0xFF4CAF50), onDirectMeld, highlighted: true, key: 'btn_direct_meld'),

        // POST-OPENING: hint when 1 card selected (tap a meld to lay off)
        if (hasOpened && selectedCount == 1)
          _badge('👆 Paquet', const Color(0xFF42A5F5)),

        // Discard hint (drag card up to discard)
        if (selectedCount == 0 && stagedMelds.isEmpty)
          Opacity(
            opacity: 0.4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swipe_up_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 3),
                const Text('Glisser ↑', style: TextStyle(color: Colors.white30, fontSize: 9)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback? onTap, {bool highlighted = false, bool big = false, String? key}) {
    return Padding(
      key: key != null ? ValueKey(key) : null,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: big ? 14 : 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: highlighted
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            border: highlighted
                ? Border.all(color: color.withOpacity(0.8), width: 1.5)
                : null,
            boxShadow: highlighted
                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, spreadRadius: 0)]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: big ? 24 : 20),
              const SizedBox(height: 1),
              Text(label, style: TextStyle(color: color, fontSize: big ? 10 : 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

