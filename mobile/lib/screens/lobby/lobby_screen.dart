import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/room_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    // Navigate to game when started
    ref.listen(roomProvider, (prev, next) {
      if (next.gameStarted && !(prev?.gameStarted ?? false)) {
        context.go('/game');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(gameProvider.notifier).disconnectOnline();
            context.go('/');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Room code
            if (room.roomCode != null) ...[
              Text('Code de la room', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: room.roomCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copié !')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        room.roomCode!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.copy, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Players list
            Text('Joueurs', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: room.players.length,
                itemBuilder: (_, i) {
                  final p = room.players[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p.ready ? Colors.green : Colors.grey,
                        child: Icon(
                          p.ready ? Icons.check : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(p.name),
                      trailing: p.ready
                          ? const Chip(label: Text('Prêt'))
                          : const Chip(label: Text('En attente')),
                    ),
                  );
                },
              ),
            ),

            // Error
            if (room.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(room.error!, style: TextStyle(color: theme.colorScheme.error)),
              ),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ref.read(gameProvider.notifier).setReady(),
                    child: const Text('Prêt !'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: room.players.every((p) => p.ready) && room.players.length >= 2
                        ? () => ref.read(gameProvider.notifier).startOnlineGame()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Démarrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

