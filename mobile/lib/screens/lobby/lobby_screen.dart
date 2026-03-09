import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/room_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomProvider);

    ref.listen(roomProvider, (prev, next) {
      if (next.gameStarted && !(prev?.gameStarted ?? false)) {
        context.go('/game');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0906),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CafeBackground(
            overlayOpacity: 0.78,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ref.read(gameProvider.notifier).disconnectOnline();
                        context.go('/');
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(color: CafeTunisienColors.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: CafeTunisienColors.goldLight, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('Lobby', style: AppTextStyles.titleLarge.copyWith(color: CafeTunisienColors.goldLight)),
                  ],
                ),
                const SizedBox(height: 12),
                const GoldDivider(width: 80),
                const SizedBox(height: 20),

                // Room code
                if (room.roomCode != null) ...[
                  Text('Code de la room', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: room.roomCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Code copié !'), backgroundColor: Color(0xFF4CAF50)),
                      );
                    },
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      borderColor: CafeTunisienColors.gold.withOpacity(0.4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(room.roomCode!, style: AppTextStyles.displayMedium.copyWith(fontSize: 28, letterSpacing: 6, fontFamily: 'monospace')),
                          const SizedBox(width: 12),
                          const Icon(Icons.copy_rounded, size: 20, color: CafeTunisienColors.gold),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Players
                Text('Joueurs', style: AppTextStyles.labelGold),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: room.players.length,
                    itemBuilder: (_, i) {
                      final RoomPlayerInfo p = room.players[i] as RoomPlayerInfo;
                      final isHost = i == 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.ready ? const Color(0xFF4CAF50).withOpacity(0.2) : CafeTunisienColors.gold.withOpacity(0.15),
                                  border: isHost ? Border.all(color: CafeTunisienColors.amber.withOpacity(0.6), width: 1.5) : null,
                                ),
                                child: Icon(
                                  isHost ? Icons.star_rounded : (p.ready ? Icons.check : Icons.person),
                                  color: isHost ? CafeTunisienColors.amber : (p.ready ? const Color(0xFF4CAF50) : CafeTunisienColors.goldLight),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(p.name, style: AppTextStyles.bodyLarge)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isHost ? CafeTunisienColors.amber : p.ready ? const Color(0xFF4CAF50) : Colors.white10).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isHost ? 'Hôte' : (p.ready ? 'Prêt ✓' : 'En attente'),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isHost ? CafeTunisienColors.amber : (p.ready ? const Color(0xFF4CAF50) : Colors.white38),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (room.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(room.error!, style: AppTextStyles.bodySmall.copyWith(color: CafeTunisienColors.warmRed)),
                  ),

                // Buttons — role-based
                Builder(builder: (context) {
                  final socket = ref.read(socketServiceProvider);
                  final myId = socket.playerId;
                  final List<RoomPlayerInfo> typedPlayers = room.players.map<RoomPlayerInfo>((p) => p as RoomPlayerInfo).toList();
                  final isHost = typedPlayers.isNotEmpty && typedPlayers.first.id == myId;
                  final myPlayerMatches = typedPlayers.where((RoomPlayerInfo p) => p.id == myId);
                  final myPlayer = myPlayerMatches.isNotEmpty ? myPlayerMatches.first : null;
                  final iAmReady = myPlayer?.ready ?? false;
                  final allReady = typedPlayers.every((RoomPlayerInfo p) => p.ready);
                  final canStart = isHost && typedPlayers.length >= 2 && allReady;

                  if (isHost) {
                    // Host: only show Start button
                    return PremiumButton(
                      label: canStart ? '🎮 Lancer la partie' : 'En attente des joueurs...',
                      icon: Icons.play_arrow_rounded,
                      onTap: canStart ? () => ref.read(gameProvider.notifier).startOnlineGame() : null,
                    );
                  } else {
                    // Non-host: only show Ready button
                    return Column(
                      children: [
                        PremiumButton(
                          label: iAmReady ? 'Prêt ✓' : 'Prêt !',
                          icon: iAmReady ? Icons.check_circle : Icons.thumb_up,
                          isSecondary: iAmReady,
                          onTap: iAmReady ? null : () => ref.read(gameProvider.notifier).setReady(),
                        ),
                        if (iAmReady) ...[
                          const SizedBox(height: 8),
                          Text('En attente du lancement par l\'hôte...', style: AppTextStyles.bodySmall.copyWith(color: Colors.white30)),
                        ],
                      ],
                    );
                  }
                }),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}
