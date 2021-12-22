import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:giphy_get/giphy_get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:whoopit/components/cheers.dart';
import 'package:whoopit/components/full_screen_activity_indicator.dart';
import 'package:whoopit/components/participant_circle.dart';
import 'package:whoopit/components/pill_button.dart';
import 'package:whoopit/components/share_room_url_button.dart';
import 'package:whoopit/states/audio_state.dart';
import 'package:whoopit/states/room_state.dart';

class RoomPage extends HookConsumerWidget {
  const RoomPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RoomState roomState = ref.watch(roomProvider);
    final AudioState audioState = ref.watch(audioProvider);

    return WillPopScope(
      onWillPop: () async => false,
      child: StreamBuilder<QuerySnapshot>(
        stream: roomState.shakersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: CupertinoTheme.of(context).scaffoldBackgroundColor,
              child: const CupertinoActivityIndicator(),
            );
          }

          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              //backgroundColor:
              //    snapshot.hasData && snapshot.data!.docs.length >= 2
              //        ? Theme.of(context).colorScheme.secondary
              //        : Theme.of(context).colorScheme.background,
              automaticallyImplyLeading: false,
              middle: GestureDetector(
                onTap: () => roomState.onRoomNameTapped(context),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: roomState.roomStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CupertinoActivityIndicator();
                    }

                    Map<String, dynamic>? data = snapshot.data!.data();
                    return Text(
                      data?['roomName'] as String? ?? roomState.roomId,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                      ),
                    );
                  },
                ),
              ),
            ),
            //backgroundColor: snapshot.hasData && snapshot.data!.docs.length >= 2
            //    ? Theme.of(context).colorScheme.secondary
            //    : Theme.of(context).colorScheme.background,
            child: SafeArea(
              child: Stack(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: roomState.participantsStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CupertinoActivityIndicator();
                      }

                      return Center(
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          direction: Axis.horizontal,
                          spacing: 20,
                          runSpacing: 40,
                          children: snapshot.data!.docs.map((doc) {
                            final Map<String, dynamic> data =
                                doc.data() as Map<String, dynamic>;
                            final String? name = data['name'] as String;
                            final String photoUrl = data['photoUrl'] as String;
                            final bool isMuted = data['isMuted'] as bool;
                            final int shakeCount = data['shakeCount'] as int;
                            final bool isClapping = data['isClapping'] as bool;
                            final bool isMe =
                                data['firebaseUid'] == roomState.me.firebaseUid;
                            String? currentGifUrl = data['gifUrl'] as String?;
                            final bool isJoined = data['isJoined'] as bool;

                            if (shakeCount >= 10) {
                              HapticFeedback.vibrate();
                              // TODO: Play boom sound
                            }

                            return GestureDetector(
                              onTap: () async {
                                if (isMe) {
                                  if (currentGifUrl == null) {
                                    GiphyGif? _newGif = await GiphyGet.getGif(
                                      context: context,
                                      apiKey:
                                          'zS43gpI1tyh32oBapKuwt7vNXz7PMoOe',
                                      lang: GiphyLanguage.english,
                                      tabColor: CupertinoTheme.of(context)
                                          .primaryColor,
                                    );
                                    currentGifUrl =
                                        _newGif?.images!.original!.webp;

                                    roomState.myParticipantDocument.update({
                                      'gifUrl': currentGifUrl,
                                    });
                                  } else {
                                    roomState.myParticipantDocument.update({
                                      'gifUrl': null,
                                    });
                                  }
                                } else {
                                  log('Ignored because it\'s not you');
                                }
                              },
                              child: ParticipantCircle(
                                photoUrl: photoUrl,
                                name: name,
                                isMuted: isMuted,
                                shakeCount: shakeCount,
                                isClapping: isClapping,
                                gifUrl: currentGifUrl,
                                isJoined: isJoined,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: const Alignment(0.00, 0.60),
                    child: ShareRoomUrlButton(
                      roomId: roomState.roomId,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          PillButton(
                            child: const Text('👋 Leave'),
                            color: CupertinoTheme.of(context).primaryColor,
                            onPressed: () => roomState.leave(
                              context,
                              audioState,
                            ),
                          ),
                          PillButton(
                            child: const Text('👏'),
                            color: CupertinoTheme.of(context).primaryColor,
                            onPressed: () {
                              if (roomState.isMeClapping) {
                                log('Ignoring because already clapping');
                              } else {
                                roomState.clap();
                              }
                            },
                          ),
                          PillButton(
                            child: roomState.isMuted
                                ? const Text('Unmute')
                                : const Text('Mute'),
                            color: roomState.isMuted
                                ? CupertinoTheme.of(context)
                                    .primaryContrastingColor
                                : CupertinoTheme.of(context).primaryColor,
                            onPressed: roomState.mute,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Cheers(shakersStream: roomState.shakersStream),
                  FullScreenActivityIndicator(
                    isLoading: roomState.isMeJoinInProgress ||
                        roomState.isMeLeaveInProgress,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
