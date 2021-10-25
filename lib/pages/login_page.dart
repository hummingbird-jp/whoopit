import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/pages/tabs_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                prefix: const Icon(CupertinoIcons.mail),
                placeholder: 'Email',
              ),
              CupertinoTextFormFieldRow(
                autocorrect: false,
                controller: _passwordController,
                prefix: const Icon(CupertinoIcons.shield_fill),
                placeholder: 'Password',
              ),
              CupertinoButton.filled(
                child: const Text('LOG IN'),
                onPressed: () async {
                  bool success = await _login(
                    _emailController.text,
                    _passwordController.text,
                    (e) => _showErrorDialog(context, 'Failed to log in', e),
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
  Future<bool> _login(
    String email,
    String password,
    void Function(FirebaseAuthException err) errorCallback,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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
