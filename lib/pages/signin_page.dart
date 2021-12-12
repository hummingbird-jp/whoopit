import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/pages/signup_page.dart';
import 'package:whoopit/states/authentication.dart';

class SigninPage extends ConsumerWidget {
  SigninPage({Key? key}) : super(key: key);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authModel = ref.read(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIGN IN'),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'email-form',
                child: CupertinoTextFormFieldRow(
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  prefix: const Icon(CupertinoIcons.mail),
                  placeholder: 'Email',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
              Hero(
                tag: 'password-form',
                child: CupertinoTextFormFieldRow(
                  autocorrect: false,
                  obscureText: true,
                  controller: _passwordController,
                  prefix: const Icon(CupertinoIcons.shield_fill),
                  placeholder: 'Password',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),
              Hero(
                tag: 'signin-button',
                child: CupertinoButton.filled(
                  child: const Text('SIGN IN'),
                  onPressed: () async {
                    bool success = await authModel.signIn(
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
              ),
              CupertinoButton(
                child: const Text('Don\'t have an account? Sign up here.'),
                onPressed: () => Navigator.push<Widget>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignupPage(),
                  ),
                ),
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
    showCupertinoDialog<void>(
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
