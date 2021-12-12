import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authProvider =
    ChangeNotifierProvider<AuthenticationState>((_) => AuthenticationState());

class AuthenticationState extends ChangeNotifier {
  final User? _user = FirebaseAuth.instance.currentUser;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  String? get email => FirebaseAuth.instance.currentUser!.email;
  String? get displayName => FirebaseAuth.instance.currentUser!.displayName;
  String? get photoUrl => FirebaseAuth.instance.currentUser?.photoURL;
  bool get isSignedIn => _user != null;

  Future<void> updatePhotoURL(String photoUrl) async {
    await _user!.updatePhotoURL(photoUrl);
    notifyListeners();
  }
}
