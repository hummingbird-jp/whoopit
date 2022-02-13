import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/components/participant_circle.dart';
import 'package:whoopit/pages/settings_page.dart';
import 'package:whoopit/states/audio_state.dart';
import 'package:whoopit/states/authentication_state.dart';
import 'package:whoopit/states/room_state.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthenticationState authState = ref.watch(authProvider);
    final RoomState roomState = ref.watch(roomProvider);
    final AudioState audioState = ref.watch(audioProvider);

    return WillPopScope(
      onWillPop: () async => false,
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          trailing: GestureDetector(
            onTap: () {
              showCupertinoModalPopup<void>(
                context: context,
                builder: (context) => CupertinoActionSheet(
                  message: Text(
                    'You\'re signed in as ${authState.displayName}',
                  ),
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                        Navigator.push<Widget>(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const SettingsPage(),
                            //builder: (context) => const ProfileScreen(
                            //  providerConfigs: providerConfigs,
                            //),
                          ),
                        );
                      },
                      child: const Text('Settings'),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              );
            },
            child: authState.photoUrl != null
                ? CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      authState.photoUrl.toString(),
                    ),
                    radius: 20,
                  )
                : const Icon(CupertinoIcons.profile_circled),
          ),
        ),
        child: Padding(
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
              buildRoomTileList(roomState, audioState),
            ],
          ),
        ),
      ),
    );
  }

  StreamBuilder<QuerySnapshot> buildRoomTileList(
    RoomState roomState,
    AudioState audioState,
  ) {
    final CollectionReference<Map<String, dynamic>> _roomsCollection =
        FirebaseFirestore.instance.collection('rooms');
    final Stream<QuerySnapshot> _roomsStream = _roomsCollection.snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: _roomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 20.0,
              runSpacing: 20.0,
              children: snapshot.data!.docs.map((doc) {
                final Map<String, dynamic> data =
                    doc.data() as Map<String, dynamic>;
                final String _roomId = doc.id;
                final String _roomName = data['roomName'] as String;

                return buildRoomTile(
                  context,
                  roomState,
                  audioState,
                  _roomsCollection,
                  _roomId,
                  _roomName,
                );
              }).toList(),
            ),
            const SizedBox(height: 20.0),
            CupertinoButton(
              color: Colors.white.withOpacity(0.07),
              child: Icon(
                CupertinoIcons.add,
                color: Colors.white.withOpacity(0.5),
              ),
              onPressed: () => roomState.create(
                context,
                audioState,
                _getRandomString(15),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildRoomTile(
    BuildContext context,
    RoomState roomState,
    AudioState audioState,
    CollectionReference<Map<String, dynamic>> roomsCollection,
    String roomId,
    String roomName,
  ) {
    final Stream<QuerySnapshot> _participantsStream =
        roomsCollection.doc(roomId).collection('participants').snapshots();

    return GestureDetector(
      onTap: () => roomState.join(context, roomId, audioState),
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
                    child: SizedBox(
                      height: 24,
                      child: Text(
                        roomName,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: 60,
                      child: StreamBuilder<QuerySnapshot>(
                        // Cannot use participantStream in RoomState because it is not initialized at this point
                        stream: _participantsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Text('Something went wrong');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
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
                              spacing: 0,
                              children: snapshot.data!.docs.map((doc) {
                                final Map<String, dynamic> data =
                                    doc.data() as Map<String, dynamic>;
                                final String photoUrl =
                                    data['photoUrl'] as String;
                                final bool isJoined = data['isJoined'] as bool;

                                return ParticipantCircle(
                                  photoUrl: photoUrl,
                                  size: 20,
                                  isJoined: isJoined,
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 16.0,
                        right: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => showCupertinoModalPopup<void>(
                              context: context,
                              builder: (context) => CupertinoActionSheet(
                                message: const Text(
                                  'Delete room?',
                                ),
                                actions: [
                                  CupertinoActionSheetAction(
                                    isDestructiveAction: true,
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context);
                                      roomState.delete(roomId);
                                    },
                                    child: const Text('Continue'),
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.trash,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
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
