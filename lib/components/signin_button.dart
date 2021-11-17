import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/pages/signin_page.dart';

class SigninButton extends StatelessWidget {
  const SigninButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Hero(
        tag: 'signin-button',
        child: CupertinoButton.filled(
          child: const Text('SIGN IN'),
          onPressed: () => Navigator.push<Widget>(
            context,
            MaterialPageRoute(builder: (context) => SigninPage()),
          ),
        ),
      ),
    );
  }
}
