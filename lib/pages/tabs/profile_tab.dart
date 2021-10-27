import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/models/authentication.dart';
import 'package:whoopit/pages/signin_page.dart';
import 'package:whoopit/pages/signup_page.dart';

class ProfileTab extends HookWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Authentication authenticationModel =
        useProvider(authenticationProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: authenticationModel.isSignedIn,
            child: authenticationModel.isSignedIn
                ? Text(
                    'You\'re signed in as ${authenticationModel.user!.displayName}')
                : const Text(''),
          ),
          Visibility(
            visible: authenticationModel.isSignedIn,
            child: CupertinoButton(
              child: const Text(
                'LOG OUT',
                style: TextStyle(
                  color: CupertinoColors.destructiveRed,
                ),
              ),
              onPressed: () async {
                await authenticationModel.signOut();
              },
            ),
          ),
          Visibility(
            visible: !authenticationModel.isSignedIn,
            child: CupertinoButton.filled(
              child: const Text(
                'SIGN UP',
              ),
              onPressed: () => Navigator.push<Widget>(
                context,
                MaterialPageRoute(
                  builder: (context) => SignupPage(),
                ),
              ),
            ),
          ),
          Visibility(
            visible: !authenticationModel.isSignedIn,
            child: CupertinoButton(
              child: const Text(
                'SIGN IN',
              ),
              onPressed: () => Navigator.push<Widget>(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
