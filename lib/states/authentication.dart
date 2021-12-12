import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final authProvider = ChangeNotifierProvider<Authentication>((_) => Authentication());

class Authentication extends ChangeNotifier {
  User? _user = FirebaseAuth.instance.currentUser;
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  String? get email => FirebaseAuth.instance.currentUser!.email;
  String? get displayName => FirebaseAuth.instance.currentUser!.displayName;
  String? get photoUrl => FirebaseAuth.instance.currentUser?.photoURL;
  bool get isSignedIn => _user != null;

  Future<bool> signUp(
    String email,
    String displayName,
    String password,
    void Function(FirebaseAuthException err) errorCallback,
  ) async {
    try {
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      // Force update _user
      _user = FirebaseAuth.instance.currentUser;
      await credential.user!.updateDisplayName(displayName);

      notifyListeners();
      log('Succeeded to Sign Up.');

      return true;
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
      log('Failed to Sign Up: $e');

      return false;
    }
  }

  Future<bool> signIn(
    String email,
    String password,
    void Function(FirebaseAuthException err) errorCallBack,
  ) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      // Force update _user
      _user = FirebaseAuth.instance.currentUser;

      notifyListeners();
      log('Succeeded to Sign In');

      return true;
    } on FirebaseAuthException catch (e) {
      errorCallBack(e);
      log('Failed to Sign In: $e');

      return false;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut().then((_) => _user = null);
    notifyListeners();
  }

  Future<void> updateUserInfo({
    required String newDisplayName,
  }) async {
    await _user!.updateDisplayName(newDisplayName);
    notifyListeners();
  }

  Future<void> updatePhotoURL(String photoUrl) async {
    await _user!.updatePhotoURL(photoUrl);
    notifyListeners();
  }
}
