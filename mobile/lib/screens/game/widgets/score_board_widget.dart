import 'package:flutter/material.dart';
import '../../../providers/game_provider.dart';
import '../../../core/theme.dart';

class ScoreBoardWidget extends StatelessWidget {
  final GameProviderState gameState;
  const ScoreBoardWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final isOffline = gameState.mode == GameMode.offline;
    final engine = gameState.offlineEngine;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0E06), Color(0xFF0F0A05)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: CafeTunisienColors.gold.withOpacity(0.3),
            ),
          ),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CafeTunisienColors.gold.withOpacity(0.1),
                ),
                child: const Icon(Icons.leaderboard_rounded, color: CafeTunisienColors.goldLight, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Tableau des scores', style: TextStyle(
                color: CafeTunisienColors.goldLight,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              )),
            ],
          ),
          const SizedBox(height: 6),
          Container(width: 80, height: 2, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: const LinearGradient(colors: [Colors.transparent, CafeTunisienColors.gold, Colors.transparent]),
          )),
          const SizedBox(height: 16),

          if (isOffline && engine != null) ...[
            // Column headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  CafeTunisienColors.gold.withOpacity(0.12),
                  CafeTunisienColors.gold.withOpacity(0.05),
                ]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.15)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Joueur', style: TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.w700, fontSize: 13))),
                  Expanded(flex: 1, child: Text('Manche', textAlign: TextAlign.center, style: TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.w700, fontSize: 13))),
                  Expanded(flex: 1, child: Text('Total', textAlign: TextAlign.center, style: TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.w700, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Player rows
            ...engine.state.players.asMap().entries.map((entry) {
              final p = entry.value;
              final isLeading = engine.state.players.every((o) => o.totalScore >= p.totalScore);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  gradient: isLeading
                      ? LinearGradient(colors: [
                          CafeTunisienColors.gold.withOpacity(0.08),
                          Colors.transparent,
                        ])
                      : null,
                  color: isLeading ? null : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLeading
                        ? CafeTunisienColors.gold.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Row(children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLeading
                              ? CafeTunisienColors.gold.withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                        ),
                        child: Center(child: Icon(
                          p.isBot ? Icons.smart_toy : Icons.person,
                          size: 13,
                          color: isLeading ? CafeTunisienColors.goldLight : Colors.white54,
                        )),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(p.name, style: TextStyle(
                          color: isLeading ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight: isLeading ? FontWeight.w600 : FontWeight.normal,
                        )),
                      ),
                      if (isLeading) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      ],
                    ])),
                    Expanded(flex: 1, child: Text(
                      '${p.score}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: p.score == 0 ? const Color(0xFF4CAF50) : Colors.white70,
                        fontSize: 14,
                        fontWeight: p.score == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    )),
                    Expanded(flex: 1, child: Text(
                      '${p.totalScore}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.bold, fontSize: 14),
                    )),
                  ],
                ),
              );
            }),
          ] else if (gameState.onlineState != null)
            ...gameState.onlineState!.players.map((p) => Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(children: [
                Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: CafeTunisienColors.gold.withOpacity(0.12),
                  ),
                  child: Text('${p.totalScore} pts', style: const TextStyle(color: CafeTunisienColors.goldLight, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ]),
            )),

          const SizedBox(height: 16),
          if (isOffline && engine != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, color: CafeTunisienColors.gold.withOpacity(0.5), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Manche ${engine.state.round} / ${engine.state.config.maxRounds}',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
