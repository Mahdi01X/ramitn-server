import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static void _showServerConfig(BuildContext context) {
    final ctrl = TextEditingController(text: AppConstants.serverUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Serveur', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'https://...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              await AppConstants.setServerUrl(ctrl.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Serveur mis à jour'), backgroundColor: Color(0xFF4CAF50)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: CafeTunisienColors.gold),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3E2723), // Dark coffee brown top
              Color(0xFF1A4D2E), // Table green
              Color(0xFF143D24), // Dark green bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.asset(
                      'unnamed.jpg',
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Text('🃏', style: TextStyle(fontSize: 80)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'RamiTN',
                    style: TextStyle(
                      color: CafeTunisienColors.goldLight,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '— قهوة و كارطة —',
                    style: TextStyle(
                      color: CafeTunisienColors.gold.withOpacity(0.7),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le jeu de cartes du café',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 48),

                  // Greeting
                  if (auth.isLoggedIn)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: CafeTunisienColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Marhba bik, ${auth.displayName ?? "Joueur"} ! 👋',
                          style: const TextStyle(color: CafeTunisienColors.goldLight, fontSize: 15),
                        ),
                      ),
                    ),

                  // Main buttons
                  _MenuButton(
                    icon: Icons.phone_android,
                    label: 'Jouer Hors-ligne',
                    subtitle: 'Hot-seat ou contre des bots',
                    onTap: () => context.push('/offline-setup'),
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    icon: Icons.wifi,
                    label: 'Jouer En ligne',
                    subtitle: 'Parties privées — pas besoin de compte !',
                    onTap: () => context.push('/quick-online'),
                  ),
                  const SizedBox(height: 12),
                  _MenuButton(
                    icon: Icons.menu_book,
                    label: 'Règles du jeu',
                    subtitle: 'Apprendre à jouer',
                    onTap: () => context.push('/rules'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOnlineOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mode En Ligne',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Créer une partie'),
              subtitle: const Text('Invite tes amis avec un code'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create-room');
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Rejoindre une partie'),
              subtitle: const Text('Entre le code de la room'),
              onTap: () {
                Navigator.pop(context);
                context.push('/join-room');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Matchmaking'),
              subtitle: const Text('Trouver des adversaires'),
              onTap: () {
                Navigator.pop(context);
                ref.read(gameProvider.notifier).connectOnline();
                ref.read(gameProvider.notifier).joinMatchmaking(2);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: CafeTunisienColors.woodBrown.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 34, color: CafeTunisienColors.goldLight),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: CafeTunisienColors.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
