import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.isLoggedIn) context.go('/');
    });

    return Scaffold(
      body: CafeBackground(
        overlayOpacity: 0.78,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
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
                  ],
                ),
                const SizedBox(height: 20),
                const Center(child: Text('🃏', style: TextStyle(fontSize: 60))),
                const SizedBox(height: 16),
                Center(child: Text(_isRegister ? 'Inscription' : 'Connexion', style: AppTextStyles.titleLarge.copyWith(color: CafeTunisienColors.goldLight))),
                const SizedBox(height: 8),
                const Center(child: GoldDivider(width: 60)),
                const SizedBox(height: 24),

                if (_isRegister) ...[
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: TextField(
                      controller: _nameCtrl,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Nom d\'affichage',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        prefixIcon: const Icon(Icons.person, color: CafeTunisienColors.gold),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      prefixIcon: const Icon(Icons.email, color: CafeTunisienColors.gold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Mot de passe',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      prefixIcon: const Icon(Icons.lock, color: CafeTunisienColors.gold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CafeTunisienColors.warmRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CafeTunisienColors.warmRed.withOpacity(0.3)),
                      ),
                      child: Text(auth.error!, style: AppTextStyles.bodySmall.copyWith(color: Colors.redAccent), textAlign: TextAlign.center),
                    ),
                  ),

                PremiumButton(
                  label: _isRegister ? 'S\'inscrire' : 'Se connecter',
                  icon: _isRegister ? Icons.person_add : Icons.login,
                  isLoading: auth.isLoading,
                  onTap: auth.isLoading ? null : _submit,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister ? 'Déjà un compte ? Se connecter' : 'Pas de compte ? S\'inscrire',
                      style: AppTextStyles.bodySmall.copyWith(color: CafeTunisienColors.goldLight),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: Text('Continuer en invité', style: AppTextStyles.bodySmall.copyWith(color: Colors.white38)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_isRegister) {
      ref.read(authProvider.notifier).register(
        _emailCtrl.text.trim(),
        _passCtrl.text,
        _nameCtrl.text.trim(),
      );
    } else {
      ref.read(authProvider.notifier).login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    }
  }
}

