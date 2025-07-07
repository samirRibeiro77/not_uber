import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/location_helper.dart';
import 'package:not_uber/src/model/uber_active_request.dart';
import 'package:not_uber/src/model/uber_request.dart';
import 'package:not_uber/src/model/uber_user.dart';

class RidePage extends StatefulWidget {
  const RidePage({super.key, required this.request});

  final UberRequest request;

  @override
  State<RidePage> createState() => _RidePageState();
}

class _RidePageState extends State<RidePage> {
  final _db = FirebaseFirestore.instance;

  final _mapController = Completer<GoogleMapController>();

  var _cameraPosition = CameraPosition(target: LatLng(0, 0));
  final Set<Marker> _markers = {};

  UberRequest? _request;

  // Control screen widgets
  var _loading = false;
  var _bottomButtonText = "Accept this trip";
  var _bottomButtonColor = Color(0xff1ebbd8);

  // Location and maps
  _getUserLocation() async {
    var lastPosition = await Geolocator.getLastKnownPosition();

    if (lastPosition != null) {
      _showDriverMarker(lastPosition);
      _moveCamera(
        CameraPosition(
          target: LatLng(lastPosition.latitude, lastPosition.longitude),
          zoom: 16,
        ),
      );
    }
  }

  _createLocationListener() async {
    await LocationHelper.isLocationEnabled();

    var settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    Geolocator.getPositionStream(locationSettings: settings).listen((position) {
      _showDriverMarker(position);
      _moveCamera(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      );
    });
  }

  _showDriverMarker(Position position) async {
    var ratio = MediaQuery.of(context).devicePixelRatio;
    var passengerIcon = await BitmapDescriptor.asset(
      ImageConfiguration(devicePixelRatio: ratio),
      "assets/images/driver.png",
      height: 45,
    );

    var passengerMarker = Marker(
      markerId: MarkerId("driver-marker"),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: "My local"),
      icon: passengerIcon,
    );

    setState(() {
      _markers.add(passengerMarker);
    });
  }

  _moveCamera(CameraPosition cameraPosition) async {
    var controller = await _mapController.future;
    setState(() {
      _cameraPosition = cameraPosition;
    });
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  // Load Data
  _getRequestData() async {
    var snapshot = await _db.collection(FirebaseHelper.collections.request).doc(widget.request.id).get();
    _request = UberRequest.fromFirebase(map: snapshot.data());
    _createRequestListener();
  }

  _createRequestListener() {
    _db
        .collection(FirebaseHelper.collections.request).doc(_request?.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        var request = UberRequest.fromFirebase(map: snapshot.data());
        print("Data => ${request.toJson()}");
        switch (request.status) {
          case UberRequestStatus.waiting:
            // _widgetsWaitingUber();
            break;
          case UberRequestStatus.canceled:
            // _cancelUber();
            break;
          case UberRequestStatus.onTheWay:
          case UberRequestStatus.onTrip:
          case UberRequestStatus.done:
            break;
        }
      }
    });
  }

  // Request functions
  _acceptRequest() {
    _confirmRequest(_request!);
  }

  _confirmRequest(UberRequest request) async {
    var driver = await UberUser.current();

    request.driverAcceptRequest(driver);
    print("Request => ${request.toJson()}");

    _db
        .collection(FirebaseHelper.collections.request)
        .doc(request.id)
        .update(request.toJson());

    var activeRequest = UberActiveRequest.fromRequest(request);
    print("Active Request => ${activeRequest.toJson()}");
    _db
        .collection(FirebaseHelper.collections.activeRequest)
        .doc(request.passenger.id)
        .set(activeRequest.toJson());
    _db
        .collection(FirebaseHelper.collections.activeRequest)
        .doc(driver.id)
        .set(activeRequest.toJson());

    _widgetsWaitingUber();
  }

  _widgetsWaitingUber() {
    setState(() {
      _bottomButtonText = "Cancel";
      _bottomButtonColor = Colors.red;
    });
  }

  @override
  void initState() {
    super.initState();

    _getUserLocation();
    _createLocationListener();
    _getRequestData();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("On a trip")),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
            initialCameraPosition: _cameraPosition,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
          ),
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom == 0 ? 25 : 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: _acceptRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bottomButtonColor,
                ),
                child: Text(
                  _bottomButtonText,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
