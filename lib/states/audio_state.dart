import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final audioProvider = ChangeNotifierProvider<AudioState>((_) => AudioState());

class AudioState extends ChangeNotifier {
  bool _isPlaying = false;
  bool _isInitialized = false;
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  late final AudioCache _bgmCache = AudioCache(
    fixedPlayer: _bgmPlayer,
    prefix: 'assets/sounds/',
  );
  late final AudioCache _effectCache = AudioCache(
    fixedPlayer: _effectPlayer,
    prefix: 'assets/sounds/',
  );

  bool get isPlaying => _isPlaying;
  bool get isInitialized => _isInitialized;
  AudioPlayer get audioPlayer => _bgmPlayer;
  AudioCache get audioCache => _bgmCache;

  Future<void> init() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.STOP);
    await _effectPlayer.setReleaseMode(ReleaseMode.STOP);
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> playBGM() async {
    if (!_isInitialized) {
      await init();
    }
    await _bgmCache.loop('jazz.mp3', volume: 0.01);
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pauseBGM() async {
    await _bgmPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stopBGM() async {
    await _bgmPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> playEffect(String fileName) async {
    if (!_isInitialized) {
      await init();
    }
    await _effectCache.play(fileName, volume: 0.1);
  }
}


//class AudioState {
//  late final AudioCache _audioCache = AudioCache(
//    fixedPlayer: AudioPlayer(),
//    prefix: 'assets/sounds/',
//  );
//  AudioPlayer? _audioPlayer;

//  AudioState({
//    required this.fileName,
//    required this.isLoop,
//  }) {
//    () async {
//      await _audioPlayer?.stop();
//      await _audioPlayer?.dispose();

//      if (isLoop) {
//        _audioPlayer = await _audioCache.loop(fileName);
//      } else {
//        _audioPlayer = await _audioCache.play(fileName);
//      }
//    }();
//  }

//  final String fileName;
//  final bool isLoop;

//  Future<void> resume() async => _audioPlayer?.resume();

//  Future<void> pause() async => _audioPlayer?.pause();

//  Future<void> stop() async => _audioPlayer?.stop();

//  Future<void> dispose() async => await _audioPlayer?.dispose();
//}
