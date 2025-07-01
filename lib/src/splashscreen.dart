import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/route_generator.dart';
import 'package:not_uber/src/model/uber_user.dart';

class Splashscreen extends StatelessWidget {
  Splashscreen({super.key});

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  _redirect(BuildContext context) async {
    var firebaseUser = await _auth.currentUser;
    if (firebaseUser == null) {
      Navigator.pushReplacementNamed(context, RouteGenerator.login);
    }

    var homePage = await _getHomePageName(firebaseUser!.uid);
    Navigator.pushReplacementNamed(context, homePage);
  }

  Future<String> _getHomePageName(String uid) async {
    var snapshot = await _db
        .collection(FirebaseHelper.collections.user)
        .doc(uid)
        .get();

    var user = UberUser.fromFirebase(map: snapshot.data());

    return user.isDriver
        ? RouteGenerator.driverHome
        : RouteGenerator.passengerHome;
  }

  @override
  Widget build(BuildContext context) {
    _redirect(context);

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/background.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(backgroundColor: Colors.white)
      )
    );
  }
}
