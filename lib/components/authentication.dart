import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gtk_flutter/pages/home_page.dart';
import 'package:gtk_flutter/pages/meeting_tab.dart';

enum ApplicationLoginState {
  loggedOut,
  emailAddress,
  register,
  password,
  loggedIn,
}

class Authentication extends StatelessWidget {
  const Authentication({
    required this.loginState,
    required this.email,
    required this.startLoginFlow,
    required this.verifyEmail,
    required this.signInWithEmailAndPassword,
    required this.cancelRegistration,
    required this.registerAccount,
    required this.signOut,
  });

  final ApplicationLoginState loginState;
  final String? email;
  final void Function() startLoginFlow;
  final void Function(
    String email,
    void Function(Exception e) error,
  ) verifyEmail;
  final void Function(
    String email,
    String password,
    void Function(Exception e) error,
  ) signInWithEmailAndPassword;
  final void Function() cancelRegistration;
  final void Function(
    String email,
    String displayName,
    String password,
    void Function(Exception e) error,
  ) registerAccount;
  final void Function() signOut;

  @override
  Widget build(BuildContext context) {
    switch (loginState) {
      case ApplicationLoginState.loggedOut:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 72),
            CupertinoButton.filled(
              onPressed: () {
                startLoginFlow();
              },
              child: const Text('SIGN UP'),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              onPressed: () {
                startLoginFlow();
              },
              child: const Text('SIGN IN'),
            ),
          ],
        );
      case ApplicationLoginState.emailAddress:
        return EmailForm(
          callback: (email) => verifyEmail(
            email,
            (e) => _showErrorDialog(context, 'Invalid email', e),
          ),
        );
      case ApplicationLoginState.password:
        return PasswordForm(
          email: email!,
          login: (email, password) {
            signInWithEmailAndPassword(
              email,
              password,
              (e) => _showErrorDialog(context, 'Failed to sign in', e),
            );
          },
        );
      case ApplicationLoginState.register:
        return RegisterForm(
          email: email!,
          cancel: () {
            cancelRegistration();
          },
          registerAccount: (
            email,
            displayName,
            password,
          ) {
            registerAccount(
              email,
              displayName,
              password,
              (e) => _showErrorDialog(context, 'Failed to create account', e),
            );
          },
        );
      case ApplicationLoginState.loggedIn:
        return Column(
          children: [
            CupertinoButton.filled(
              child: const Text('JOIN'),
              onPressed: () {
                Navigator.push<Widget>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              },
            ),
            CupertinoButton(
              onPressed: () {
                signOut();
              },
              child: const Text(
                'Log out',
                style: TextStyle(
                  color: CupertinoColors.destructiveRed,
                ),
              ),
            ),
          ],
        );
      default:
        return Row(
          children: const [
            Text("Uncaught error. Please contact us."),
          ],
        );
    }
  }

  void _showErrorDialog(BuildContext context, String title, Exception e) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(
            title,
            //style: const TextStyle(fontSize: 24),
          ),
          content: Text(
            '${(e as dynamic).message}',
            //style: const TextStyle(fontSize: 18),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class EmailForm extends StatefulWidget {
  const EmailForm({required this.callback});
  final void Function(String email) callback;
  @override
  _EmailFormState createState() => _EmailFormState();
}

class _EmailFormState extends State<EmailForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_EmailFormState');
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoTextFormFieldRow(
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    cursorColor:
                        CupertinoTheme.of(context).primaryContrastingColor,
                    style: const TextStyle(color: Colors.white),
                    textCapitalization: TextCapitalization.none,
                    placeholder: 'Email',
                    prefix: const Icon(CupertinoIcons.mail_solid),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your email address to continue';
                      }
                      return null;
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 16.0, right: 24, left: 24),
                      child: CupertinoButton.filled(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            widget.callback(_controller.text);
                          }
                        },
                        child: const Text('NEXT'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    required this.registerAccount,
    required this.cancel,
    required this.email,
  });
  final String email;
  final void Function(String email, String displayName, String password)
      registerAccount;
  final void Function() cancel;
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_RegisterFormState');
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoTextFormFieldRow(
                    controller: _emailController,
                    autocorrect: false,
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Icon(CupertinoIcons.mail_solid),
                    placeholder: 'Email',
                    style: const TextStyle(color: Colors.white),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your email address to continue';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoTextFormFieldRow(
                    controller: _displayNameController,
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                    prefix: const Icon(CupertinoIcons.profile_circled),
                    style: const TextStyle(color: Colors.white),
                    placeholder: 'First & Last Name',
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your account name';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoTextFormFieldRow(
                    controller: _passwordController,
                    autocorrect: false,
                    prefix: const Icon(CupertinoIcons.lock_fill),
                    placeholder: 'New Password',
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.cancel,
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 16),
                      CupertinoButton.filled(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            widget.registerAccount(
                              _emailController.text,
                              _displayNameController.text,
                              _passwordController.text,
                            );
                          }
                        },
                        child: const Text('SAVE'),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PasswordForm extends StatefulWidget {
  const PasswordForm({
    required this.login,
    required this.email,
  });
  final String email;
  final void Function(String email, String password) login;
  @override
  _PasswordFormState createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_PasswordFormState');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoTextFormFieldRow(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    placeholder: 'Email',
                    prefix: const Icon(CupertinoIcons.mail_solid),
                    autocorrect: false,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your email address to continue';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoTextFormFieldRow(
                    controller: _passwordController,
                    keyboardType: TextInputType.text,
                    prefix: const Icon(CupertinoIcons.lock_fill),
                    placeholder: 'Password',
                    style: const TextStyle(color: Colors.white),
                    autocorrect: false,
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 16),
                      CupertinoButton.filled(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            widget.login(
                              _emailController.text,
                              _passwordController.text,
                            );
                            Navigator.push<Widget>(
                              context,
                              MaterialPageRoute<Widget>(
                                builder: (context) => const MeetingTab(),
                              ),
                            );
                          }
                        },
                        child: const Text('SIGN IN'),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
