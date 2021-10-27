import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/models/authentication.dart';
import 'package:whoopit/pages/meeting_page.dart';

class HomeTab extends StatefulHookWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: '_MeetingTabState');
  final TextEditingController _channelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Authentication authenticationModel =
        useProvider(authenticationProvider);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoTextFormFieldRow(
              readOnly: !authenticationModel.isSignedIn,
              controller: _channelController,
              keyboardType: TextInputType.text,
              autocorrect: false,
              cursorColor: CupertinoTheme.of(context).primaryContrastingColor,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.none,
              placeholder: 'Channel',
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Enter a channel';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              child: authenticationModel.isSignedIn
                  ? const Text(' JOIN')
                  : Text(
                      'Sign In to Join',
                      style: TextStyle(
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
              // Enable when signed in
              onPressed: authenticationModel.isSignedIn
                  ? () {
                      if (_formKey.currentState!.validate()) {
                        FocusScope.of(context).unfocus();
                        channelName = _channelController.text;
                        Navigator.push<Widget>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MeetingPage(),
                          ),
                        );
                      } else {
                        log('Channel is empty.');
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
