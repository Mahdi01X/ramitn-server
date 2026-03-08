import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ref.read(gameProvider.notifier).connectOnline();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CafeBackground(
        overlayOpacity: 0.78,
        child: SafeArea(
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
                    Text('Rejoindre', style: AppTextStyles.titleLarge.copyWith(color: CafeTunisienColors.goldLight)),
                  ],
                ),
                const SizedBox(height: 16),
                const GoldDivider(width: 80),
                const SizedBox(height: 40),

                const Center(child: Text('🔑', style: TextStyle(fontSize: 50))),
                const SizedBox(height: 16),
                Center(child: Text('Entre le code de la room', style: AppTextStyles.bodyMedium)),
                const SizedBox(height: 24),

                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: TextField(
                    controller: _codeCtrl,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: AppTextStyles.displayMedium.copyWith(fontSize: 34, letterSpacing: 10, fontFamily: 'monospace', color: CafeTunisienColors.goldLight),
                    decoration: InputDecoration(
                      border: InputBorder.none, counterText: '',
                      hintText: 'ABC12',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.12), letterSpacing: 10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                const Spacer(),

                PremiumButton(
                  label: 'Rejoindre',
                  icon: Icons.login_rounded,
                  onTap: () {
                    if (_codeCtrl.text.length >= 4) {
                      ref.read(gameProvider.notifier).joinRoom(_codeCtrl.text);
                      context.go('/lobby');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
