import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isRegister = false;
  bool _obscurePassword = true;

  late AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
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
      backgroundColor: const Color(0xFF0D0906),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CafeBackground(
            overlayOpacity: 0.78,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (context, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back button
                      _buildAnimated(0, child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/'),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                                border: Border.all(color: CafeTunisienColors.glassBorder),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)],
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: CafeTunisienColors.goldLight, size: 18),
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(height: 20),

                      // Logo
                      _buildAnimated(1, child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [CafeTunisienColors.gold.withOpacity(0.1), Colors.transparent],
                              ),
                              border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.2)),
                            ),
                            child: const Center(child: Text('🃏', style: TextStyle(fontSize: 40))),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isRegister ? 'Inscription' : 'Connexion',
                              key: ValueKey(_isRegister),
                              style: AppTextStyles.titleLarge.copyWith(
                                color: CafeTunisienColors.goldLight,
                                shadows: [Shadow(color: CafeTunisienColors.gold.withOpacity(0.3), blurRadius: 8)],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const GoldDivider(width: 60),
                        ],
                      )),
                      const SizedBox(height: 28),

                      // Name field (register only)
                      if (_isRegister)
                        _buildAnimated(2, child: Column(children: [
                          GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: TextField(
                              controller: _nameCtrl,
                              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Nom d\'affichage',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                                prefixIcon: Icon(Icons.person, color: CafeTunisienColors.gold.withOpacity(0.7)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ])),

                      // Email field
                      _buildAnimated(_isRegister ? 3 : 2, child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Email',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                            prefixIcon: Icon(Icons.email, color: CafeTunisienColors.gold.withOpacity(0.7)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      )),
                      const SizedBox(height: 12),

                      // Password field
                      _buildAnimated(_isRegister ? 4 : 3, child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Mot de passe',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                            prefixIcon: Icon(Icons.lock, color: CafeTunisienColors.gold.withOpacity(0.7)),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white.withOpacity(0.3),
                                size: 20,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      )),
                      const SizedBox(height: 24),

                      // Error
                      if (auth.error != null)
                        _buildAnimated(0, child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              CafeTunisienColors.warmRed.withOpacity(0.15),
                              CafeTunisienColors.warmRed.withOpacity(0.05),
                            ]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CafeTunisienColors.warmRed.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.redAccent.withOpacity(0.7), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(auth.error!, style: AppTextStyles.bodySmall.copyWith(color: Colors.redAccent), textAlign: TextAlign.left),
                              ),
                            ],
                          ),
                        )),

                      // Submit button
                      _buildAnimated(_isRegister ? 5 : 4, child: PremiumButton(
                        label: _isRegister ? 'S\'inscrire' : 'Se connecter',
                        icon: _isRegister ? Icons.person_add : Icons.login,
                        isLoading: auth.isLoading,
                        onTap: auth.isLoading ? null : _submit,
                      )),
                      const SizedBox(height: 16),

                      // Toggle register/login
                      _buildAnimated(_isRegister ? 6 : 5, child: Center(
                        child: TextButton(
                          onPressed: () => setState(() => _isRegister = !_isRegister),
                          child: Text(
                            _isRegister ? 'Déjà un compte ? Se connecter' : 'Pas de compte ? S\'inscrire',
                            style: AppTextStyles.bodySmall.copyWith(color: CafeTunisienColors.goldLight),
                          ),
                        ),
                      )),
                      const SizedBox(height: 8),

                      // Guest
                      _buildAnimated(_isRegister ? 7 : 6, child: Center(
                        child: TextButton(
                          onPressed: () => context.go('/'),
                          child: Text('Continuer en invité', style: AppTextStyles.bodySmall.copyWith(color: Colors.white38)),
                        ),
                      )),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimated(int index, {required Widget child}) {
    final delay = index * 0.08;
    final progress = CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    ).value;

    return Opacity(
      opacity: progress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - progress)),
        child: child,
      ),
    );
  }

  void _submit() {
    HapticFeedback.mediumImpact();
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
