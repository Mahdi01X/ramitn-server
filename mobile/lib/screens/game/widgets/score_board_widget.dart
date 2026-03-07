import 'package:flutter/material.dart';
import '../../../providers/game_provider.dart';

class ScoreBoardWidget extends StatelessWidget {
  final GameProviderState gameState;
  const ScoreBoardWidget({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final isOffline = gameState.mode == GameMode.offline;
    final engine = gameState.offlineEngine;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tableau des scores',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (isOffline && engine != null)
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFE0E0E0)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Joueur', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Manche', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Total', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                ...engine.state.players.map((p) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(p.isBot ? Icons.smart_toy : Icons.person, size: 16),
                          const SizedBox(width: 4),
                          Text(p.name),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${p.score}', textAlign: TextAlign.center),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '${p.totalScore}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )),
              ],
            )
          else if (gameState.onlineState != null)
            ...gameState.onlineState!.players.map((p) => ListTile(
              leading: CircleAvatar(child: Text('${p.totalScore}')),
              title: Text(p.name),
            )),

          const SizedBox(height: 16),
          if (isOffline && engine != null)
            Text(
              'Manche ${engine.state.round} / ${engine.state.config.maxRounds}',
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

