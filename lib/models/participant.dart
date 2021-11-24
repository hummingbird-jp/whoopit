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
