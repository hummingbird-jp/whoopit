import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/models/authentication.dart';
import 'package:whoopit/pages/signin_page.dart';
import 'package:whoopit/pages/tabs/browse_tab.dart';
import 'package:whoopit/pages/tabs/home_tab.dart';
import 'package:whoopit/pages/tabs/meet_tab.dart';
import 'package:whoopit/pages/tabs/settings_tab.dart';

class TabsPage extends StatefulHookWidget {
  const TabsPage({Key? key}) : super(key: key);

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  final List<Widget> _tabs = [
    const HomeTab(),
    const MeetTab(),
    const BrowseTab(),
    //const ProfileTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final Authentication authenticationModel =
        useProvider(authenticationProvider);

    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          middle: Text(
            'Whoopit',
            style: TextStyle(
              color: CupertinoTheme.of(context).primaryContrastingColor,
            ),
          ),
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
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.heart_fill),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.phone_fill),
                label: 'Meet',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.square_grid_2x2_fill),
                label: 'Browse',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                label: 'Settings',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            return _tabs[index];
          },
        ),
      ),
    );
  }
}
