import 'package:flutter/material.dart';
import 'package:not_uber/src/ui/home_page/home_appbar.dart';

class PassengerHomePage extends StatefulWidget {
  const PassengerHomePage({super.key});

  @override
  State<PassengerHomePage> createState() => _PassengerHomePageState();
}

class _PassengerHomePageState extends State<PassengerHomePage> {
  @override
  Widget build(BuildContext context) {
    print(kToolbarHeight);
    return Scaffold(
      appBar: HomeAppbar(title: "Passenger")
    );
  }
}
