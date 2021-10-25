import 'dart:async';
import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

const String appId = '8d98fb1cbd094508bff710b6a2d199ef';
const String channelName = 'test';
String token = '';
late RtcEngine agoraEngine;

class MeetingPage extends StatefulWidget {
  const MeetingPage({Key? key}) : super(key: key);

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  bool _joined = false;
  bool get joined => _joined;
  int _remoteUid = 0;
  bool _muted = false;
  final RoundedLoadingButtonController _muteButtonController =
      RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    await [Permission.camera, Permission.microphone].request();

    RtcEngineContext _rtcEngineContext = RtcEngineContext(appId);

    agoraEngine = await RtcEngine.createWithContext(_rtcEngineContext);
    agoraEngine.destroy();
    agoraEngine = await RtcEngine.createWithContext(_rtcEngineContext);

    agoraEngine.setEventHandler(
      RtcEngineEventHandler(
        joinChannelSuccess: (channel, uid, elapsed) {
          log('joinChannelSuccess: $channel $uid');
          setState(() {
            _joined = true;
          });
        },
        userJoined: (uid, elapsed) {
          log('userJoined: $uid');
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

    log('Agora Platform State initialized.');

    _join();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              color: CupertinoTheme.of(context).primaryColor,
                              width: 100.0,
                              height: 100.0,
                              child: _renderLocalPreview(),
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
                          CupertinoTheme.of(context).primaryColor,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: CupertinoTheme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      child: Text(
                        '👋 Leave',
                        style: TextStyle(
                          color: CupertinoTheme.of(context)
                              .primaryContrastingColor,
                        ),
                      ),
                      onPressed: () async {
                        await agoraEngine.leaveChannel();
                        log('Left the channel.');
                        Navigator.pop(context);
                      },
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          CupertinoTheme.of(context).primaryColor,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: CupertinoTheme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                      child: Text(
                        '👏',
                        style: TextStyle(
                          color: CupertinoTheme.of(context)
                              .primaryContrastingColor,
                        ),
                      ),
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
                      successColor: CupertinoTheme.of(context).primaryColor,
                      errorColor: const Color(0xFFFF2D34),
                      color: _muted
                          ? const Color(0xFFFF2D34)
                          : CupertinoTheme.of(context).primaryContrastingColor,
                      child: Row(
                        children: [
                          Icon(
                            _muted
                                ? CupertinoIcons.mic_off
                                : CupertinoIcons.mic_fill,
                            size: 12,
                            color: _muted
                                ? CupertinoTheme.of(context)
                                    .primaryContrastingColor
                                : CupertinoTheme.of(context).primaryColor,
                          ),
                          Text(
                            _muted ? 'Muted' : 'Unmuted',
                            style: TextStyle(
                              color: _muted
                                  ? CupertinoTheme.of(context)
                                      .primaryContrastingColor
                                  : CupertinoTheme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () async {
                        await agoraEngine.muteLocalAudioStream(!_muted);
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

    await agoraEngine.enableVideo();

    final String account = FirebaseAuth.instance.currentUser!.uid;
    await agoraEngine.joinChannelWithUserAccount(token, channelName, account);
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
              color: CupertinoTheme.of(context).primaryColor.withOpacity(0.8),
              child: Center(
                child: Icon(
                  CupertinoIcons.mic_off,
                  color: CupertinoTheme.of(context).primaryContrastingColor,
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
