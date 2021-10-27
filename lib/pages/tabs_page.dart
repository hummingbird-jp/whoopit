import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/pages/tabs/browse_tab.dart';
import 'package:whoopit/pages/tabs/home_tab.dart';
import 'package:whoopit/pages/tabs/profile_tab.dart';
import 'package:whoopit/pages/tabs/settings_tab.dart';

class TabsPage extends StatefulWidget {
  const TabsPage({Key? key}) : super(key: key);

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  final List<Widget> _tabs = [
    const HomeTab(),
    const BrowseTab(),
    const ProfileTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
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
        ),
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.heart_fill),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.square_grid_2x2_fill),
                label: 'Browse',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.profile_circled),
                label: 'Profile',
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
