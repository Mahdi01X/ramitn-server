import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

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
    final theme = Theme.of(context);

    ref.listen(authProvider, (prev, next) {
      if (next.isLoggedIn) {
        context.go('/');
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Inscription' : 'Connexion')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text('🃏', textAlign: TextAlign.center, style: TextStyle(fontSize: 60)),
            const SizedBox(height: 24),

            if (_isRegister)
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom d\'affichage',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
            if (_isRegister) const SizedBox(height: 16),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(auth.error!, style: TextStyle(color: theme.colorScheme.error)),
              ),

            ElevatedButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isRegister ? 'S\'inscrire' : 'Se connecter'),
            ),
            const SizedBox(height: 12),

            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister
                  ? 'Déjà un compte ? Se connecter'
                  : 'Pas de compte ? S\'inscrire'),
            ),
            const Divider(height: 40),

            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : _guestLogin,
              icon: const Icon(Icons.person_outline),
              label: const Text('Continuer en tant qu\'invité'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final notifier = ref.read(authProvider.notifier);
    if (_isRegister) {
      notifier.register(_emailCtrl.text, _passCtrl.text, _nameCtrl.text);
    } else {
      notifier.login(_emailCtrl.text, _passCtrl.text);
    }
  }

  void _guestLogin() {
    ref.read(authProvider.notifier).guestLogin();
  }
}

