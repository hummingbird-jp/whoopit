import 'dart:async';
import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:shake/shake.dart';
import 'package:share_plus/share_plus.dart';

late String token;
late String roomName;

class RoomPage extends StatefulWidget {
  const RoomPage({Key? key}) : super(key: key);

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final String appId = '8d98fb1cbd094508bff710b6a2d199ef';
  final RoundedLoadingButtonController _muteButtonController =
      RoundedLoadingButtonController();
  final Participant _me = Participant(
    agoraUid: FirebaseAuth.instance.currentUser!.uid.hashCode,
    name: FirebaseAuth.instance.currentUser!.displayName ?? '',
    firebaseUid: FirebaseAuth.instance.currentUser!.uid,
    isShaking: false,
    isMuted: true,
  );

  final CollectionReference _participantsCollection = FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomName)
      .collection('participants');
  // Will be initialized after joining the channel
  final List<int> _remoteAgoraUids = [];
  late final DocumentReference _myParticipantRef;
  final Stream<QuerySnapshot> _participantsStream = FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomName)
      .collection('participants')
      .snapshots();

  late RtcEngine _rtcEngine;
  late ShakeDetector _shakeDetector;

  bool _isMeJoined = false;
  bool _isMeMuted = true;
  bool _isMeShaking = false;
  bool _isMeClapping = false;

  bool _isMeJoinInProgress = false;
  bool _isMeLeaveInProgress = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
    _shakeDetector = ShakeDetector.autoStart(onPhoneShake: _onShake);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(roomName),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _participantsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Something went wrong');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }

                  return Center(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      direction: Axis.horizontal,
                      spacing: 20,
                      runSpacing: 40,
                      children: snapshot.data!.docs.map((doc) {
                        final Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        final int agoraUid = data['agoraUid'] as int;
                        final String firebaseUid =
                            data['firebaseUid'] as String;
                        final String? name = data['name'] as String;
                        final bool isMe = agoraUid == _me.agoraUid;
                        final bool isMuted = data['isMuted'] as bool;
                        final bool isShaking = data['isShaking'] as bool;
                        final bool isClapping = data['isClapping'] as bool;

                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                color: Theme.of(context).colorScheme.primary,
                                width: 100.0,
                                height: 100.0,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Text(name!),
                                    ),
                                    Visibility(
                                      visible: isMuted,
                                      child: Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.8),
                                        child: Center(
                                          child: Icon(
                                            CupertinoIcons.mic_off,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: isShaking,
                                      child: const Center(
                                        child: Text(
                                          '🍺',
                                          style: TextStyle(fontSize: 80.0),
                                        ),
                                      ),
                                    ),
                                    Visibility(
                                      visible: isClapping,
                                      child: const Center(
                                        child: Text(
                                          '👏',
                                          style: TextStyle(fontSize: 80.0),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              Align(
                alignment: const Alignment(0.00, 0.60),
                child: CupertinoButton.filled(
                  child: const Text('Share to friends!'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomName));
                    Share.share(roomName);
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
                        onPressed: _onLeave,
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
                        onPressed: _isMeClapping ? null : _onClap,
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
                        color: _isMeMuted
                            ? const Color(0xFFFF2D34)
                            : Theme.of(context).colorScheme.secondary,
                        child: Row(
                          children: [
                            Icon(
                              _isMeMuted
                                  ? CupertinoIcons.mic_off
                                  : CupertinoIcons.mic_fill,
                              size: 12,
                              color: _isMeMuted
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            Text(
                              _isMeMuted ? 'Muted' : 'Unmuted',
                              style: TextStyle(
                                color: _isMeMuted
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        onPressed: _onMute,
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: _isMeJoinInProgress || _isMeLeaveInProgress,
                child: Opacity(
                  opacity: 0.8,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Theme.of(context).colorScheme.background,
                    child: const Center(child: CupertinoActivityIndicator()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initAgora() async {
    RtcEngineContext _rtcEngineContext = RtcEngineContext(appId);

    await [Permission.camera, Permission.microphone].request();
    _rtcEngine = await RtcEngine.createWithContext(_rtcEngineContext);

    // Just for hot-restart
    // TODO: Remove in production
    _rtcEngine.destroy();
    _rtcEngine = await RtcEngine.createWithContext(_rtcEngineContext);

    _rtcEngine.setEventHandler(
      RtcEngineEventHandler(
        joinChannelSuccess: (channel, uid, elapsed) {
          log('Joined a room: $channel');
          setState(() {
            _isMeJoined = true;
          });
        },
        userJoined: (uid, elapsed) {
          log('Remote user joined: $uid');
          setState(() {
            _remoteAgoraUids.add(uid);
          });
        },
        userOffline: (uid, reason) {
          log('userOffline: $uid, reason: $reason');
          setState(() {
            _remoteAgoraUids.remove(uid);
          });
        },
        error: (err) {
          log('Error in Agora: $err');
        },
      ),
    );

    _onJoin();
  }

  Future<void> _onMute() async {
    _myParticipantRef.update({
      'isMuted': !_isMeMuted,
    });

    await _rtcEngine.muteLocalAudioStream(!_isMeMuted);
    HapticFeedback.lightImpact();

    setState(() {
      _isMeMuted = !_isMeMuted;
    });

    Timer(const Duration(milliseconds: 200), () {
      _isMeMuted
          ? _muteButtonController.error()
          : _muteButtonController.success();
    });
  }

  Future<void> _onShake() async {
    log('_shakeDetector.count: ${_shakeDetector.mShakeCount}');

    if (_isMeShaking == true) {
      return;
    } else if (_shakeDetector.mShakeCount == 3) {
      setState(() {
        _isMeShaking = true;
      });

      _myParticipantRef.update({'isShaking': true});
      HapticFeedback.lightImpact();
    }

    Future.delayed(const Duration(milliseconds: 8000), () async {
      setState(() {
        _isMeShaking = false;
      });
      _myParticipantRef.update({'isShaking': false});
    });
  }

  Future<void> _onClap() async {
    setState(() {
      _isMeClapping = true;
    });
    _myParticipantRef.update({'isClapping': true});

    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 200), () async {
      setState(() {
        _isMeClapping = false;
      });
      _myParticipantRef.update({'isClapping': false});
    });
  }

  Future<void> _onJoin() async {
    setState(() {
      _isMeJoinInProgress = true;
    });

    final String newToken = await _fetchTokenWithUid();

    // Using 'newToken' because cannot use async/await inside of setState
    setState(() {
      token = newToken;
    });

    try {
      Future.wait([
        _rtcEngine.enableVideo(),
        _rtcEngine.joinChannel(token, roomName, null, _me.agoraUid),
      ]);
    } catch (e) {
      log('Failed to join a room: $e');
    }

    _myParticipantRef = _participantsCollection.doc(_me.firebaseUid);

    await _participantsCollection.doc(_me.firebaseUid).set({
      'firebaseUid': _me.firebaseUid,
      'agoraUid': _me.agoraUid,
      'name': _me.name,
      'isMuted': _me.isMuted,
      'isShaking': false,
      'isClapping': false,
    });

    setState(() {
      _isMeJoinInProgress = false;
    });
  }

  Future<void> _onLeave() async {
    setState(() {
      _isMeLeaveInProgress = true;
    });

    _myParticipantRef.delete();

    HapticFeedback.lightImpact();

    try {
      await _rtcEngine.leaveChannel();
      await _rtcEngine.disableVideo();
      await _rtcEngine.destroy();
    } on Exception catch (e) {
      log('Error leaving room: $e');
    }

    Navigator.pop(context);

    setState(() {
      _isMeLeaveInProgress = false;
    });

    log('Left the room.');
  }

  Future<String> _fetchTokenWithUid() async {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('fetchTokenWithUid');

    final result =
        await callable({'channelName': roomName, 'agoraUid': _me.agoraUid});

    return result.data as String;
  }

  Widget _renderLocalPreview() {
    if (_isMeJoined) {
      return rtc_local_view.SurfaceView();
    } else {
      return const CupertinoActivityIndicator();
    }
  }

  Widget _renderRemotePreview(int _remoteAgoraUid) {
    return rtc_remote_view.SurfaceView(
      uid: _remoteAgoraUid,
      channelId: '123',
    );
  }
}

class Participant {
  final String firebaseUid;
  final int agoraUid;
  final String name;
  final bool isMuted;
  final bool isShaking;

  Participant({
    required this.firebaseUid,
    required this.agoraUid,
    required this.name,
    required this.isMuted,
    required this.isShaking,
  });
}
