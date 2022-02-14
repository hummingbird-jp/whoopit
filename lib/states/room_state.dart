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
import 'package:whoopit/pages/room_page.dart';
import 'package:whoopit/states/audio_state.dart';

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

    await _initAgora();
    _roomId = roomId;
    _initCollections();
    _initDocuments();
    _initStreams();
    _initShakeDetector();
  }

  Future<void> _initAgora() async {
    RtcEngineContext _rtcEngineContext = RtcEngineContext(appId);
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
  }

  void _initShakeDetector() {
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

  void _initStreams() {
    _roomStream = _roomsCollection.doc(_roomId).snapshots();
    _participantsStream = _participantsCollection.snapshots();
    _shakersStream =
        _roomsCollection.doc(_roomId).collection('shakers').snapshots();
  }

  void _initDocuments() {
    _myParticipantDocument = _participantsCollection.doc(_me.firebaseUid);
  }

  void _initCollections() {
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
  }

  Future<void> clap() async {
    log('roomState.clap()');

    _isMeClapping = true;
    _myParticipantDocument.update({'isClapping': true});

    HapticFeedback.lightImpact();

    Future.delayed(const Duration(milliseconds: 1000), () async {
      _isMeClapping = false;
      _myParticipantDocument.update({'isClapping': false});
      notifyListeners();
    });
  }

  Future<void> create(
    BuildContext context,
    AudioState audioState,
    String roomId,
  ) async {
    HapticFeedback.heavyImpact();

    roomsCollection.doc(roomId).set(<String, dynamic>{
      'roomName': roomId,
      'createdAt': Timestamp.now(),
    });

    join(context, roomId, audioState);
  }

  Future<void> join(
      BuildContext context, String roomId, AudioState audioState) async {
    _isMeJoinInProgress = true;

    HapticFeedback.lightImpact();

    await init(roomId);

    _token = await _fetchTokenWithUid();

    _rtcEngine.joinChannel(
      _token,
      _roomId,
      null,
      FirebaseAuth.instance.currentUser!.uid.hashCode,
    );
    await _rtcEngine.enableAudio();
    await _rtcEngine.muteLocalAudioStream(true);

    await _addMeToParticipants();
    await _addMyInterestsToRoomsInterests(roomId);

    await audioState.playBGM();

    _isMeJoinInProgress = false;

    Navigator.push<RoomPage>(
      context,
      CupertinoPageRoute(
        builder: (context) => const RoomPage(),
      ),
    );

    notifyListeners();
  }

  Future<void> _addMeToParticipants() async {
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
  }

  Future<void> _addMyInterestsToRoomsInterests(String roomId) async {
    final roomInterestsCollection =
        roomsCollection.doc(roomId).collection('interests');
    final users = FirebaseFirestore.instance.collection('users');
    final me = users.doc(FirebaseAuth.instance.currentUser!.uid);
    final myInterestsCollection = me.collection('interests');

    await myInterestsCollection.get().then((myInterests) {
      for (var myInterest in myInterests.docs) {
        roomInterestsCollection.add(myInterest.data());
      }
    });
  }

  Future<void> leave(BuildContext context, AudioState audioState) async {
    _isMeLeaveInProgress = true;

    HapticFeedback.lightImpact();

    _myParticipantDocument.update({
      'isJoined': false,
    });

    await Future.wait([
      _rtcEngine.leaveChannel(),
      _rtcEngine.disableAudio(),
      _rtcEngine.destroy(),
      audioState.stopBGM(),
    ]);

    Navigator.pop(context);
    _isMeLeaveInProgress = false;

    notifyListeners();
  }

  Future<void> delete(String roomId) async =>
      roomsCollection.doc(roomId).delete();

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
