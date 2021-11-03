import 'dart:async';
import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shake/shake.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';

late String token;
late String channelName;

class RoomPage extends StatefulWidget {
  const RoomPage({Key? key}) : super(key: key);

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final String appId = '8d98fb1cbd094508bff710b6a2d199ef';
  final RoundedLoadingButtonController _muteButtonController =
      RoundedLoadingButtonController();
  final DocumentReference _roomRef =
      FirebaseFirestore.instance.collection('rooms').doc(channelName);
  final String _account = FirebaseAuth.instance.currentUser!.uid;
  final String? _myName = FirebaseAuth.instance.currentUser!.displayName;

  late RtcEngine _rtcEngine;
  late ShakeDetector _shakeDetector;

  bool _joined = false;
  bool get joined => _joined;
  int _remoteUid = 0;
  bool _muted = false;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _shakeDetector = ShakeDetector.autoStart(onPhoneShake: _onShake);
  }

  Future<void> _onShake() async {
    log('_shakeDetector.count: ${_shakeDetector.mShakeCount}');

    if (_isShaking == true) {
      return;
    } else if (_shakeDetector.mShakeCount == 3) {
      setState(() {
        _isShaking = true;
      });

      // Temporary remove myself from the list
      await _roomRef.update({
        'participants': FieldValue.arrayRemove(
          <Map>[
            <String, dynamic>{
              'displayName': _myName,
              'uid': _account,
              'isShaking': false,
            }
          ],
        ),
      });

      // Add myself to the list again with 'isShaking' set to true
      await _roomRef.update({
        'participants': FieldValue.arrayUnion(
          <Map>[
            <String, dynamic>{
              'displayName': _myName,
              'uid': _account,
              'isShaking': true,
            }
          ],
        ),
      });

      Vibration.vibrate();
    }

    Future.delayed(const Duration(milliseconds: 8000), () async {
      setState(() {
        _isShaking = false;
      });

      // Temporary remove myself from the list
      await _roomRef.update({
        'participants': FieldValue.arrayRemove(
          <Map>[
            <String, dynamic>{
              'displayName': _myName,
              'uid': _account,
              'isShaking': true,
            }
          ],
        ),
      });

      // Add myself to the list again with 'isShaking' set to false
      await _roomRef.update({
        'participants': FieldValue.arrayUnion(
          <Map>[
            <String, dynamic>{
              'displayName': _myName,
              'uid': _account,
              'isShaking': false,
            }
          ],
        ),
      });
    });
  }

  Future<void> _initAgora() async {
    await [Permission.camera, Permission.microphone].request();

    RtcEngineContext _rtcEngineContext = RtcEngineContext(appId);

    _rtcEngine = await RtcEngine.createWithContext(_rtcEngineContext);

    // Just for hot-restart
    // TODO: Remove in production
    _rtcEngine.destroy();
    _rtcEngine = await RtcEngine.createWithContext(_rtcEngineContext);

    _rtcEngine.setEventHandler(
      RtcEngineEventHandler(
        joinChannelSuccess: (channel, uid, elapsed) {
          log('Succeeded to join a channel: channel: $channel, uid: $uid');
          setState(() {
            _joined = true;
          });
        },
        userJoined: (uid, elapsed) {
          log('Remote user joined: $uid');
          setState(() {
            _remoteUid = uid;
          });
        },
        userOffline: (uid, reason) {
          log('userOffline: $uid, reason: $reason');
          setState(() {
            _remoteUid = 0;
          });
        },
      ),
    );

    _join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(channelName),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceAround,
                  direction: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Column(
                        children: [
                          Hero(
                            tag: 'profile',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                color: Theme.of(context).colorScheme.primary,
                                width: 100.0,
                                height: 100.0,
                                child: _renderLocalPreview(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            FirebaseAuth.instance.currentUser!.displayName ??
                                'Anonymous',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: SizedBox(
                              width: 100.0,
                              height: 100.0,
                              child: _renderRemoteVideo(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'User B',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Align(
              alignment: const Alignment(0.00, 0.60),
              child: CupertinoButton.filled(
                child: const Text('Share to friends!'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: channelName));
                  Share.share(channelName);
                },
              ),
            ),
            Positioned(
              bottom: 0,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      child: const Text('👋 Leave'),
                      onPressed: _leave,
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      child: const Text('👏'),
                      onPressed: null,
                      //onPressed: () {
                      // TODO: Implement functionallity
                      //},
                    ),
                    RoundedLoadingButton(
                      controller: _muteButtonController,
                      height: 36,
                      width: 72,
                      loaderStrokeWidth: 1.0,
                      animateOnTap: true,
                      resetDuration: const Duration(milliseconds: 1500),
                      resetAfterDuration: true,
                      successIcon: CupertinoIcons.mic_fill,
                      failedIcon: CupertinoIcons.mic_off,
                      successColor: Theme.of(context).colorScheme.primary,
                      errorColor: const Color(0xFFFF2D34),
                      color: _muted
                          ? const Color(0xFFFF2D34)
                          : Theme.of(context).colorScheme.secondary,
                      child: Row(
                        children: [
                          Icon(
                            _muted
                                ? CupertinoIcons.mic_off
                                : CupertinoIcons.mic_fill,
                            size: 12,
                            color: _muted
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          Text(
                            _muted ? 'Muted' : 'Unmuted',
                            style: TextStyle(
                              color: _muted
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () async {
                        await _rtcEngine.muteLocalAudioStream(!_muted);
                        setState(() {
                          _muted = !_muted;
                        });
                        Timer(const Duration(milliseconds: 200), () {
                          _muted
                              ? _muteButtonController.error()
                              : _muteButtonController.success();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: _isShaking,
              child: const Center(
                child: Text(
                  '🍺',
                  style: TextStyle(fontSize: 160.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _join() async {
    final String newToken = await _fetchTokenWithAccount();

    // Using 'newToken' because cannot use async/await inside of setState
    setState(() {
      token = newToken;
    });

    await _rtcEngine.enableVideo();
    await _rtcEngine.joinChannelWithUserAccount(token, channelName, _account);

    _roomRef.get().then((docSnapshot) {
      if (docSnapshot.exists) {
        log('Room already exists. Updating existing doc on Firestore...');
        // Add myself to the list of participants
        _roomRef.update({
          'participants': FieldValue.arrayUnion(
            <Map>[
              <String, dynamic>{
                'displayName': _myName,
                'uid': _account,
                'isShaking': _isShaking,
              }
            ],
          ),
        });
      } else {
        log('Room doesn\'t exist. Creating new doc on Firestore...');
        // Create new room on Firestore
        _roomRef.set(<String, dynamic>{
          'name': channelName,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'owner': <String, dynamic>{
            'displayName': _myName,
            'uid': _account,
          },
          'participants': <Map>[
            <String, dynamic>{
              'displayName': _myName,
              'uid': _account,
              'isShaking': _isShaking,
            },
          ],
        });
      }
    });

    log('Joined the room.');
  }

  Future<void> _leave() async {
    Future.wait([
      _rtcEngine.leaveChannel(),
      _roomRef.update({
        'participants': FieldValue.arrayRemove(
          <Map>[
            <String, dynamic>{
              'displayName': _myName,
              'uid': _account,
              'isShaking': _isShaking,
            }
          ],
        ),
      }),
    ]);

    log('Left the channel.');
    Navigator.pop(context);
  }

  Future<String> _fetchTokenWithAccount() async {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('fetchTokenWithAccount');

    final result = await callable({'channelName': channelName});
    final String token = result.data as String;
    log('Got token via Cloud Functions: $token');

    return token;
  }

  Widget _renderLocalPreview() {
    if (_joined) {
      return Stack(
        children: [
          rtc_local_view.SurfaceView(),
          Visibility(
            visible: _muted,
            child: Container(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              child: Center(
                child: Icon(
                  CupertinoIcons.mic_off,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const CupertinoActivityIndicator();
    }
  }

  Widget _renderRemoteVideo() {
    if (_remoteUid != 0) {
      return rtc_remote_view.SurfaceView(
        uid: _remoteUid,
        channelId: '123',
      );
    } else {
      return const Center(
        child: Icon(CupertinoIcons.hourglass_tophalf_fill),
      );
    }
  }
}
