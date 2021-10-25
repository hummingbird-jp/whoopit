import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/pages/welcome_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoButton(
        color: CupertinoColors.destructiveRed,
        child: const Text(
          'LOG OUT',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        onPressed: () {
          FirebaseAuth.instance.signOut();
          Navigator.push<Widget>(
            context,
            MaterialPageRoute(
              builder: (context) => const WelcomePage(),
            ),
          );
        },
      ),
    );
  }
}
