import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sound effects service for card game actions.
/// Uses layered haptic feedback patterns for a tactile, premium card game feel.
/// Each action has a distinct haptic "signature" so players can feel the difference.
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;

  /// Card tap / select — crisp light tap
  Future<void> cardTap() async {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Card pick up (start drag) — satisfying grab feel
  Future<void> cardPickUp() async {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Card slide (reorder in hand) — subtle slide feedback
  Future<void> cardSlide() async {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Card draw from deck — crisp flick
  Future<void> cardDraw() async {
    if (!enabled) return;
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    HapticFeedback.selectionClick();
  }

  /// Card discard (throw on table) — satisfying thud
  Future<void> cardDiscard() async {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 40));
    HapticFeedback.lightImpact();
  }

  /// Meld placed on table — weighty slam
  Future<void> meldPlace() async {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
  }

  /// Opening confirmed — dramatic double slam (big moment!)
  Future<void> openingConfirm() async {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    HapticFeedback.mediumImpact();
  }

  /// Layoff — card snaps into place
  Future<void> layoff() async {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.selectionClick();
  }

  /// Joker recovered — exciting moment!
  Future<void> jokerRecovered() async {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
  }

  /// Round win — celebration pattern
  Future<void> roundWin() async {
    if (!enabled) return;
    for (int i = 0; i < 3; i++) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    HapticFeedback.heavyImpact();
  }

  /// Round lose — heavy thud
  Future<void> roundLose() async {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();
  }

  /// Round end
  Future<void> roundEnd() async {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Turn notification (it's your turn) — attention pulse
  Future<void> yourTurn() async {
    if (!enabled) return;
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.lightImpact();
  }

  /// Timer warning (low time)
  Future<void> timerWarning() async {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Error / invalid action — sharp buzz
  Future<void> error() async {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    HapticFeedback.heavyImpact();
  }

  /// Bot action — subtle notification that bot did something
  Future<void> botAction() async {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}


