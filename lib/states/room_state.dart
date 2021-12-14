import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shake/shake.dart';
import 'package:whoopit/components/room_name_dialog.dart';
import 'package:whoopit/models/participant.dart';

final roomProvider = ChangeNotifierProvider((ref) => RoomState());

class RoomState extends ChangeNotifier {
  final String appId = '8d98fb1cbd094508bff710b6a2d199ef';
  final List<int> _remoteAgoraUids = [];
  late RtcEngine _rtcEngine;
  late String _token;
  late String _roomId;

  bool _isMeJoinInProgress = false;
  bool _isMeLeaveInProgress = false;
  bool _isMeClapping = false;
  bool _isMuted = true;

  // Collections
  late CollectionReference<Map<String, dynamic>> _roomsCollection;
  late CollectionReference _participantsCollection;
  late CollectionReference _shakersCollection;

  // Documents
  late DocumentReference _myParticipantDocument;

  // Streams
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _roomStream;
  late Stream<QuerySnapshot> _participantsStream;
  late Stream<QuerySnapshot> _shakersStream;

  // Others
  late Participant _me;
  late ShakeDetector _shakeDetector;

  // Getters
  String get roomId => _roomId;
  bool get isMeJoinInProgress => _isMeJoinInProgress;
  bool get isMeLeaveInProgress => _isMeLeaveInProgress;
  bool get isMeClapping => _isMeClapping;
  bool get isMuted => _isMuted;
  CollectionReference<Map<String, dynamic>> get roomsCollection =>
      _roomsCollection;
  DocumentReference get myParticipantDocument => _myParticipantDocument;
  Stream<DocumentSnapshot<Map<String, dynamic>>> get roomStream => _roomStream;
  Stream<QuerySnapshot> get participantsStream => _participantsStream;
  Stream<QuerySnapshot> get shakersStream => _shakersStream;
  Participant get me => _me;

  // Setters
  set roomId(String value) {
    roomId = value;
    notifyListeners();
  }

  set token(String value) {
    token = value;
    notifyListeners();
  }

  set setIsMeJoinInProgress(bool value) {
    _isMeJoinInProgress = value;
    notifyListeners();
  }

  set setIsMeLeaveInProgress(bool value) {
    _isMeLeaveInProgress = value;
    notifyListeners();
  }

  set setIsMeClapping(bool value) {
    _isMeClapping = value;
    notifyListeners();
  }

  Future<void> init(String roomId) async {
    await [Permission.camera, Permission.microphone].request();

    // Init Agora Rtc Engine
    RtcEngineContext _rtcEngineContext = RtcEngineContext(appId);
    // TODO: Remove in production
    _rtcEngine = await RtcEngine.createWithContext(_rtcEngineContext);
    _rtcEngine.destroy();
    _rtcEngine = await RtcEngine.createWithContext(_rtcEngineContext);
    _rtcEngine.setEventHandler(
      RtcEngineEventHandler(
        joinChannelSuccess: (channel, uid, elapsed) {
          log('Joined a room: $channel');
        },
        userJoined: (uid, elapsed) {
          log('Remote user joined: $uid');
          _remoteAgoraUids.add(uid);
          notifyListeners();
        },
        userOffline: (uid, reason) {
          log('userOffline: $uid, reason: $reason');
          _remoteAgoraUids.remove(uid);
          notifyListeners();
        },
        error: (err) {
          log('Error in Agora: $err');
        },
      ),
    );

    _roomId = roomId;

    // Init collections
    _roomsCollection = FirebaseFirestore.instance.collection('rooms');
    _participantsCollection = FirebaseFirestore.instance
        .collection('rooms')
        .doc(_roomId)
        .collection('participants');
    _shakersCollection = FirebaseFirestore.instance
        .collection('rooms')
        .doc(_roomId)
        .collection('shakers');

    _me = Participant(
      agoraUid: FirebaseAuth.instance.currentUser!.uid.hashCode,
      name: FirebaseAuth.instance.currentUser!.displayName ?? '',
      firebaseUid: FirebaseAuth.instance.currentUser!.uid,
      photoUrl: FirebaseAuth.instance.currentUser!.photoURL ?? '',
      isShaking: false,
      isMuted: true,
    );

    // Init documents
    _myParticipantDocument = _participantsCollection.doc(_me.firebaseUid);

    // Init streams
    _roomStream = _roomsCollection.doc(_roomId).snapshots();
    _participantsStream = _participantsCollection.snapshots();
    _shakersStream =
        _roomsCollection.doc(_roomId).collection('shakers').snapshots();

    // Init others
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () {
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
        notifyListeners();
      },
      shakeCountResetTime: 2000,
    );
  }

  Future<void> clap() async {
    _isMeClapping = true;
    _myParticipantDocument.update({'isClapping': true});

    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 1000), () async {
      _isMeClapping = false;
      _myParticipantDocument.update({'isClapping': false});
      notifyListeners();
    });
  }

  Future<void> join() async {
    _isMeJoinInProgress = true;
    _token = await _fetchTokenWithUid();

    _rtcEngine.joinChannel(
      _token,
      _roomId,
      null,
      FirebaseAuth.instance.currentUser!.uid.hashCode,
    );
    await _rtcEngine.enableAudio();
    await _rtcEngine.muteLocalAudioStream(true);

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

    _isMeJoinInProgress = false;

    notifyListeners();
  }

  Future<void> leave(BuildContext context) async {
    _isMeLeaveInProgress = true;

    HapticFeedback.lightImpact();

    _myParticipantDocument.update({
      'isJoined': false,
    });

    await Future.wait([
      _rtcEngine.leaveChannel(),
      _rtcEngine.disableAudio(),
      _rtcEngine.destroy(),
    ]);

    Navigator.pop(context);
    _isMeLeaveInProgress = false;

    notifyListeners();
  }

  Future<void> mute() async {
    HapticFeedback.lightImpact();
    _myParticipantDocument.update({
      'isMuted': !isMuted,
    });
    await _rtcEngine.muteLocalAudioStream(!_isMuted);
    _isMuted = !_isMuted;
    notifyListeners();
  }

  Future<String> _fetchTokenWithUid() async {
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('fetchTokenWithUid');

    final result = await callable(<String, dynamic>{
      'channelName': roomId,
      'agoraUid': FirebaseAuth.instance.currentUser!.uid.hashCode,
    });

    return result.data as String;
  }

  void onRoomNameTapped(BuildContext context) {
    GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => RoomNameDialog(
        formKey: _formKey,
        roomsCollection: _roomsCollection,
      ),
    );
  }
}
