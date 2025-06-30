import 'package:flutter/material.dart';
import 'package:not_uber/src/ui/home_page/home_appbar.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppbar(title: "Driver"),
    );
  }
}
