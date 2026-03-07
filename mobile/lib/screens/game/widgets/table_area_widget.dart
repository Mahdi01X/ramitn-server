import 'package:flutter/material.dart';
import '../../../models/card.dart' as models;
import '../../../models/meld.dart';
import '../../../core/theme.dart';
import 'card_widget.dart';

class TableAreaWidget extends StatelessWidget {
  final int drawPileCount;
  final models.Card? topDiscard;
  final List<Meld> tableMelds;
  final String turnStep;
  final bool isMyTurn;
  final VoidCallback? onDrawDeck;
  final VoidCallback? onDrawDiscard;

  const TableAreaWidget({
    super.key,
    required this.drawPileCount,
    required this.topDiscard,
    required this.tableMelds,
    required this.turnStep,
    required this.isMyTurn,
    this.onDrawDeck,
    this.onDrawDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Tapis de jeu avec texture
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            CafeTunisienColors.tableGreenLight,
            CafeTunisienColors.tableGreen,
            const Color(0xFF143D24),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Smoke/ambiance overlay (chicha effect)
          ...List.generate(3, (i) => Positioned(
            left: 20.0 + i * 120,
            top: 10.0 + i * 30,
            child: _SmokeParticle(delay: i * 2),
          )),

          // Table border decoration
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CafeTunisienColors.gold.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Central pile area
                _buildPileArea(),

                const SizedBox(height: 8),

                // Status indicator
                _buildStatusBadge(),

                const SizedBox(height: 8),

                // Table melds
                Expanded(child: _buildTableMelds()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPileArea() {
    final canDraw = isMyTurn && turnStep == 'draw';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Draw pile (single deck)
        GestureDetector(
          onTap: canDraw ? onDrawDeck : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                // Shadow cards behind
                if (drawPileCount > 4)
                  Transform.translate(
                    offset: const Offset(3, 3),
                    child: _buildDeckCard(glow: false),
                  ),
                if (drawPileCount > 2)
                  Transform.translate(
                    offset: const Offset(1.5, 1.5),
                    child: _buildDeckCard(glow: false),
                  ),
                _buildDeckCard(glow: canDraw),
                // Card count
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CafeTunisienColors.woodBrown,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CafeTunisienColors.gold, width: 0.5),
                    ),
                    child: Text(
                      '$drawPileCount',
                      style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 30),

        // Discard pile
        GestureDetector(
          onTap: canDraw && topDiscard != null ? onDrawDiscard : null,
          child: Container(
            width: 60,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: canDraw && topDiscard != null
                    ? CafeTunisienColors.goldLight
                    : CafeTunisienColors.gold.withOpacity(0.3),
                width: canDraw && topDiscard != null ? 2 : 1,
              ),
              color: topDiscard == null ? Colors.white.withOpacity(0.05) : null,
              boxShadow: canDraw && topDiscard != null
                  ? [BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.3), blurRadius: 12)]
                  : null,
            ),
            child: topDiscard != null
                ? CardWidget(card: topDiscard!, width: 58, height: 82)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers_clear, color: Colors.white.withOpacity(0.15), size: 24),
                        const SizedBox(height: 2),
                        Text('Talon', style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 9)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckCard({required bool glow}) {
    return Container(
      width: 60,
      height: 84,
      decoration: BoxDecoration(
        color: CafeTunisienColors.cardBack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: glow ? CafeTunisienColors.goldLight : Colors.white12,
          width: glow ? 2 : 0.8,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.4), blurRadius: 14, spreadRadius: 2),
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(2, 3)),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB22222), Color(0xFF8B0000), Color(0xFF6B0000)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✦', style: TextStyle(fontSize: 22, color: CafeTunisienColors.goldLight.withOpacity(0.6))),
            if (glow)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('Pioche', style: TextStyle(color: CafeTunisienColors.goldLight, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (!isMyTurn) return const SizedBox.shrink();

    final isDrawPhase = turnStep == 'draw';
    final text = isDrawPhase ? '☝️ Touchez le paquet pour piocher' : '🃏 Glissez une carte vers le haut pour défausser';
    final color = isDrawPhase ? CafeTunisienColors.amber : CafeTunisienColors.gold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  Widget _buildTableMelds() {
    if (tableMelds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee, color: Colors.white.withOpacity(0.08), size: 48),
            const SizedBox(height: 8),
            Text(
              '☕ En attente des combinaisons...',
              style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: tableMelds.map((meld) => _MeldDisplay(meld: meld)).toList(),
      ),
    );
  }
}

// ─── Meld Display ────────────────────────────────────────────

class _MeldDisplay extends StatelessWidget {
  final Meld meld;
  const _MeldDisplay({required this.meld});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: meld.cards.map((card) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: CardWidget(card: card, width: 32, height: 46),
        )).toList(),
      ),
    );
  }
}

// ─── Smoke Particle (chicha ambiance) ────────────────────────

class _SmokeParticle extends StatefulWidget {
  final int delay;
  const _SmokeParticle({required this.delay});

  @override
  State<_SmokeParticle> createState() => _SmokeParticleState();
}

class _SmokeParticleState extends State<_SmokeParticle> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: 6 + widget.delay),
    )..repeat();
    _opacity = Tween<double>(begin: 0.0, end: 0.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _position = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -40),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.translate(
        offset: _position.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(0.15), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
