import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/route_generator.dart';
import 'package:not_uber/src/model/uber_active_request.dart';
import 'package:not_uber/src/model/uber_request.dart';
import 'package:not_uber/src/model/uber_user.dart';
import 'package:not_uber/src/ui/home_page/home_appbar.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final _db = FirebaseFirestore.instance;

  final _controller = StreamController<QuerySnapshot>.broadcast();

  Widget _showMessage(String text) {
    return Center(
      child: Text(
        text,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  _createRequestListener() {
    _db
        .collection(FirebaseHelper.collections.request)
        .where("status", isEqualTo: UberRequestStatus.waiting.value)
        .snapshots()
        .listen((data) {
          _controller.add(data);
        });
  }

  _getCurrentRequest() async {
    var user = await UberUser.current();
    var activeRequestSnapshot = await _db.collection(FirebaseHelper.collections.activeRequest).doc(user.id).get();

    if (activeRequestSnapshot.data() == null) {
      _createRequestListener();
    }
    else {
      var activeRequest = UberActiveRequest.fromFirebase(map: activeRequestSnapshot.data());
      var requestSnapshot = await _db.collection(FirebaseHelper.collections.request).doc(activeRequest.requestId).get();
      var request = UberRequest.fromFirebase(map: requestSnapshot.data());
      Navigator.pushReplacementNamed(context, RouteGenerator.onTrip, arguments: request);
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentRequest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppbar(title: "Driver"),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.stream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            case ConnectionState.active:
            case ConnectionState.done:
              if (snapshot.hasError) {
                return _showMessage("Error loading requests");
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _showMessage("No requests at this moment");
              }

              var requestList = snapshot.data!.docs;
              return ListView.separated(
                itemCount: requestList.length,
                separatorBuilder: (context, index) => Divider(height: 2, color: Colors.grey),
                itemBuilder: (context, index) {
                  var request = UberRequest.fromFirebase(snapshot: requestList[index]);

                  return ListTile(
                    onTap: () => Navigator.pushNamed(context, RouteGenerator.onTrip, arguments: request),
                    title: Text(request.passenger.name),
                    subtitle: Text("Destination: ${request.destination.toShortString()}"),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
