import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/pages/tabs_page.dart';

class SignupPage extends StatelessWidget {
  SignupPage({Key? key}) : super(key: key);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextFormFieldRow(
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                placeholder: 'Email',
                prefix: const Icon(CupertinoIcons.mail),
              ),
              CupertinoTextFormFieldRow(
                autocorrect: false,
                controller: _passwordController,
                placeholder: 'Password',
                prefix: const Icon(CupertinoIcons.shield_fill),
              ),
              CupertinoTextFormFieldRow(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                placeholder: 'Name',
                prefix: const Icon(CupertinoIcons.profile_circled),
              ),
              CupertinoButton.filled(
                child: const Text('SIGN UP'),
                onPressed: () async {
                  bool success = await _signUp(
                    _emailController.text,
                    _nameController.text,
                    _passwordController.text,
                    (err) =>
                        _showErrorDialog(context, 'Failed to sign up', err),
                  );

                  if (success) {
                    Navigator.push<Widget>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TabsPage(),
                      ),
                    );
                  }
                },
              ),
              CupertinoButton(
                child: const Icon(CupertinoIcons.arrow_left),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: avoid_void_async
  Future<bool> _signUp(
    String email,
    String displayName,
    String password,
    void Function(FirebaseAuthException err) errorCallback,
  ) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(displayName);
      return FirebaseAuth.instance.currentUser != null;
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
      return FirebaseAuth.instance.currentUser != null;
    }
  }

  void _showErrorDialog(BuildContext context, String title, Exception e) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            title,
          ),
          content: Text(
            '${(e as dynamic).message}',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
