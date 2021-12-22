import 'dart:developer';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioProvider = ChangeNotifierProvider<AudioState>((_) => AudioState());

enum AudioStateInitStatus {
  yet,
  inProgress,
  done,
}

class AudioState extends ChangeNotifier {
  bool _isPlaying = false;
  AudioStateInitStatus _initStatus = AudioStateInitStatus.yet;
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _beerPlayer = AudioPlayer();
  final AudioPlayer _boomPlayer = AudioPlayer();

  bool get isPlaying => _isPlaying;
  AudioStateInitStatus get isInitialized => _initStatus;
  AudioPlayer get bgmPlayer => _bgmPlayer;
  AudioPlayer get beerPlayer => _beerPlayer;
  AudioPlayer get boomPlayer => _boomPlayer;

  Future<void> init() async {
    log('Initializing AudioState...');

    final AudioSession session = await AudioSession.instance;
    session.configure(
      const AudioSessionConfiguration.music(),
    );

    _bgmPlayer.setAsset('assets/sounds/jazz.mp3');
    _beerPlayer.setAsset('assets/sounds/soda.wav');
    _boomPlayer.setAsset('assets/sounds/boom.wav');

    _bgmPlayer.setLoopMode(LoopMode.all);
    _bgmPlayer.setVolume(0.2);

    _initStatus = AudioStateInitStatus.done;
    notifyListeners();

    log('Done');
  }

  Future<void> playBGM() async {
    if (_initStatus == AudioStateInitStatus.yet) {
      await init();
    }

    _bgmPlayer.play();

    _isPlaying = true;
    notifyListeners();
  }

  Future<void> pauseBGM() async {
    await _bgmPlayer.pause();

    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stopBGM() async {
    // audioPlayer.stop() is deprecated after 0.6.x
    // https://pub.dev/packages/just_audio#migrating-from-05x-to-06x
    await _bgmPlayer.pause();
    await _bgmPlayer.seek(Duration.zero);

    _isPlaying = false;
    notifyListeners();
  }

  Future<void> playBeer() async {
    log('playBeer()');

    if (_initStatus == AudioStateInitStatus.yet) {
      await init();
    }
    await _beerPlayer.play();
  }
}
