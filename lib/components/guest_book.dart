import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:whoopit/components/paragraph.dart';

class GuestBookMessage {
  const GuestBookMessage({required this.name, required this.message});

  final String name;
  final String message;
}

enum Attending { yes, no, unknown }

class Chat extends StatefulWidget {
  const Chat({Key? key, required this.addMessage, required this.messages})
      : super(key: key);
  final Future<void> Function(String message) addMessage;
  final List<GuestBookMessage> messages;

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_GuestBookState');
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var message in widget.messages)
          Paragraph('${message.name}: ${message.message}'),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextFormFieldRow(
                    controller: _controller,
                    placeholder: 'Leave a message',
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your message to continue';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CupertinoButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await widget.addMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: const Icon(CupertinoIcons.arrow_up_circle_fill),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
