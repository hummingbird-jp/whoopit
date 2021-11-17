import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ParticipantCircle extends StatelessWidget {
  const ParticipantCircle({
    Key? key,
    required this.photoUrl,
    required this.name,
    required this.isMuted,
    required this.isShaking,
    required this.isClapping,
    this.size = 50,
  }) : super(key: key);

  final double size;
  final String photoUrl;
  final String? name;
  final bool isMuted;
  final bool isShaking;
  final bool isClapping;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        photoUrl != ''
            ? CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  photoUrl,
                ),
                radius: size,
              )
            : Center(
                child: Text(
                  name ?? '',
                ),
              ),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: SizedBox(
            width: 100.0,
            height: 100.0,
            child: Stack(
              children: [
                Visibility(
                  visible: isMuted,
                  child: Container(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.mic_off,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: isShaking,
                  child: const Center(
                    child: Text(
                      '🍺',
                      style: TextStyle(fontSize: 80.0),
                    ),
                  ),
                ),
                Visibility(
                  visible: isClapping,
                  child: const Center(
                    child: Text(
                      '👏',
                      style: TextStyle(fontSize: 80.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
