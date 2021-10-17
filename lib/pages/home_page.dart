import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gtk_flutter/pages/meeting_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Whoopit',
          style: TextStyle(
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
      ),
      child: Center(
        child: CupertinoButton.filled(
          child: const Text('JOIN'),
          onPressed: () {
            Navigator.push<Widget>(
              context,
              MaterialPageRoute<Widget>(
                builder: (context) => const MeetingPage(),
              ),
            );
          },
        ),
      ),
    );
  }
}
