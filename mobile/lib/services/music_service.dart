import 'package:audioplayers/audioplayers.dart';

/// Singleton service for background music during the game.
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  double _volume = 0.3; // default 30%

  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  /// Start looping yasmina.mp3 as background music.
  Future<void> play() async {
    if (_isPlaying) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.play(AssetSource('yasmina.mp3'));
      _isPlaying = true;
    } catch (_) {
      // Silently fail — music is optional
    }
  }

  /// Stop background music.
  Future<void> stop() async {
    if (!_isPlaying) return;
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (_) {}
  }

  /// Pause background music.
  Future<void> pause() async {
    if (!_isPlaying) return;
    try {
      await _player.pause();
    } catch (_) {}
  }

  /// Resume background music.
  Future<void> resume() async {
    if (!_isPlaying) return;
    try {
      await _player.resume();
    } catch (_) {}
  }

  /// Set volume (0.0 to 1.0).
  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _player.setVolume(_volume);
    } catch (_) {}
  }

  /// Dispose the player.
  Future<void> dispose() async {
    await _player.dispose();
    _isPlaying = false;
  }
}

