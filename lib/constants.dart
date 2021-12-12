import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:flutterfire_ui/auth/google.dart';

CupertinoThemeData kThemeData = const CupertinoThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF4642B3),
  primaryContrastingColor: Color(0xFFFFCC4A),
  barBackgroundColor: Color(0xFF000030),
  scaffoldBackgroundColor: Color(0xFF000030),
);

const providerConfigs = [
  EmailProviderConfiguration(),
  GoogleProviderConfiguration(
    clientId: 'fir-flutter-codelab-32edb',
  ),
];
