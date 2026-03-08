import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  int _numPlayers = 2;

  @override
  void initState() {
    super.initState();
    ref.read(gameProvider.notifier).connectOnline();
  }

  @override
  Widget build(BuildContext context) {
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/'),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                          border: Border.all(color: CafeTunisienColors.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: CafeTunisienColors.goldLight, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('Créer une partie', style: AppTextStyles.titleLarge.copyWith(color: CafeTunisienColors.goldLight)),
                  ],
                ),
                const SizedBox(height: 16),
                const GoldDivider(width: 80),
                const SizedBox(height: 32),

                Text('Nombre de joueurs', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [2, 3, 4].map((n) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _numPlayers = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _numPlayers == n ? CafeTunisienColors.gold : Colors.white.withOpacity(0.06),
                          border: Border.all(color: _numPlayers == n ? CafeTunisienColors.goldLight : CafeTunisienColors.glassBorder, width: _numPlayers == n ? 2 : 1),
                          boxShadow: _numPlayers == n ? [BoxShadow(color: CafeTunisienColors.gold.withOpacity(0.3), blurRadius: 12)] : null,
                        ),
                        child: Center(child: Text('$n', style: AppTextStyles.titleMedium.copyWith(color: _numPlayers == n ? Colors.white : Colors.white54, fontWeight: FontWeight.w700))),
                      ),
                    ),
                  )).toList(),
                ),

                const Spacer(),

                PremiumButton(
                  label: 'Créer la room',
                  icon: Icons.add_rounded,
                  onTap: () {
                    ref.read(gameProvider.notifier).createRoom(numPlayers: _numPlayers);
                    context.go('/lobby');
                  },
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}
