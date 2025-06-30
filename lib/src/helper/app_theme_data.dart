import 'package:flutter/material.dart';

class AppThemeData {
  static ThemeData get defaultTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff37474f)),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blueGrey[700],
      foregroundColor: Colors.white
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xff1ebbd8),
        padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    )
  );
}
