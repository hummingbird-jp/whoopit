import 'dart:async';
import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
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
import 'package:whoopit/components/participant_circle.dart';

late String token;
late String roomId;

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
    photoUrl: FirebaseAuth.instance.currentUser!.photoURL ?? '',
    isShaking: false,
    isMuted: true,
  );

  final CollectionReference<Map<String, dynamic>> _roomsCollection =
      FirebaseFirestore.instance.collection('rooms');
  final CollectionReference _participantsCollection = FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('participants');
  // Will be initialized after joining the channel
  final List<int> _remoteAgoraUids = [];
  late final DocumentReference _myParticipantRef;

  late RtcEngine _rtcEngine;
  late ShakeDetector _shakeDetector;

  bool _isMeMuted = true;
  bool _isMeClapping = false;

  bool _isMeJoinInProgress = false;
  bool _isMeLeaveInProgress = false;

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

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: GestureDetector(
            onTap: () {
              // TODO: Show cupertino dialog which accepts user input
              // and updates the room name
              GlobalKey<FormState> _formKey = GlobalKey<FormState>();

              showCupertinoDialog<void>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                        title: const Text('New Room Name'),
                        content: Form(
                          key: _formKey,
                          child: CupertinoTextFormFieldRow(
                            autofocus: true,
                            autocorrect: false,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Cannot be blank';
                              }
                              if (value.length > 20) {
                                return 'Must be less than 20 characters';
                              }
                              if (value.contains(RegExp(r'[^a-zA-Z0-9]'))) {
                                return 'Must contain only letters and numbers';
                              }
                              return null;
                            },
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary),
                            onSaved: (value) {
                              log('onSaved');

                              _roomsCollection
                                  .doc(roomId)
                                  .update({'roomName': value});
                            },
                          ),
                        ),
                        actions: <Widget>[
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: const Text('Save'),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ));
            },
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _roomStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Loading...');
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('Something went wrong');
                  }

                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  return Text(data['roomName'] as String);
                }),
          ),
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
                        final String? name = data['name'] as String;
                        final String photoUrl = data['photoUrl'] as String;
                        final bool isMuted = data['isMuted'] as bool;
                        final int shakeCount = data['shakeCount'] as int;
                        final bool isClapping = data['isClapping'] as bool;

                        return Column(
                          children: [
                            ParticipantCircle(
                              photoUrl: photoUrl,
                              name: name,
                              isMuted: isMuted,
                              shakeCount: shakeCount,
                              isClapping: isClapping,
                            ),
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
                    Clipboard.setData(ClipboardData(text: roomId));
                    Share.share(roomId);
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
    int _shakeCount = _shakeDetector.mShakeCount;

    log('_shakeCount: $_shakeCount');
    _myParticipantRef.update({'shakeCount': _shakeCount});
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
        _rtcEngine.joinChannel(token, roomId, null, _me.agoraUid),
      ]);
    } catch (e) {
      log('Failed to join a room: $e');
    }

    _myParticipantRef = _participantsCollection.doc(_me.firebaseUid);

    await _participantsCollection.doc(_me.firebaseUid).set({
      'firebaseUid': _me.firebaseUid,
      'agoraUid': _me.agoraUid,
      'name': _me.name,
      'photoUrl': _me.photoUrl,
      'isMuted': _me.isMuted,
      'shakeCount': 0,
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
        await callable({'channelName': roomId, 'agoraUid': _me.agoraUid});

    return result.data as String;
  }
}

class Participant {
  final String firebaseUid;
  final int agoraUid;
  final String name;
  final String photoUrl;
  final bool isMuted;
  final bool isShaking;

  Participant({
    required this.firebaseUid,
    required this.agoraUid,
    required this.name,
    required this.photoUrl,
    required this.isMuted,
    required this.isShaking,
  });
}
