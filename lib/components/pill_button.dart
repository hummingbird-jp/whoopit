import 'package:flutter/material.dart';

class PillButton extends StatelessWidget {
  const PillButton({
    Key? key,
    required this.child,
    required this.color,
    this.onPressed,
  }) : super(key: key);

  final Widget child;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          color,
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              color: color,
            ),
          ),
        ),
      ),
      child: child,
      onPressed: onPressed,
    );
  }
}
