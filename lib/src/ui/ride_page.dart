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
  Set<Marker> _markers = {};
  var _currentLocation = GeoPoint(0, 0);

  // Control screen widgets
  var _bottomButtonText = "Accept this trip";
  var _bottomButtonColor = Color(0xff1ebbd8);
  VoidCallback? _bottomButtonFunction;
  String _appbarStatus = "";

  // Location and maps
  _getDriverLocation() async {
    var lastPosition = await Geolocator.getLastKnownPosition();

    if (lastPosition != null) {
      _currentLocation = GeoPoint(lastPosition.latitude, lastPosition.longitude);

    }
  }

  _createDriverLocationListener() async {
    await LocationHelper.isLocationEnabled();

    var settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    Geolocator.getPositionStream(locationSettings: settings).listen((position) {
      _currentLocation = GeoPoint(position.latitude, position.longitude);

    });
  }

  _showMarker(GeoPoint position, String icon, String infoWindow) async {
    var ratio = MediaQuery.of(context).devicePixelRatio;
    var bitmapIcon = await BitmapDescriptor.asset(
      ImageConfiguration(devicePixelRatio: ratio),
      icon,
      height: 45,
    );

    var marker = Marker(
      markerId: MarkerId(icon),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: infoWindow),
      icon: bitmapIcon,
    );

    setState(() {
      _markers.add(marker);
    });
  }

  _moveCamera(CameraPosition cameraPosition) async {
    var controller = await _mapController.future;
    setState(() {
      _cameraPosition = cameraPosition;
    });
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _moveCameraBounds(LatLng driver, LatLng passenger) async {
    var sLat = passenger.latitude;
    var nLat = driver.latitude;
    var sLng = passenger.longitude;
    var nLng = driver.longitude;

    if (driver.latitude <= passenger.latitude) {
      sLat = driver.latitude;
      nLat = passenger.latitude;
    }

    if (driver.longitude <= passenger.longitude) {
      sLng = driver.longitude;
      nLng = passenger.longitude;
    }

    var controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(sLat, sLng),
          northeast: LatLng(nLat, nLng),
        ),
        100,
      ),
    );
  }

  // Load Data
  _createRequestListener() {
    _db
        .collection(FirebaseHelper.collections.request)
        .doc(widget.request.id)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.data() != null) {
            var request = UberRequest.fromFirebase(map: snapshot.data());
            switch (request.status) {
              case UberRequestStatus.waiting:
              case UberRequestStatus.canceled:
                _statusWaiting(request);
                break;
              case UberRequestStatus.onTheWay:
              case UberRequestStatus.onTrip:
                _statusGoingToThePassenger();
                break;
              case UberRequestStatus.done:
                break;
            }
          }
        });
  }

  // Request functions
  _acceptRequest() async {
    var driver = await UberUser.current();
    driver.position = _currentLocation;

    widget.request.driverAcceptRequest(driver);

    _db
        .collection(FirebaseHelper.collections.request)
        .doc(widget.request.id)
        .update(widget.request.toJson());

    var activeRequest = UberActiveRequest.fromRequest(widget.request);
    _db
        .collection(FirebaseHelper.collections.activeRequest)
        .doc(widget.request.passenger.id)
        .update(activeRequest.toJson());
    _db
        .collection(FirebaseHelper.collections.activeRequest)
        .doc(driver.id)
        .set(activeRequest.toJson());

    _showPassengerLocation();
  }

  _showPassengerLocation() {
    _showBothMarkers(
      widget.request.driver!.position!,
      widget.request.passenger.position!,
    );
  }

  _showBothMarkers(GeoPoint driver, GeoPoint passenger) async {
    Set<Marker> markerList = {};
    var ratio = MediaQuery.of(context).devicePixelRatio;

    var passengerIcon = await BitmapDescriptor.asset(
      ImageConfiguration(devicePixelRatio: ratio),
      "assets/images/passenger.png",
      height: 45,
    );

    var passengerMarker = Marker(
      markerId: MarkerId("passenger-marker"),
      position: LatLng(passenger.latitude, passenger.longitude),
      infoWindow: InfoWindow(title: "My local"),
      icon: passengerIcon,
    );

    var driverIcon = await BitmapDescriptor.asset(
      ImageConfiguration(devicePixelRatio: ratio),
      "assets/images/driver.png",
      height: 45,
    );

    var driverMarker = Marker(
      markerId: MarkerId("driver-marker"),
      position: LatLng(driver.latitude, driver.longitude),
      infoWindow: InfoWindow(title: "My local"),
      icon: driverIcon,
    );

    markerList.add(passengerMarker);
    markerList.add(driverMarker);

    setState(() {
      _markers = markerList;
    });

    _moveCameraBounds(
      LatLng(driver.latitude, driver.longitude),
      LatLng(passenger.latitude, passenger.longitude),
    );
  }

  _startTrip() {}

  // Bottom Button
  _statusWaiting(UberRequest request) {
    _updateWidgets(
      appbarMessage: request.passenger.name,
      message: "Accept ride",
      color: Color(0xff1ebbd8),
      function: _acceptRequest,
    );

    if (request.driver != null) {
      _showMarker(
        request.driver!.position!,
        "assets/images/driver.png",
        "Driver",
      );

      _moveCamera(
        CameraPosition(
          target: LatLng(
            request.driver!.position!.latitude,
            request.driver!.position!.longitude,
          ),
          zoom: 19,
        ),
      );
    }
  }

  _statusGoingToThePassenger() {
    _showPassengerLocation();
    _updateWidgets(
      appbarMessage: "Going to the passenger",
      message: "Start trip",
      color: Color(0xff1ebbd8),
      function: _startTrip,
    );
  }

  _updateWidgets({
    String appbarMessage = "",
    required String message,
    Color color = Colors.transparent,
    VoidCallback? function,
  }) {
    setState(() {
      _appbarStatus = appbarMessage.isNotEmpty ? "- $appbarMessage" : "";
      _bottomButtonText = message;
      _bottomButtonColor = color;
      _bottomButtonFunction = function;
    });
  }

  @override
  void initState() {
    super.initState();
    _createRequestListener();

    _getDriverLocation();
    _createDriverLocationListener();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ride $_appbarStatus")),
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
                onPressed: _bottomButtonFunction,
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
