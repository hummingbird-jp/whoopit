import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/models/authentication.dart';
import 'package:whoopit/pages/signin_page.dart';
import 'package:whoopit/pages/tabs/settings_tab.dart';

import 'meeting_page.dart';

class HomePage extends StatefulHookWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _TabsPageState();
}

class _TabsPageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final Authentication authenticationModel =
        useProvider(authenticationProvider);

    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          trailing: GestureDetector(
            onTap: () {
              showCupertinoModalPopup<void>(
                context: context,
                builder: (context) => CupertinoActionSheet(
                  message: authenticationModel.isSignedIn
                      ? Text(
                          'You\'re signed in as ${authenticationModel.user!.displayName}',
                        )
                      : null,
                  actions: [
                    authenticationModel.isSignedIn
                        ? CupertinoActionSheetAction(
                            isDestructiveAction: true,
                            isDefaultAction: true,
                            onPressed: () {
                              authenticationModel.signOut();
                              Navigator.pop(context);
                            },
                            child: const Text('Sign Out'),
                          )
                        : CupertinoActionSheetAction(
                            isDefaultAction: true,
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push<Widget>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SigninPage(),
                                ),
                              );
                            },
                            child: const Text('Sign In'),
                          ),
                    CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.push<Widget>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsTab(),
                          ),
                        );
                      },
                      child: const Text('Settings'),
                    ),
                    // TODO: Implement 'Update Profile' button
                    //CupertinoActionSheetAction(
                    //  onPressed: () {},
                    //  child: const Text('Update Profile'),
                    //),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              );
            },
            child: const Icon(CupertinoIcons.profile_circled),
          ),
        ),
        child: CupertinoPageScaffold(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              children: [
                SizedBox(
                  height: 400,
                  child: Center(
                    child: Text(
                      'Whoopit',
                      style: TextStyle(
                        color:
                            CupertinoTheme.of(context).primaryContrastingColor,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'What\'s Whoopit?',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.right_chevron,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20.0,
                  runSpacing: 20.0,
                  children: [
                    GestureDetector(
                      onTap: () => _onJoin('roomA'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          width: 160.0,
                          height: 160.0,
                          color: Colors.white.withOpacity(0.07),
                          child: const Align(
                            alignment: Alignment(-0.70, -0.70),
                            child: Text('Room A'),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onJoin('roomB'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          width: 160.0,
                          height: 160.0,
                          color: Colors.white.withOpacity(0.07),
                          child: const Align(
                            alignment: Alignment(-0.70, -0.70),
                            child: Text('Room B'),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onJoin(_getRandomString(10)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Container(
                          width: 160.0,
                          height: 160.0,
                          color: Colors.white.withOpacity(0.07),
                          child: const Align(
                            alignment: Alignment(-0.70, -0.70),
                            child: Text('Create'),
                          ),
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        width: 160.0,
                        height: 160.0,
                        color: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onJoin(String newChannelName) {
    channelName = newChannelName;
    log('channelName: $channelName');
    Navigator.push<Widget>(
      context,
      MaterialPageRoute(
        builder: (context) => const MeetingPage(),
      ),
    );
  }

  String _getRandomString(int length) {
    const String _alphaNum =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final math.Random _random = math.Random();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _alphaNum.codeUnitAt(
          _random.nextInt(_alphaNum.length),
        ),
      ),
    );
  }
}
