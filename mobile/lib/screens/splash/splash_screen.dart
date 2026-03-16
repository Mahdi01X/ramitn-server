import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';

/// Cinematic splash/intro screen for RamiTN — studio-quality opening
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
  late AnimationController _glowPulseCtrl;
  late AnimationController _ringCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _cardsAnim;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _shimmer;
  late Animation<double> _glowPulse;
  late Animation<double> _ringRotation;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final _random = Random();
  final List<_FallingCard> _fallingCards = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Create a richer set of falling cards
    for (int i = 0; i < 28; i++) {
      _fallingCards.add(_FallingCard(
        suit: ['♠', '♥', '♦', '♣'][_random.nextInt(4)],
        rank: ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'][_random.nextInt(13)],
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.5,
        speed: 0.4 + _random.nextDouble() * 0.6,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 3,
        scale: 0.7 + _random.nextDouble() * 0.5,
        blur: _random.nextDouble() > 0.6,
      ));
    }

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _bgFade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeIn));

    _cardsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    _cardsAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardsCtrl, curve: Curves.easeInOut));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _logoScale = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.3)));

    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textSlide = Tween(begin: 50.0, end: 0.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _shimmer = Tween(begin: -1.5, end: 2.5).animate(_shimmerCtrl);

    _glowPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowPulse = Tween(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _glowPulseCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _ringRotation = Tween(begin: 0.0, end: 2 * pi).animate(_ringCtrl);

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    try {
      await _sfxPlayer.setVolume(0.5);
      await _sfxPlayer.play(AssetSource('yasmina.mp3'));
      Future.delayed(const Duration(milliseconds: 4000), () {
        if (mounted) _sfxPlayer.stop();
      });
    } catch (_) {}

    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _cardsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    HapticFeedback.heavyImpact();
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _shimmerCtrl.repeat();
    await Future.delayed(const Duration(milliseconds: 2000));
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
    _glowPulseCtrl.dispose();
    _ringCtrl.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgFade, _cardsAnim, _logoScale, _textOpacity, _shimmer, _glowPulse, _ringRotation]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Background image with cinematic fade
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
                opacity: _bgFade.value * 0.75,
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

              // Overhead warm light (like a lamp over a card table)
              Opacity(
                opacity: _bgFade.value * _glowPulse.value * 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 0.7,
                      colors: [
                        CafeTunisienColors.gold.withOpacity(0.12),
                        CafeTunisienColors.gold.withOpacity(0.03),
                        Colors.transparent,
                      ],
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
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      radius: 0.95,
                    ),
                  ),
                ),
              ),

              // Falling cards — with depth (blurred far cards, sharp near cards)
              ..._fallingCards.map((fc) {
                final progress = (_cardsAnim.value - fc.delay).clamp(0.0, 1.0) / (1.0 - fc.delay).clamp(0.01, 1.0);
                if (progress <= 0) return const SizedBox.shrink();
                final screenH = MediaQuery.of(context).size.height;
                final screenW = MediaQuery.of(context).size.width;
                final y = -80.0 + (screenH + 160) * progress * fc.speed;
                final x = fc.x * screenW;
                final rotation = fc.rotation + fc.rotationSpeed * progress;
                final opacity = (progress < 0.1 ? progress * 10 : (progress > 0.8 ? (1 - progress) * 5 : 1.0))
                    .clamp(0.0, fc.blur ? 0.25 : 0.45);
                final isRed = fc.suit == '♥' || fc.suit == '♦';
                final cardW = 40.0 * fc.scale;
                final cardH = 56.0 * fc.scale;

                return Positioned(
                  left: x - cardW / 2,
                  top: y,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Container(
                        width: cardW,
                        height: cardH,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4 * fc.scale),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: fc.blur ? 8 : 4),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${fc.rank}\n${fc.suit}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9 * fc.scale,
                              fontWeight: FontWeight.bold,
                              color: isRed ? const Color(0xFFCC0000) : const Color(0xFF1A1A2E),
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
                    // Logo with rotating gold ring + pulsing glow
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: SizedBox(
                          width: 200,
                          height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow
                              Container(
                                width: 190,
                                height: 190,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CafeTunisienColors.gold.withOpacity(_glowPulse.value * 0.5),
                                      blurRadius: 60,
                                      spreadRadius: 20,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 30,
                                    ),
                                  ],
                                ),
                              ),
                              // Rotating ornamental ring
                              Transform.rotate(
                                angle: _ringRotation.value,
                                child: CustomPaint(
                                  size: const Size(190, 190),
                                  painter: _OrnamentalRingPainter(_logoOpacity.value),
                                ),
                              ),
                              // Logo image
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: CafeTunisienColors.gold.withOpacity(0.6),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 16,
                                    ),
                                  ],
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
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

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
                                Color(0xFFD4A017),
                                Color(0xFFFFF8E1),
                                Color(0xFFFFD700),
                                Color(0xFFFFF8E1),
                                Color(0xFFD4A017),
                              ],
                              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                            ).createShader(bounds);
                          },
                          child: Text(
                            'RamiTN',
                            style: AppTextStyles.displayLarge.copyWith(
                              color: Colors.white,
                              fontSize: 56,
                              letterSpacing: 5,
                              shadows: [
                                Shadow(color: Colors.black87, offset: const Offset(2, 4), blurRadius: 16),
                                Shadow(color: CafeTunisienColors.gold.withOpacity(0.3), offset: const Offset(0, 0), blurRadius: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Arabic tagline
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value * 1.2),
                        child: Text('— قهوة و كارطة —', style: AppTextStyles.arabicTagline.copyWith(
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        )),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Opacity(
                      opacity: _textOpacity.value * 0.6,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value * 1.4),
                        child: Text(
                          'Le jeu de cartes du café tunisien',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white54,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 44),

                    // Premium loading indicator with gold gradient
                    Opacity(
                      opacity: _textOpacity.value * 0.6,
                      child: SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation(CafeTunisienColors.gold.withOpacity(0.7)),
                            minHeight: 2.5,
                          ),
                        ),
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
                  child: Column(
                    children: [
                      _SuitOrnament(size: 18, opacity: 0.35),
                      const SizedBox(height: 10),
                      Text(
                        'v1.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.15),
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
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

/// Paints an ornamental ring with suit symbols
class _OrnamentalRingPainter extends CustomPainter {
  final double opacity;
  _OrnamentalRingPainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Dashed ring
    final paint = Paint()
      ..color = CafeTunisienColors.gold.withOpacity(opacity * 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashCount = 40;
    const dashAngle = 2 * pi / dashCount;
    for (int i = 0; i < dashCount; i++) {
      final start = i * dashAngle;
      final end = start + dashAngle * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        end - start,
        false,
        paint,
      );
    }

    // Small diamond ornaments at 4 positions
    final ornPaint = Paint()
      ..color = CafeTunisienColors.gold.withOpacity(opacity * 0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final ox = center.dx + radius * cos(angle);
      final oy = center.dy + radius * sin(angle);
      final path = Path()
        ..moveTo(ox, oy - 4)
        ..lineTo(ox + 3, oy)
        ..lineTo(ox, oy + 4)
        ..lineTo(ox - 3, oy)
        ..close();
      canvas.drawPath(path, ornPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentalRingPainter old) => old.opacity != opacity;
}

class _FallingCard {
  final String suit;
  final String rank;
  final double x;
  final double delay;
  final double speed;
  final double rotation;
  final double rotationSpeed;
  final double scale;
  final bool blur;

  _FallingCard({
    required this.suit,
    required this.rank,
    required this.x,
    required this.delay,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
    required this.scale,
    required this.blur,
  });
}

/// Ornamental suit symbols row
class _SuitOrnament extends StatelessWidget {
  final double size;
  final double opacity;
  const _SuitOrnament({this.size = 14, this.opacity = 0.3});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('♠', style: TextStyle(color: CafeTunisienColors.gold.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.6),
        Text('♥', style: TextStyle(color: CafeTunisienColors.warmRed.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.6),
        Text('♦', style: TextStyle(color: CafeTunisienColors.warmRed.withOpacity(opacity), fontSize: size)),
        SizedBox(width: size * 0.6),
        Text('♣', style: TextStyle(color: CafeTunisienColors.gold.withOpacity(opacity), fontSize: size)),
      ],
    );
  }
}
