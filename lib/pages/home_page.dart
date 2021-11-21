import 'dart:developer';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/components/participant_circle.dart';
import 'package:whoopit/components/signin_button.dart';
import 'package:whoopit/models/authentication.dart';
import 'package:whoopit/pages/profile_page.dart';
import 'package:whoopit/pages/signin_page.dart';

import 'room_page.dart';

class HomePage extends StatefulHookWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _TabsPageState();
}

class _TabsPageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final Authentication authModel = useProvider(authProvider);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            GestureDetector(
              onTap: () {
                showCupertinoModalPopup<void>(
                  context: context,
                  builder: (context) => authModel.isSignedIn
                      ? CupertinoActionSheet(
                          message: Text(
                            'You\'re signed in as ${authModel.displayName}',
                          ),
                          actions: [
                            CupertinoActionSheetAction(
                              isDestructiveAction: true,
                              isDefaultAction: true,
                              onPressed: () {
                                authModel.signOut();
                                Navigator.pop(context);
                              },
                              child: const Text('Sign Out'),
                            ),
                            CupertinoActionSheetAction(
                              onPressed: _onUpdateProfile,
                              child: const Text('Update Profile'),
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        )
                      : CupertinoActionSheet(
                          actions: [
                            CupertinoActionSheetAction(
                              isDefaultAction: true,
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push<Widget>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SigninPage(),
                                  ),
                                );
                              },
                              child: const Text('Sign In'),
                            ),
                          ],
                          cancelButton: CupertinoActionSheetAction(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                );
              },
              child: Hero(
                tag: 'profile',
                child: authModel.photoUrl != null
                    ? CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                          authModel.photoUrl.toString(),
                        ),
                        radius: 20,
                      )
                    : const Icon(CupertinoIcons.profile_circled),
              ),
            ),
            const SizedBox(width: 24.0),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              const SizedBox(
                height: 320,
                child: Center(
                  child: Text(
                    'Whoopit',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!authModel.isSignedIn)
                const SigninButton()
              else
                buildRoomTileList(),
            ],
          ),
        ),
      ),
    );
  }

  Wrap buildRoomTileList() {
    CollectionReference<Map<String, dynamic>> roomsRef =
        FirebaseFirestore.instance.collection('rooms');

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20.0,
      runSpacing: 20.0,
      children: [
        buildRoomTile(roomsRef, 'roomA', 'Room A'),
        buildRoomTile(roomsRef, 'roomB', 'Room B'),
        buildRoomTile(roomsRef, _getRandomString(10), 'Create'),
        ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Container(
            width: 160.0,
            height: 160.0,
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }

  Widget buildRoomTile(
    CollectionReference<Map<String, dynamic>> roomsRef,
    String roomId,
    String roomName,
  ) {
    final Stream<QuerySnapshot> _participantsStream =
        roomsRef.doc(roomId).collection('participants').snapshots();

    return GestureDetector(
      onTap: () => _onJoin(roomId),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Stack(
          children: [
            Container(
              width: 160.0,
              height: 160.0,
              color: Colors.white.withOpacity(0.07),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    // TODO: Make roomName to listen to the roomName field
                    child: Text(
                      roomName,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: _participantsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Something went wrong');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CupertinoActivityIndicator(),
                        );
                      }

                      return Align(
                        alignment: Alignment.center,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          direction: Axis.horizontal,
                          spacing: 10.0,
                          children: snapshot.data!.docs.map((doc) {
                            final Map<String, dynamic> data =
                                doc.data() as Map<String, dynamic>;
                            final String photoUrl = data['photoUrl'] as String;

                            return ParticipantCircle(
                              photoUrl: photoUrl,
                              size: 20,
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onJoin(String newChannelName) {
    roomId = newChannelName;
    HapticFeedback.lightImpact();
    log('channelName: $roomId');

    Navigator.push<Widget>(
      context,
      MaterialPageRoute(
        builder: (context) => const RoomPage(),
      ),
    );
  }

  void _onUpdateProfile() {
    HapticFeedback.lightImpact();
    Navigator.pop(context);
    Navigator.push<Widget>(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
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
