import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/components/authentication.dart';
import 'package:whoopit/pages/login_page.dart';
import 'package:whoopit/pages/tabs_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({Key? key, required this.loginState}) : super(key: key);

  final ApplicationLoginState loginState;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push<Widget>(
          context,
          MaterialPageRoute(
            builder: (context) => loginState == ApplicationLoginState.loggedIn
                ? const TabsPage()
                : const LoginPage(),
          ),
        );
      },
      child: CupertinoPageScaffold(
        child: Center(
          child: Text(
            'Whoopit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 48,
              color: CupertinoTheme.of(context).primaryContrastingColor,
            ),
          ),
        ),
      ),
    );
  }
}
