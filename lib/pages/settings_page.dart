import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:flutterfire_ui/firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TextEditingController emojiController = TextEditingController();
  TextEditingController interestController = TextEditingController();
  bool emojiShowing = false;

  @override
  Widget build(BuildContext context) {
    CupertinoThemeData theme = CupertinoTheme.of(context);
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    DocumentReference user = users.doc(FirebaseAuth.instance.currentUser!.uid);
    CollectionReference interests = user.collection('interests');

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const UserAvatar(),
                    const SizedBox(height: 64),
                    _buildYourInterestsList(interests),
                    const SizedBox(height: 24),
                    _buildAddInterestField(theme),
                  ],
                ),
              ),
            ),
            // Leave this here for now
            _buildEmojiPicker(theme),
          ],
        ),
      ),
    );
  }

  Row _buildAddInterestField(CupertinoThemeData theme) {
    return Row(
      children: [
        _buildInputField(theme),
        _buildAddInterestButton(theme),
      ],
    );
  }

  SizedBox _buildYourInterestsList(CollectionReference<Object?> interests) {
    return SizedBox(
      height: 40,
      child: FirestoreListView(
        scrollDirection: Axis.horizontal,
        query: interests.orderBy('timestamp', descending: true),
        itemBuilder: (context, snapshot) {
          final interest = snapshot.data() as Map<String, dynamic>;

          if (!snapshot.exists) {
            return const Text('No interests found. Add some!');
          }

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4.0,
              vertical: 8.0,
            ),
            child: GestureDetector(
              onLongPress: () {
                interests.doc(snapshot.id).delete();
                HapticFeedback.heavyImpact();
              },
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                HapticFeedback.lightImpact();
                showCupertinoDialog<CupertinoAlertDialog>(
                    context: context,
                    builder: (_) {
                      return CupertinoAlertDialog(
                        title: const Text('Delete?'),
                        content:
                            const Text('Tips: You can delete by long-press!'),
                        actions: [
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: const Text('Delete'),
                            onPressed: () {
                              interests.doc(snapshot.id).delete();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
              child: Container(
                height: 24,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: Colors.grey.withOpacity(0.3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Text(
                    '${interest['emoji']} ${interest['content']}',
                    style: const TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddInterestButton(CupertinoThemeData theme) {
    return TextButton(
      onPressed: () =>
          _addInterest(emojiController.text, interestController.text),
      child: Icon(
        CupertinoIcons.add,
        color: theme.primaryContrastingColor,
      ),
    );
  }

  Widget _buildInputField(CupertinoThemeData theme) {
    return SizedBox(
      width: 272,
      child: CupertinoTextFormFieldRow(
        controller: interestController,
        prefix: GestureDetector(
          child: Text(
            emojiController.text == '' ? '🙃' : emojiController.text,
            style: const TextStyle(fontSize: 32.0),
          ),
          onTap: () => setState(
            () {
              emojiShowing = !emojiShowing;
              FocusManager.instance.primaryFocus?.unfocus();
            },
          ),
        ),
        onTap: () => setState(() => emojiShowing = false),
        showCursor: true,
        cursorColor: theme.primaryContrastingColor,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE0E0E0),
              width: 0.0,
            ),
          ),
        ),
        onSaved: (_) {
          if (interestController.text.isNotEmpty) {
            _addInterest(emojiController.text, interestController.text);
          }
        },
        placeholder: 'What are you interested in?',
        placeholderStyle: TextStyle(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }

  Material _buildEmojiPicker(CupertinoThemeData theme) {
    return Material(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: emojiShowing ? 300 : 0,
        curve: Curves.easeOut,
        child: EmojiPicker(
          onEmojiSelected: (_, emoji) => _onEmojiSelected(emoji),
          onBackspacePressed: _onBackspacePressed,
          config: Config(
            // Issue: https://github.com/flutter/flutter/issues/28894
            emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
            indicatorColor: theme.primaryColor,
            iconColorSelected: theme.primaryColor,
            progressIndicatorColor: theme.primaryColor,
            backspaceColor: theme.primaryColor,
            buttonMode: ButtonMode.CUPERTINO,
          ),
        ),
      ),
    );
  }

  void _onEmojiSelected(Emoji emoji) {
    setState(() {
      emojiController
        ..text = emoji.emoji
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: emojiController.text.length),
        );
    });
  }

  void _onBackspacePressed() {
    setState(() {
      emojiController
        ..text = emojiController.text.characters.skipLast(1).toString()
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: emojiController.text.length),
        );
    });
  }

  void _addInterest(String emoji, String content) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    DocumentReference user = users.doc(FirebaseAuth.instance.currentUser!.uid);
    CollectionReference interests = user.collection('interests');

    try {
      interests.add({
        'emoji': emoji == '' ? '🙃' : emoji,
        'content': content,
        'timestamp': Timestamp.now(),
      });
      HapticFeedback.lightImpact();
    } on Exception {
      // TODO
    }

    interestController.clear();
  }
}
