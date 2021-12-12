import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FullScreenActivityIndicator extends StatelessWidget {
  const FullScreenActivityIndicator({
    Key? key,
    required bool isLoading,
  })  : _isInProgress = isLoading,
        super(key: key);

  final bool _isInProgress;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _isInProgress,
      child: IgnorePointer(
        ignoring: _isInProgress,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: CupertinoTheme.of(context)
              .scaffoldBackgroundColor
              .withOpacity(0.9),
          child: const Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
    );
  }
}
