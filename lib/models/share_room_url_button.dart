import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareRoomUrlButton extends StatelessWidget {
  const ShareRoomUrlButton({
    Key? key,
    required this.roomId,
  }) : super(key: key);

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      child: const Text('Share to friends!'),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: roomId));
        Share.share(roomId);
      },
    );
  }
}
