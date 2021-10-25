import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/pages/login_page.dart';
import 'package:whoopit/pages/signup_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: Text(
          'Whoopit',
          style: TextStyle(
            color: CupertinoTheme.of(context).primaryContrastingColor,
          ),
        ),
      ),
      child: Material(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        textStyle: const TextStyle(
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton.filled(
                child: const Text('SIGN UP'),
                onPressed: () => Navigator.push<Widget>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignupPage(),
                  ),
                ),
              ),
              CupertinoButton(
                child: const Text('LOG IN'),
                onPressed: () => Navigator.push<Widget>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
