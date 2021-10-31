import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/models/authentication.dart';
import 'package:whoopit/pages/meeting_page.dart';

class MeetTab extends StatefulHookWidget {
  const MeetTab({Key? key}) : super(key: key);

  @override
  State<MeetTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<MeetTab> {
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
            ////CupertinoTextFormFieldRow(
            ////  readOnly: !authenticationModel.isSignedIn,
            ////  controller: _channelController,
            ////  keyboardType: TextInputType.text,
            ////  autocorrect: false,
            ////  cursorColor: CupertinoTheme.of(context).primaryContrastingColor,
            ////  style: const TextStyle(color: Colors.white),
            ////  textCapitalization: TextCapitalization.none,
            ////  placeholder: 'Channel',
            ////  validator: (value) {
            ////    if (value!.isEmpty) {
            ////      return 'Enter a channel';
            ////    }
            ////    return null;
            ////  },
            ////),
            //const SizedBox(height: 24),
            // Create button
            CupertinoButton.filled(
              child: authenticationModel.isSignedIn
                  ? const Text('CREATE')
                  : Text(
                      'Sign In to Create',
                      style: TextStyle(
                        color: CupertinoTheme.of(context).primaryColor,
                      ),
                    ),
              // Enable when signed in
              onPressed: authenticationModel.isSignedIn
                  ? () {
                      channelName = _getRandomString(10);
                      log('channelName: $channelName');
                      Navigator.push<Widget>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MeetingPage(),
                        ),
                      );
                    }
                  : null,
            ),
            // Join button
            CupertinoButton(
              child: const Text('JOIN'),
              // Enable when signed in
              onPressed: null,
              //onPressed: () {
              //if (_formKey.currentState!.validate()) {
              //  FocusScope.of(context).unfocus();
              //  channelName = _channelController.text;
              //  Navigator.push<Widget>(
              //    context,
              //    MaterialPageRoute(
              //      builder: (context) => const MeetingPage(),
              //    ),
              //  );
              //} else {
              //  log('Channel is empty.');
              //}
              //},
            ),
          ],
        ),
      ),
    );
  }

  String _getRandomString(int length) {
    const String _alphaNum =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final math.Random _random = math.Random();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _alphaNum.codeUnitAt(
          _random.nextInt(_alphaNum.length),
        ),
      ),
    );
  }
}
