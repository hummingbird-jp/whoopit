import 'package:flutter/cupertino.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:flutterfire_ui/auth/google.dart';

CupertinoThemeData kThemeData = const CupertinoThemeData(
  primaryColor: CupertinoDynamicColor.withBrightness(
    color: Color(0xFF4642B3),
    darkColor: Color(0xFF18173D),
  ),
  primaryContrastingColor: CupertinoDynamicColor.withBrightness(
    color: Color(0xFFFFCC4A),
    darkColor: Color(0xFFB08D33),
  ),
  barBackgroundColor: CupertinoDynamicColor.withBrightness(
    color: Color(0xFF000030),
    darkColor: Color(0xFF00000E),
  ),
  scaffoldBackgroundColor: CupertinoDynamicColor.withBrightness(
    color: Color(0xFF000030),
    darkColor: Color(0xFF00000E),
  ),
  textTheme: CupertinoTextThemeData(
    primaryColor: CupertinoDynamicColor.withBrightness(
      color: Color(0xFFFFFFFF),
      darkColor: Color(0xFFCCCCCC),
    ),
    textStyle: TextStyle(
      fontFamily: 'Helvetica Neue',
      fontSize: 17,
      fontWeight: FontWeight.w400,
    ),
  ),
);

const providerConfigs = [
  EmailProviderConfiguration(),
  GoogleProviderConfiguration(
    clientId: 'fir-flutter-codelab-32edb',
  ),
];
