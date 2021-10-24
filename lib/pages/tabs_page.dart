import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gtk_flutter/pages/tabs/browse_tab.dart';
import 'package:gtk_flutter/pages/tabs/home_tab.dart';
import 'package:gtk_flutter/pages/tabs/profile_tab.dart';
import 'package:gtk_flutter/pages/tabs/search_tab.dart';

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
    const SearchTab(),
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
                icon: Icon(CupertinoIcons.search),
                label: 'Search',
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
