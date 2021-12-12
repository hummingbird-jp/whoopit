import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/states/authentication.dart';

class SignupPage extends ConsumerWidget {
  SignupPage({Key? key}) : super(key: key);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authModel = ref.read(authProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('SIGN UP'),
      ),
      child: SafeArea(
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
                  placeholder: 'Email',
                  prefix: const Icon(CupertinoIcons.mail),
                ),
              ),
              Hero(
                tag: 'password-form',
                child: CupertinoTextFormFieldRow(
                  autocorrect: false,
                  obscureText: true,
                  controller: _passwordController,
                  placeholder: 'Password',
                  prefix: const Icon(CupertinoIcons.shield_fill),
                ),
              ),
              CupertinoTextFormFieldRow(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                placeholder: 'Name',
                prefix: const Icon(CupertinoIcons.profile_circled),
              ),
              Hero(
                tag: 'signin-button',
                child: CupertinoButton.filled(
                  child: const Text('SIGN UP'),
                  onPressed: () async {
                    bool success = await authModel.signUp(
                      _emailController.text,
                      _nameController.text,
                      _passwordController.text,
                      (err) =>
                          _showErrorDialog(context, 'Failed to Sign Up', err),
                    );

                    if (success) {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  },
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
