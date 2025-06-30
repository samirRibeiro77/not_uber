import 'package:flutter/material.dart';

class AppThemeData {
  static ThemeData get defaultTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
    primaryColor: Color(0xff37474f),
  );
}