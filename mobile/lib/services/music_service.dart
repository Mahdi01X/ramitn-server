import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';

/// Audio source mode for the game
enum AudioMode { off, localMusic, radio }

/// Tunisian radio station definition
class RadioStation {
  final String name;
  final String url;
  final String emoji;
  final String? description;
  final int bitrate;

  const RadioStation({
    required this.name,
    required this.url,
    required this.emoji,
    this.description,
    this.bitrate = 128,
  });
}

/// Hardcoded fallback stations (verified working URLs — tested 2026-03-09)
const List<RadioStation> _fallbackRadios = [
  RadioStation(
    name: 'Mosaïque FM',
    url: 'https://radio.mosaiquefm.net/mosalive',
    emoji: '📻',
    description: 'Hits & Infos — La #1 en Tunisie',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Mosaïque FM Tounsi',
    url: 'https://radio.mosaiquefm.net/mosatounsi',
    emoji: '🇹🇳',
    description: '100% Musique tunisienne',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Mosaïque FM Tarab',
    url: 'https://radio.mosaiquefm.net/mosatarab',
    emoji: '🎻',
    description: 'Tarab & classiques arabes',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Mosaïque FM Gold',
    url: 'https://radio.mosaiquefm.net/mosagold',
    emoji: '✨',
    description: 'Les classiques dorés',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Jawhara FM',
    url: 'https://streaming2.toutech.net/jawharafm',
    emoji: '💎',
    description: 'La perle de la radio',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Diwan FM',
    url: 'https://streaming.diwanfm.net/stream',
    emoji: '🎵',
    description: 'Musique & Culture',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Express FM',
    url: 'https://expressfm.ice.infomaniak.ch/expressfm-64.mp3',
    emoji: '⚡',
    description: 'Info & Business',
    bitrate: 64,
  ),
  RadioStation(
    name: 'Sabra FM',
    url: 'https://manager5.streamradio.fr:1905/stream',
    emoji: '🌴',
    description: 'Du Sud tunisien',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Radio Nationale',
    url: 'http://rtstream.tanitweb.com/nationale',
    emoji: '🇹🇳',
    description: 'Radio nationale tunisienne',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Radio Jeunes',
    url: 'http://rtstream.tanitweb.com/jeunes',
    emoji: '🎧',
    description: 'Pour les jeunes tunisiens',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Radio Culturelle',
    url: 'http://rtstream.tanitweb.com/culturelle',
    emoji: '📚',
    description: 'Culture & Patrimoine',
    bitrate: 128,
  ),
  RadioStation(
    name: 'RTCI',
    url: 'http://rtstream.tanitweb.com/rtci',
    emoji: '🌍',
    description: 'Radio Tunisie Chaîne Inter',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Zitouna FM',
    url: 'https://radio.radiotunisienne.tn/radiozaitouna',
    emoji: '🕌',
    description: 'Radio religieuse',
    bitrate: 128,
  ),
  RadioStation(
    name: 'KnOOz FM',
    url: 'http://streaming.knoozfm.net:8000/knoozfm',
    emoji: '🎶',
    description: 'Divertissement & Musique',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Ambiance FM',
    url: 'https://stream.zeno.fm/0rehsamc9xxtv',
    emoji: '🎉',
    description: 'Bonne ambiance tunisienne',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Radio Misk',
    url: 'https://live.misk.art/stream',
    emoji: '🌸',
    description: 'Radio Misk',
    bitrate: 128,
  ),
  RadioStation(
    name: 'Radio Tunisia Med',
    url: 'https://azuracast.conceptradio.fr:8000/radio.mp3',
    emoji: '🌊',
    description: 'Méditerranée tunisienne',
    bitrate: 128,
  ),
  RadioStation(
    name: 'AlHayet FM',
    url: 'https://manager8.streamradio.fr:2885/stream',
    emoji: '💚',
    description: 'Radio AlHayet',
    bitrate: 128,
  ),
];

/// Emoji map for known station names
const _emojiMap = <String, String>{
  'mosaique': '📻',
  'jawhara': '💎',
  'shems': '☀️',
  'express': '⚡',
  'ifm': '🎶',
  'diwan': '🎵',
  'zitouna': '🕌',
  'sabra': '🌴',
  'cap fm': '🌊',
  'radio nat': '🇹🇳',
  'rtci': '🇹🇳',
  'oasis': '🏜️',
  'oxygene': '💨',
  'tawasol': '📡',
  'radio med': '🌍',
  'pilote': '✈️',
  'culturelle': '📚',
  'jeunes': '🎧',
};

