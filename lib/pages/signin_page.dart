import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/models/authentication.dart';

class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authenticationModel = context.read(authenticationProvider);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextFormFieldRow(
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                prefix: const Icon(CupertinoIcons.mail),
                placeholder: 'Email',
              ),
              CupertinoTextFormFieldRow(
                autocorrect: false,
                controller: _passwordController,
                prefix: const Icon(CupertinoIcons.shield_fill),
                placeholder: 'Password',
              ),
              CupertinoButton.filled(
                child: const Text('SIGN IN'),
                onPressed: () async {
                  bool success = await authenticationModel.signIn(
                    _emailController.text,
                    _passwordController.text,
                    (err) =>
                        _showErrorDialog(context, 'Failed to Sign In', err),
                  );

                  if (success) {
                    Navigator.pop(context);
                  }
                },
              ),
              CupertinoButton(
                child: const Icon(CupertinoIcons.arrow_left),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, Exception e) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            title,
          ),
          content: Text(
            '${(e as dynamic).message}',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
