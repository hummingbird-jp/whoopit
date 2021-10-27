import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            showAboutDialog(
              context: context,
              applicationVersion: '1.0.1',
              applicationIcon: const Icon(CupertinoIcons.airplane),
              applicationName: 'Whoopit',
              applicationLegalese: 'Yeah yeah yeah.',
            );
          },
          child: const Text(
            'About Whoopit',
          ),
        ),
        const Text('XXX'),
      ],
    );
  }
}
