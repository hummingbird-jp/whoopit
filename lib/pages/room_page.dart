import 'dart:async';
import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shake/shake.dart';
import 'package:whoopit/components/participant_circle.dart';
import 'package:whoopit/models/cheers.dart';
import 'package:whoopit/models/full_screen_activity_indicator.dart';
import 'package:whoopit/models/participant.dart';
import 'package:whoopit/models/pill_button.dart';
import 'package:whoopit/models/room_name_dialog.dart';
import 'package:whoopit/models/share_room_url_button.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({Key? key, required this.roomId}) : super(key: key);

  @override
  State<RoomPage> createState() => _RoomPageState();

  final String roomId;
}

class _RoomPageState extends State<RoomPage> {
  // Agora
  final String appId = '8d98fb1cbd094508bff710b6a2d199ef';
  final List<int> _remoteAgoraUids = [];
  late RtcEngine _rtcEngine;
  late String token;
  late String roomId = widget.roomId;

  // Firebase
  final CollectionReference<Map<String, dynamic>> _roomsCollection =
      FirebaseFirestore.instance.collection('rooms');
  late final CollectionReference _participantsCollection = FirebaseFirestore
      .instance
      .collection('rooms')
      .doc(roomId)
      .collection('participants');
  late final CollectionReference _shakersCollection = FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('shakers');
  late final DocumentReference _myParticipantDocument;

  // Sounds
  final AudioPlayer _bgmPlayer = AudioPlayer();
  late final AudioCache _bgmCache = AudioCache(
    prefix: 'assets/sounds/',
    fixedPlayer: _bgmPlayer,
  );

  // Others
  bool _isMeMuted = true;
  bool _isMeClapping = false;
  bool _isMeJoinInProgress = false;
  bool _isMeLeaveInProgress = false;
  late ShakeDetector _shakeDetector;
  final Participant _me = Participant(
    agoraUid: FirebaseAuth.instance.currentUser!.uid.hashCode,
    name: FirebaseAuth.instance.currentUser!.displayName ?? '',
    firebaseUid: FirebaseAuth.instance.currentUser!.uid,
    photoUrl: FirebaseAuth.instance.currentUser!.photoURL ?? '',
    isShaking: false,
    isMuted: true,
  );

  @override
  void initState() {
    super.initState();
    _initAgora();
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: _onShake,
      shakeCountResetTime: 2000,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Stream<DocumentSnapshot<Map<String, dynamic>>> _roomStream =
        _roomsCollection.doc(roomId).snapshots();
    final Stream<QuerySnapshot> _participantsStream =
        _participantsCollection.snapshots();
    final Stream<QuerySnapshot> _shakersStream =
        _roomsCollection.doc(roomId).collection('shakers').snapshots();

    return WillPopScope(
      onWillPop: () async => false,
      child: StreamBuilder<QuerySnapshot>(
        stream: _shakersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CupertinoActivityIndicator();
          }

          return Scaffold(
            appBar: AppBar(
              backgroundColor:
                  snapshot.hasData && snapshot.data!.docs.length >= 2
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.background,
              automaticallyImplyLeading: false,
              title: GestureDetector(
                onTap: _onRoomNameTapped,
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _roomStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CupertinoActivityIndicator();
                      }

                      Map<String, dynamic>? data = snapshot.data!.data();
                      return Text(data?['roomName'] as String? ?? roomId);
                    }),
              ),
            ),
            backgroundColor: snapshot.hasData && snapshot.data!.docs.length >= 2
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.background,
            body: SafeArea(
              child: Stack(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _participantsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CupertinoActivityIndicator();
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
                            final String? name = data['name'] as String;
                            final String photoUrl = data['photoUrl'] as String;
                            final bool isMuted = data['isMuted'] as bool;
                            final int shakeCount = data['shakeCount'] as int;
                            final bool isClapping = data['isClapping'] as bool;
                            final bool isMe =
                                data['firebaseUid'] == _me.firebaseUid;
                            String? currentGifUrl = data['gifUrl'] as String?;
                            final bool isJoined = data['isJoined'] as bool;

                            if (shakeCount >= 10) {
                              HapticFeedback.vibrate();
                              // TODO: Play boom sound
                            }

                            return GestureDetector(
                              onTap: () async {
                                if (isMe) {
                                  if (currentGifUrl == null) {
                                    GiphyGif? _newGif = await GiphyGet.getGif(
                                      context: context,
                                      apiKey:
                                          'zS43gpI1tyh32oBapKuwt7vNXz7PMoOe',
                                      lang: GiphyLanguage.english,
                                      tabColor:
                                          Theme.of(context).colorScheme.primary,
                                    );
                                    currentGifUrl = _newGif!
                                        .images!.original!.webp as String;

                                    _myParticipantDocument.update({
                                      'gifUrl': currentGifUrl,
                                    });
                                  } else {
                                    _myParticipantDocument.update({
                                      'gifUrl': null,
                                    });
                                  }
                                } else {
                                  log('Ignored because it\'s not you');
                                }
                              },
                              child: ParticipantCircle(
                                photoUrl: photoUrl,
                                name: name,
                                isMuted: isMuted,
                                shakeCount: shakeCount,
                                isClapping: isClapping,
                                gifUrl: currentGifUrl,
                                isJoined: isJoined,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: const Alignment(0.00, 0.60),
                    child: ShareRoomUrlButton(
                      roomId: roomId,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          PillButton(
                            child: const Text('👋 Leave'),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: _onLeave,
                          ),
                          PillButton(
                            child: const Text('👏'),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: _isMeClapping ? null : _onClap,
                          ),
                          PillButton(
                            child: _isMeMuted
                                ? const Text('Unmute')
                                : const Text('Mute'),
                            color: _isMeMuted
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary,
                            onPressed: _onMute,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Cheers(shakersStream: _shakersStream),
                  FullScreenActivityIndicator(
                    isLoading: _isMeJoinInProgress || _isMeLeaveInProgress,
                  ),
                ],
              ),
            ),
          );
        },
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
    _myParticipantDocument.update({
      'isMuted': !_isMeMuted,
    });

    await _rtcEngine.muteLocalAudioStream(!_isMeMuted);
    HapticFeedback.lightImpact();

    setState(() {
      _isMeMuted = !_isMeMuted;
    });

    if (_isMeMuted) {
      _rtcEngine.muteLocalAudioStream(true);
    } else {
      _rtcEngine.muteLocalAudioStream(false);
    }
  }

