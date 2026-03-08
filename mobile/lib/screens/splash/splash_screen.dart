import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

/// Beautiful animated splash/intro screen for RamiTN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _cardsCtrl;
  late AnimationController _textCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _cardsAnim;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _shimmer;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final _random = Random();
  final List<_FallingCard> _fallingCards = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    for (int i = 0; i < 20; i++) {
      _fallingCards.add(_FallingCard(
        suit: ['♠', '♥', '♦', '♣'][_random.nextInt(4)],
        rank: ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'][_random.nextInt(13)],
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.6,
        speed: 0.5 + _random.nextDouble() * 0.5,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
      ));
    }

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _bgFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn));

    _cardsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _cardsAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeInOut));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _logoScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.4)));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textSlide = Tween(begin: 40.0, end: 0.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _shimmer = Tween(begin: -1.0, end: 2.0).animate(_shimmerCtrl);

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      await _sfxPlayer.setVolume(0.5);
      await _sfxPlayer.play(AssetSource('yasmina.mp3'));
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) _sfxPlayer.stop();
      });
    } catch (_) {}

    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _cardsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    HapticFeedback.heavyImpact();
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _shimmerCtrl.repeat();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      context.go('/');
    }
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _cardsCtrl.dispose();
    _textCtrl.dispose();
    _shimmerCtrl.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgFade, _cardsAnim, _logoScale, _textOpacity, _shimmer]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Opacity(
                opacity: _bgFade.value,
                child: Image.asset(
                  'assets/1772912871079.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0D3B13)),
                ),
              ),

              // Dark overlay
              Opacity(
                opacity: _bgFade.value * 0.7,
                child: Container(color: Colors.black),
              ),

              // Green tint
              Opacity(
                opacity: _bgFade.value * 0.3,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.3),
                      radius: 1.2,
                      colors: [Color(0x402E7D3A), Color(0x201B5E20), Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Vignette
              Opacity(
                opacity: _bgFade.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      radius: 1.0,
                    ),
                  ),
                ),
              ),

              // Falling cards
              ..._fallingCards.map((fc) {
                final progress = (_cardsAnim.value - fc.delay).clamp(0.0, 1.0) / (1.0 - fc.delay).clamp(0.01, 1.0);
                if (progress <= 0) return const SizedBox.shrink();
                final screenH = MediaQuery.of(context).size.height;
                final screenW = MediaQuery.of(context).size.width;
                final y = -80.0 + (screenH + 160) * progress * fc.speed;
                final x = fc.x * screenW;
                final rotation = fc.rotation + fc.rotationSpeed * progress;
                final opacity = progress < 0.1 ? progress * 10 : (progress > 0.8 ? (1 - progress) * 5 : 1.0);
                final isRed = fc.suit == '♥' || fc.suit == '♦';

                return Positioned(
                  left: x - 20,
                  top: y,
                  child: Opacity(
                    opacity: opacity.clamp(0.0, 0.5),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Container(
                        width: 40,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                        ),
                        child: Center(
                          child: Text(
                            '${fc.rank}\n${fc.suit}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isRed ? Colors.red.shade700 : Colors.black87,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with golden glow
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CafeTunisienColors.gold.withOpacity(0.4 * _logoOpacity.value),
                                blurRadius: 50,
                                spreadRadius: 15,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                            border: Border.all(color: CafeTunisienColors.gold.withOpacity(0.5 * _logoOpacity.value), width: 3),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'unnamed.jpg',
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 160, height: 160,
                                color: const Color(0xFF1B5E20),
                                child: const Center(child: Text('🃏', style: TextStyle(fontSize: 60))),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Title with shimmer
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              begin: Alignment(_shimmer.value - 1, 0),
                              end: Alignment(_shimmer.value, 0),
                              colors: const [
                                Color(0xFFFFD700),
                                Color(0xFFFFF8E1),
                                Color(0xFFFFD700),
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            'RamiTN',
                            style: AppTextStyles.displayLarge.copyWith(
                              color: Colors.white,
                              fontSize: 52,
                              shadows: [
                                Shadow(color: Colors.black54, offset: const Offset(2, 3), blurRadius: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Arabic tagline
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value * 1.2),
                        child: Text('— قهوة و كارطة —', style: AppTextStyles.arabicTagline),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Opacity(
                      opacity: _textOpacity.value * 0.7,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value * 1.4),
                        child: Text(
                          'Le jeu de cartes du café tunisien',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Loading indicator
                    Opacity(
                      opacity: _textOpacity.value * 0.5,
                      child: const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: CafeTunisienColors.goldLight),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom ornament
              Positioned(
                bottom: 30,
                left: 0, right: 0,
                child: Opacity(
                  opacity: _textOpacity.value * 0.4,
                  child: const Center(
                    child: SuitOrnament(size: 18, opacity: 0.3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FallingCard {
  final String suit;
  final String rank;
  final double x;
  final double delay;
  final double speed;
  final double rotation;
  final double rotationSpeed;

  _FallingCard({
    required this.suit,
    required this.rank,
    required this.x,
    required this.delay,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
  });
}

/// Ornamental suit symbols row — duplicated from widgets.dart for splash independence
class SuitOrnament extends StatelessWidget {
  final double size;
  final double opacity;
  const SuitOrnament({super.key, this.size = 14, this.opacity = 0.3});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('♠', style: TextStyle(color: CafeTunisienColors.gold.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.8),
        Text('♥', style: TextStyle(color: CafeTunisienColors.warmRed.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.8),
        Text('♦', style: TextStyle(color: CafeTunisienColors.warmRed.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.8),
        Text('♣', style: TextStyle(color: CafeTunisienColors.gold.withOpacity(opacity), fontSize: size)),
      ],
    );
  }
}
