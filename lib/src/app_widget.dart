import 'package:flutter/material.dart';
import 'package:not_uber/src/helper/app_theme_data.dart';
import 'package:not_uber/src/helper/route_generator.dart';
import 'package:not_uber/src/ui/login_page.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Not Uber",
      theme: AppThemeData.defaultTheme,
      initialRoute: RouteGenerator.initial,
      onGenerateRoute: RouteGenerator.generateRoutes,
      home: LoginPage(),
    );
  }
}
