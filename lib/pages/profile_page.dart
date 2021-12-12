import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whoopit/states/authentication.dart';

class ProfilePage extends HookConsumerWidget {
  ProfilePage({Key? key}) : super(key: key);

  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Authentication authModel = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  XFile? pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);

                  if (pickedFile != null) {
                    String filePath = pickedFile.path;
                    File file = File(filePath);

                    try {
                      await FirebaseStorage.instance
                          .ref()
                          .child('profile_images')
                          .child(authModel.uid)
                          .child('profile_image')
                          .putFile(file);

                      authModel.updatePhotoURL(
                        await FirebaseStorage.instance
                            .ref()
                            .child('profile_images')
                            .child(authModel.uid)
                            .child('profile_image')
                            .getDownloadURL(),
                      );
                    } on FirebaseException catch (e) {
                      log('Error on Firebase: $e');
                    }
                  }
                },
                child: authModel.photoUrl != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                              authModel.photoUrl.toString(),
                            ),
                            radius: 50,
                          ),
                          CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            radius: 50,
                          ),
                          const Icon(
                            CupertinoIcons.pencil,
                            size: 30,
                          ),
                        ],
                      )
                    : const Icon(CupertinoIcons.profile_circled, size: 100),
              ),
              const SizedBox(height: 24),
              CupertinoTextFormFieldRow(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                placeholder: 'New Name',
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              CupertinoButton.filled(
                child: const Text('Update'),
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    authModel.updateUserInfo(
                      newDisplayName: _nameController.text,
                    );
                    Navigator.pop(context);
                  } else {
                    showCupertinoDialog<void>(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Please enter a name'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            isDefaultAction: true,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
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
}
