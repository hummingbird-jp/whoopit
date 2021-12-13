class Participant {
  Participant({
    required this.firebaseUid,
    required this.agoraUid,
    required this.name,
    required this.photoUrl,
    required this.isMuted,
    required this.isShaking,
  });

  final String firebaseUid;
  final int agoraUid;
  String name;
  String photoUrl;
  bool isMuted;
  bool isShaking;
}
