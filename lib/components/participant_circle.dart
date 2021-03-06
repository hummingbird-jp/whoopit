import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ParticipantCircle extends StatelessWidget {
  const ParticipantCircle({
    Key? key,
    this.participantRef,
    required this.photoUrl,
    this.name,
    this.isMuted,
    this.shakeCount,
    this.isClapping,
    this.size = 50,
    this.gifUrl,
    required this.isJoined,
  }) : super(key: key);

  final DocumentReference? participantRef;
  final double size;
  final String? photoUrl;
  final String? name;
  final bool? isMuted;
  final int? shakeCount;
  final bool? isClapping;
  final String? gifUrl;
  final bool isJoined;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: isJoined,
      child: Stack(
        children: [
          photoUrl != '' && photoUrl != null
              ? CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    photoUrl as String,
                  ),
                  radius: size,
                )
              : Icon(CupertinoIcons.person_circle, size: size * 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              width: 100.0,
              height: 100.0,
              child: Stack(
                children: [
                  if (gifUrl != null)
                    Center(
                      child: Image.network(
                        gifUrl as String,
                        headers: const {'accept': 'image/*'},
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Visibility(
                    visible: isMuted ?? false,
                    child: Container(
                      color: CupertinoTheme.of(context)
                          .primaryColor
                          .withOpacity(0.8),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.mic_off,
                          color: CupertinoTheme.of(context)
                              .primaryContrastingColor,
                        ),
                      ),
                    ),
                  ),
                  if (shakeCount != null && shakeCount! >= 10) buildBoom(),
                  if (shakeCount != null &&
                      shakeCount! >= 3 &&
                      shakeCount! < 10)
                    buildBeer(),
                  Visibility(
                    visible: isClapping ?? false,
                    child: const Center(
                      child: Text(
                        '????',
                        style: TextStyle(fontSize: 80.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AnimatedOpacity buildBoom() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      onEnd: () => participantRef!.update({'shakeCount': 0}),
      child: const Center(
        child: Text(
          '????',
          style: TextStyle(fontSize: 80.0),
        ),
      ),
    );
  }

  AnimatedOpacity buildBeer() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      onEnd: () => participantRef!.update({'shakeCount': 0}),
      child: const Center(
        child: Text(
          '????',
          style: TextStyle(fontSize: 80.0),
        ),
      ),
    );
  }
}
