import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/route_generator.dart';
import 'package:not_uber/src/model/uber_user.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  _redirect() async {
    if (FirebaseAuth.instance.currentUser == null) {
      Timer(Duration(seconds: 3), () {
        Navigator.pushReplacementNamed(context, RouteGenerator.login);
      });
    } else {
      var homePage = await _getHomePageName();
      Navigator.pushReplacementNamed(context, homePage);
    }
  }

  Future<String> _getHomePageName() async {
    var user = await UberUser.current();

    return user.isDriver
        ? Future.value(RouteGenerator.driverHome)
        : Future.value(RouteGenerator.passengerHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _redirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(backgroundColor: Colors.white),
        ),
      ),
    );
  }
}
