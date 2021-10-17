import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gtk_flutter/pages/home_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

const String appId = '8d98fb1cbd094508bff710b6a2d199ef';
const String token =
    '0068d98fb1cbd094508bff710b6a2d199efIAARboItECdGrAG6C4wo/BAUIh/O1Qo8LpJVFbSzTRkvpAx+f9gAAAAAEACOYDhkhDttYQEAAQCEO21h';
const String channelName = 'test';
late RtcEngine agoraEngine;

class MeetingPage extends StatefulWidget {
  const MeetingPage({Key? key}) : super(key: key);

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  bool _joined = false;
  int _remoteUid = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    await [Permission.camera, Permission.microphone].request();

    RtcEngineContext _rtcEngineContext = RtcEngineContext(appId);

    agoraEngine = await RtcEngine.createWithContext(_rtcEngineContext);
    // TODO: Just for hot-restart. Remove when publish.
    agoraEngine.destroy();
    agoraEngine = await RtcEngine.createWithContext(_rtcEngineContext);

    agoraEngine.setEventHandler(
      RtcEngineEventHandler(
        joinChannelSuccess: (channel, uid, elapsed) {
          print('joinChannelSuccess: $channel $uid');

          setState(() {
            _joined = true;
          });
        },
        userJoined: (uid, elapsed) {
          print('userJoined: $uid');

          setState(() {
            _remoteUid = uid;
          });
        },
        userOffline: (uid, reason) {
          print('userOffline: $uid, reason: $reason');

          setState(() {
            _remoteUid = 0;
          });
        },
      ),
    );

    await agoraEngine.enableVideo();
    await agoraEngine.joinChannel(token, 'test', null, 0);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Project X',
          style: TextStyle(
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
      ),
      child: Material(
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
                              child: SizedBox(
                                width: 100.0,
                                height: 100.0,
                                child: _renderLocalPreview(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'User A',
                              style: TextStyle(
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
                  //Consumer<ApplicationState>(
                  //  builder: (context, appState, _) => Column(
                  //    crossAxisAlignment: CrossAxisAlignment.start,
                  //    children: [
                  //      if (appState.loginState ==
                  //          ApplicationLoginState.loggedIn) ...[
                  //        Chat(
                  //          addMessage: (message) =>
                  //              appState.addMessageToGuestBook(message),
                  //          messages: appState.guestBookMessages,
                  //        )
                  //      ]
                  //    ],
                  //  ),
                  //),
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
                          '👋 Leave quietly',
                          style: TextStyle(
                            color: CupertinoTheme.of(context)
                                .primaryContrastingColor,
                          ),
                        ),
                        onPressed: () {
                          agoraEngine.leaveChannel();
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
                        onPressed: () {
                          // TODO: Implement functionallity
                        },
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                            CupertinoTheme.of(context).primaryContrastingColor,
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
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.mic_fill,
                              size: 12,
                              color: CupertinoTheme.of(context).primaryColor,
                            ),
                            Text(
                              'Mute',
                              style: TextStyle(
                                color: CupertinoTheme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () {
                          agoraEngine.muteLocalAudioStream(!_muted);
                          setState(() {
                            _muted = !_muted;
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
      ),
    );
  }

  Widget _renderLocalPreview() {
    if (_joined) {
      return rtc_local_view.SurfaceView();
    } else {
      return const Text(
        'Please join a channel first.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      );
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
        child: Text(
          'Waiting for a user...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }
}
