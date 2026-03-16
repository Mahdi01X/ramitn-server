import 'dart:math';
import 'package:flutter/material.dart';
import '../../../providers/game_provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';

/// Premium scoreboard bottom sheet with rich wood/gold aesthetic,
/// animated entries, and trophy indicators.
class ScoreBoardWidget extends StatelessWidget {
  final GameProviderState gameState;
  const ScoreBoardWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final isOffline = gameState.mode == GameMode.offline;
    final engine = gameState.offlineEngine;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F1208), Color(0xFF150D06), Color(0xFF0A0603)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: CafeTunisienColors.gold.withOpacity(0.4), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: const Offset(0, -10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 44, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  CafeTunisienColors.gold.withOpacity(0.2),
                  CafeTunisienColors.gold.withOpacity(0.5),
                  CafeTunisienColors.gold.withOpacity(0.2),
                ],
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [CafeTunisienColors.gold.withOpacity(0.15), Colors.transparent],
                  ),
                  border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.2)),
                ),
                child: const Icon(Icons.leaderboard_rounded, color: CafeTunisienColors.goldLight, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Tableau des scores', style: TextStyle(
                color: CafeTunisienColors.goldLight,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                shadows: [Shadow(color: CafeTunisienColors.gold.withOpacity(0.3), blurRadius: 8)],
              )),
            ],
          ),
          const SizedBox(height: 10),
          const GoldDivider(width: 100),
          const SizedBox(height: 18),

          if (isOffline && engine != null) ...[
            // Column headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  CafeTunisienColors.gold.withOpacity(0.12),
                  CafeTunisienColors.gold.withOpacity(0.04),
                ]),
                borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 8),

            // Player rows
            ...engine.state.players.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              final isLeading = engine.state.players.every((o) => o.totalScore >= p.totalScore);
              return _PlayerScoreRow(
                index: idx,
                name: p.name,
                isBot: p.isBot,
                roundScore: p.score,
                totalScore: p.totalScore,
                isLeading: isLeading,
              );
            }),
          ] else if (gameState.onlineState != null)
            ...gameState.onlineState!.players.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return _PlayerScoreRow(
                index: idx,
                name: p.name,
                isBot: false,
                roundScore: null,
                totalScore: p.totalScore,
                isLeading: gameState.onlineState!.players.every((o) => o.totalScore >= p.totalScore),
              );
            }),

          const SizedBox(height: 18),
          if (isOffline && engine != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_rounded, color: CafeTunisienColors.gold.withOpacity(0.4), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Manche ${engine.state.round} / ${engine.state.config.maxRounds}',
                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Premium player score row with rank indicator and animations
class _PlayerScoreRow extends StatelessWidget {
  final int index;
  final String name;
  final bool isBot;
  final int? roundScore;
  final int totalScore;
  final bool isLeading;

  const _PlayerScoreRow({
    required this.index,
    required this.name,
    required this.isBot,
    this.roundScore,
    required this.totalScore,
    required this.isLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: isLeading
            ? LinearGradient(
                colors: [
                  CafeTunisienColors.gold.withOpacity(0.1),
                  CafeTunisienColors.gold.withOpacity(0.03),
                ],
              )
            : null,
        color: isLeading ? null : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLeading
              ? CafeTunisienColors.gold.withOpacity(0.25)
              : Colors.white.withOpacity(0.05),
        ),
        boxShadow: isLeading ? [
          BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.08), blurRadius: 10, spreadRadius: 1),
        ] : null,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Row(children: [
            // Avatar circle
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isLeading
                    ? LinearGradient(colors: [
                        CafeTunisienColors.gold.withOpacity(0.25),
                        CafeTunisienColors.gold.withOpacity(0.1),
                      ])
                    : null,
                color: isLeading ? null : Colors.white.withOpacity(0.05),
                border: Border.all(
                  color: isLeading ? CafeTunisienColors.gold.withOpacity(0.3) : Colors.white.withOpacity(0.08),
                  width: 0.5,
                ),
              ),
              child: Center(child: Icon(
                isBot ? Icons.smart_toy : Icons.person,
                size: 14,
                color: isLeading ? CafeTunisienColors.goldLight : Colors.white54,
              )),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(name, style: TextStyle(
                color: isLeading ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isLeading ? FontWeight.w600 : FontWeight.normal,
              )),
            ),
            if (isLeading) ...[
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
            ],
          ])),
          if (roundScore != null)
            Expanded(flex: 1, child: Text(
              '$roundScore',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: roundScore == 0 ? const Color(0xFF4CAF50) : Colors.white70,
                fontSize: 14,
                fontWeight: roundScore == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            )),
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: isLeading ? BoxDecoration(
              gradient: LinearGradient(colors: [
                CafeTunisienColors.gold.withOpacity(0.15),
                Colors.transparent,
              ]),
              borderRadius: BorderRadius.circular(6),
            ) : null,
            child: Text(
              '$totalScore',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLeading ? CafeTunisienColors.goldLight : CafeTunisienColors.goldLight.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
