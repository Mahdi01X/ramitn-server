import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sound effects service for card game actions.
/// Uses haptic feedback as fallback when audio isn't available.
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;

  /// Card tap / select
  Future<void> cardTap() async {
    HapticFeedback.selectionClick();
  }

  /// Card draw from deck
  Future<void> cardDraw() async {
    HapticFeedback.lightImpact();
  }

  /// Card discard (throw on table)
  Future<void> cardDiscard() async {
    HapticFeedback.mediumImpact();
  }

  /// Meld placed on table
  Future<void> meldPlace() async {
    HapticFeedback.heavyImpact();
  }

  /// Opening confirmed — big moment
  Future<void> openingConfirm() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }

  /// Round end
  Future<void> roundEnd() async {
    HapticFeedback.heavyImpact();
  }

  /// Turn notification (it's your turn)
  Future<void> yourTurn() async {
    HapticFeedback.mediumImpact();
  }

  /// Error / invalid action
  Future<void> error() async {
    HapticFeedback.heavyImpact();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}