  Future<void> _onShake() async {
    HapticFeedback.mediumImpact();

    int _shakeCount = _shakeDetector.mShakeCount;
    _myParticipantDocument.update({'shakeCount': _shakeCount});

    if (_shakeCount < 3) {
      _shakersCollection.doc(_me.firebaseUid).delete();
    }

    if (_shakeCount >= 3 && _shakeCount < 10) {
      _shakersCollection.doc(_me.firebaseUid).set(({
            'shakeCount': _shakeCount,
            'timestamp': Timestamp.now(),
          }));
    }
  }

  Future<void> _onClap() async {
    setState(() {
      _isMeClapping = true;
    });
    _myParticipantDocument.update({'isClapping': true});

    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 1000), () async {
      setState(() {
        _isMeClapping = false;
      });
      _myParticipantDocument.update({'isClapping': false});
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

    _playBgm();

    try {
      Future.wait([
        _rtcEngine.joinChannel(token, roomId, null, _me.agoraUid),
        _rtcEngine.enableAudio(),
        _rtcEngine.muteLocalAudioStream(true),
      ]);
    } catch (e) {
      log('Failed to join a room: $e');
    }

    _myParticipantDocument = _participantsCollection.doc(_me.firebaseUid);

    await _participantsCollection.doc(_me.firebaseUid).set({
      'firebaseUid': _me.firebaseUid,
      'agoraUid': _me.agoraUid,
      'name': _me.name,
      'photoUrl': _me.photoUrl,
      'isMuted': _me.isMuted,
      'shakeCount': 0,
      'isClapping': false,
      'isJoined': true
    });

    setState(() {
      _isMeJoinInProgress = false;
    });
  }

  Future<void> _onLeave() async {
    _bgmPlayer.stop();

    setState(() {
      _isMeLeaveInProgress = true;
    });

    _myParticipantDocument.update({
      'isJoined': false,
    });

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

    final result = await callable(
        <String, dynamic>{'channelName': roomId, 'agoraUid': _me.agoraUid});

    return result.data as String;
  }

  Future<void> _playBgm() async {
    await _bgmCache.loop('jazz.mp3', volume: 0.01);
  }

  void _onRoomNameTapped() {
    GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => RoomNameDialog(
        formKey: _formKey,
        roomsCollection: _roomsCollection,
        roomId: roomId,
      ),
    );
  }
}
