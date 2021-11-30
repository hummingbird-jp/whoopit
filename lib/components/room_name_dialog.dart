import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoomNameDialog extends StatelessWidget {
  const RoomNameDialog({
    Key? key,
    required GlobalKey<FormState> formKey,
    required CollectionReference<Map<String, dynamic>> roomsCollection,
    required this.roomId,
  })  : _formKey = formKey,
        _roomsCollection = roomsCollection,
        super(key: key);

  final GlobalKey<FormState> _formKey;
  final CollectionReference<Map<String, dynamic>> _roomsCollection;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('New Room Name'),
      content: Form(
        key: _formKey,
        child: CupertinoTextFormFieldRow(
          autofocus: true,
          autocorrect: false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Cannot be blank';
            }
            if (value.length > 20) {
              return 'Must be less than 20 characters';
            }
            if (value.contains(RegExp(r'[^a-zA-Z0-9]'))) {
              return 'Must contain only letters and numbers';
            }
            return null;
          },
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          onSaved: (value) {
            _roomsCollection.doc(roomId).update({'roomName': value});
          },
        ),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          isDestructiveAction: true,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.pop(context);
            }
          },
        ),
      ],
    );
  }
}
