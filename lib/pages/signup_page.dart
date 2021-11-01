import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/models/authentication.dart';

class SignupPage extends StatelessWidget {
  SignupPage({Key? key}) : super(key: key);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authenticationModel = context.read(authenticationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIGN UP'),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextFormFieldRow(
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                placeholder: 'Email',
                prefix: const Icon(CupertinoIcons.mail),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              CupertinoTextFormFieldRow(
                autocorrect: false,
                controller: _passwordController,
                placeholder: 'Password',
                prefix: const Icon(CupertinoIcons.shield_fill),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              CupertinoTextFormFieldRow(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                placeholder: 'Name',
                prefix: const Icon(CupertinoIcons.profile_circled),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              CupertinoButton.filled(
                child: const Text('SIGN UP'),
                onPressed: () async {
                  bool success = await authenticationModel.signUp(
                    _emailController.text,
                    _nameController.text,
                    _passwordController.text,
                    (err) =>
                        _showErrorDialog(context, 'Failed to Sign Up', err),
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