String _emojiFor(String name) {
  final lower = name.toLowerCase();
  for (final entry in _emojiMap.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return '📻';
}

/// Cached radio stations fetched from API
List<RadioStation>? _cachedRadios;
bool _isFetching = false;

/// Fetch Tunisian radio stations.
/// Returns hardcoded verified list immediately, then enriches with API results.
Future<List<RadioStation>> fetchTunisianRadios() async {
  // Return cache if already enriched
  if (_cachedRadios != null) return _cachedRadios!;

  // Start with verified fallback list (always works)
  final stations = List<RadioStation>.from(_fallbackRadios);

  // Try to fetch more from API in background (non-blocking)
  if (!_isFetching) {
    _isFetching = true;
    _fetchFromAPI().then((apiStations) {
      if (apiStations.isNotEmpty) {
        // Merge: keep fallbacks first, add new ones from API
        final existingUrls = stations.map((s) => s.url).toSet();
        for (final s in apiStations) {
          if (!existingUrls.contains(s.url)) {
            stations.add(s);
            existingUrls.add(s.url);
          }
        }
        _cachedRadios = stations;
      }
      _isFetching = false;
    }).catchError((_) {
      _isFetching = false;
    });
  }

  return stations;
}

/// Internal: fetch from radio-browser.info API
Future<List<RadioStation>> _fetchFromAPI() async {
  try {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 6);
    dio.options.receiveTimeout = const Duration(seconds: 6);
    dio.options.headers = {'User-Agent': 'RamiTN/1.0'};

    final response = await dio.get(
      'https://de1.api.radio-browser.info/json/stations/bycountry/tunisia',
      queryParameters: {
        'limit': 25,
        'order': 'clickcount',
        'reverse': 'true',
        'hidebroken': 'true',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data is List ? response.data : [];
      final stations = <RadioStation>[];
      final seenNames = <String>{};

      for (final item in data) {
        final name = (item['name'] ?? '').toString().trim();
        final url = (item['url_resolved'] ?? item['url'] ?? '').toString().trim();
        final codec = (item['codec'] ?? '').toString().toLowerCase();
        final bitrate = (item['bitrate'] ?? 0) as int;

        if (name.isEmpty || url.isEmpty) continue;
        final normName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (seenNames.contains(normName)) continue;
        seenNames.add(normName);

        // Skip non-audio and religious Quran streams (keep music radios)
        if (url.contains('qurango.net')) continue;
        if (codec.isNotEmpty && !['mp3', 'aac', 'ogg', 'opus', 'wma', 'flac'].contains(codec)) continue;

        stations.add(RadioStation(
          name: name,
          url: url,
          emoji: _emojiFor(name),
          description: '${bitrate > 0 ? '${bitrate}kbps' : 'Live'} · ${codec.isEmpty ? 'MP3' : codec.toUpperCase()}',
          bitrate: bitrate,
        ));
      }
      return stations;
    }
  } catch (e) {
    print('📻 Radio API error: $e');
  }
  return [];
}

/// Singleton service for background audio during the game.
/// Supports local music (yasmina.mp3), live Tunisian radio streams, and off.
class MusicService {
  MusicService._();
  static final MusicService instance = MusicService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  double _volume = 0.5;
  AudioMode _mode = AudioMode.localMusic;
  RadioStation? _currentStation;
  String? lastError;
  bool isLoading = false;

  bool get isPlaying => _isPlaying;
  double get volume => _volume;
  AudioMode get mode => _mode;
  RadioStation? get currentStation => _currentStation;

  /// Start playing based on current mode.
  Future<void> play() async {
    if (_mode == AudioMode.off) return;
    if (_isPlaying) return;
    lastError = null;

    try {
      await _player.setVolume(_volume);

      if (_mode == AudioMode.localMusic) {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource('yasmina.mp3'));
        _isPlaying = true;
      } else if (_mode == AudioMode.radio && _currentStation != null) {
        isLoading = true;
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.play(UrlSource(_currentStation!.url));
        _isPlaying = true;
        isLoading = false;
      }
    } catch (e) {
      lastError = e.toString();
      _isPlaying = false;
      isLoading = false;
      print('🔇 Audio error: $e');
    }
  }

  /// Stop all audio.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
    isLoading = false;
  }

  /// Pause audio.
  Future<void> pause() async {
    if (!_isPlaying) return;
    try {
      await _player.pause();
    } catch (_) {}
  }

  /// Resume audio.
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

  /// Switch to local music (yasmina.mp3)
  Future<void> switchToLocalMusic() async {
    await stop();
    _mode = AudioMode.localMusic;
    _currentStation = null;
    await play();
  }

  /// Switch to a live radio station
  Future<void> switchToRadio(RadioStation station) async {
    await stop();
    _mode = AudioMode.radio;
    _currentStation = station;
    await play();
  }

  /// Switch off all audio
  Future<void> switchOff() async {
    await stop();
    _mode = AudioMode.off;
    _currentStation = null;
  }

  /// Get a display label for the current audio
  String get currentLabel {
    switch (_mode) {
      case AudioMode.off:
        return 'Audio off';
      case AudioMode.localMusic:
        return '🎵 Yasmina';
      case AudioMode.radio:
        if (isLoading) return '⏳ Chargement...';
        return '${_currentStation?.emoji ?? '📻'} ${_currentStation?.name ?? 'Radio'}';
    }
  }

  /// Dispose the player.
  Future<void> dispose() async {
    await _player.dispose();
    _isPlaying = false;
  }
}

