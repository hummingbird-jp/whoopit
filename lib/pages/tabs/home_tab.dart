import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/pages/meeting_page.dart';

class HomeTab extends StatefulWidget {
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoTextFormFieldRow(
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
              child: const Text('JOIN'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  FocusScope.of(context).unfocus();
                  Navigator.push<Widget>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MeetingPage(),
                    ),
                  );
                } else {
                  log('Channel is empty.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
