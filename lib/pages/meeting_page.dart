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
  bool get joined => _joined;
  int _remoteUid = 0;
  bool _muted = false;
  final RoundedLoadingButtonController _buttonController =
      RoundedLoadingButtonController();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    await [Permission.camera, Permission.microphone].request();

    print('initPlatformState called.');
    RtcEngineContext _rtcEngineContext = RtcEngineContext(appId);

    agoraEngine = await RtcEngine.createWithContext(_rtcEngineContext);
    // TODO: Just for hot-restart. Remove when publish.
    agoraEngine.destroy();
    print('agoraEngine destroyed.');
    agoraEngine = await RtcEngine.createWithContext(_rtcEngineContext);
    print('agoraEngine re-initialized.');

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

    try {
      await agoraEngine.enableVideo();
      await agoraEngine.joinChannel(token, channelName, null, 0);

      print('Succeeded to join a channel: $channelName');
    } catch (e) {
      print('Failed to join a channel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Whoopit',
          style: TextStyle(
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
        previousPageTitle: 'Home',
        //leading: const HomePage(),
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
                  // <ApplicationState>(
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
                          '👋 Leave',
                          style: TextStyle(
                            color: CupertinoTheme.of(context)
                                .primaryContrastingColor,
                          ),
                        ),
                        onPressed: () async {
                          await agoraEngine.leaveChannel();
                          print('Left the channel.');
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
                        onPressed: () {
                          // TODO: Implement functionallity
                        },
                      ),
                      RoundedLoadingButton(
                        controller: _buttonController,
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
                            : CupertinoTheme.of(context)
                                .primaryContrastingColor,
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
                                ? _buttonController.error()
                                : _buttonController.success();
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
      return ElevatedButton(
        onPressed: initPlatformState,
        child: const Icon(CupertinoIcons.refresh_bold),
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
