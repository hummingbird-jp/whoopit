import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FullScreenActivityIndicator extends StatelessWidget {
  const FullScreenActivityIndicator({
    Key? key,
    required bool isLoading,
  })  : _isInProgress = isLoading,
        super(key: key);

  //final bool _isMeJoinInProgress;
  //final bool _isMeLeaveInProgress;
  final bool _isInProgress;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _isInProgress,
      child: Opacity(
        opacity: 0.8,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).colorScheme.background,
          child: const Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
    );
  }
}
