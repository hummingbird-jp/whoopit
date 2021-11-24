import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  late final AudioCache _audioCache = AudioCache(
    fixedPlayer: AudioPlayer(),
    prefix: 'assets/sounds/',
  );
  AudioPlayer? _audioPlayer;

  SoundPlayer({
    required this.fileName,
    required this.isLoop,
  }) {
    () async {
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();

      if (isLoop) {
        _audioPlayer = await _audioCache.loop(fileName);
      } else {
        _audioPlayer = await _audioCache.play(fileName);
      }
    }();
  }

  final String fileName;
  final bool isLoop;

  Future<void> resume() async => _audioPlayer?.resume();

  Future<void> pause() async => _audioPlayer?.pause();

  Future<void> stop() async => _audioPlayer?.stop();

  Future<void> dispose() async => await _audioPlayer?.dispose();
}
