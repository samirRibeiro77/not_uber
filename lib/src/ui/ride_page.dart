import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/location_helper.dart';
import 'package:not_uber/src/helper/route_generator.dart';
import 'package:not_uber/src/model/UberMarker.dart';
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
  _createDriverLocationListener() async {
    await LocationHelper.isLocationEnabled();

    var settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    Geolocator.getPositionStream(locationSettings: settings).listen((position) {
      _updateLocation(position: position);

      if (widget.request.status.withDriver()) {
        _updateDriverLocation();
      }
    });
  }

  _updateLocation({Position? position}) {
    if (position != null) {
      setState(() {
        _currentLocation = GeoPoint(position.latitude, position.longitude);
      });
    }

    if (!widget.request.status.withDriver()) {
      _showMarker(_currentLocation, "assets/images/driver.png", "Driver");
      _moveCamera(
        CameraPosition(
          target: LatLng(_currentLocation.latitude, _currentLocation.longitude),
          zoom: 16,
        ),
      );
    }
  }

  _updateDriverLocation() async {
    var passenger = await UberUser.current();
    passenger.updateLocation(widget.request.id, _currentLocation);
  }

  _showMarker(GeoPoint position, String icon, String infoWindow) async {
    Set<Marker> oneMarker = {};

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

    oneMarker.add(marker);

    setState(() {
      _markers = oneMarker;
    });
  }

  _moveCamera(CameraPosition cameraPosition) async {
    var controller = await _mapController.future;
    setState(() {
      _cameraPosition = cameraPosition;
    });
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _moveCameraBounds(LatLng origin, LatLng destination) async {
    var sLat = destination.latitude;
    var nLat = origin.latitude;
    var sLng = destination.longitude;
    var nLng = origin.longitude;

    if (origin.latitude <= destination.latitude) {
      sLat = origin.latitude;
      nLat = destination.latitude;
    }

    if (origin.longitude <= destination.longitude) {
      sLng = origin.longitude;
      nLng = destination.longitude;
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
                _statusGoingToThePassenger(request);
                break;
              case UberRequestStatus.onTrip:
                _statusOnTrip(request);
                break;
              case UberRequestStatus.waitingPayment:
                _statusTripEnded(request);
                break;
              case UberRequestStatus.done:
                _statusTripCompleted();
                break;
            }
          }
        });
  }

  // Request functions
  _showPassengerLocation({UberRequest? request}) {
    var ratio = MediaQuery.of(context).devicePixelRatio;

    if (request != null) {
      var origin = UberMarker(
        position: request.driver!.position!,
        type: UberMarkerType.driver,
        pixelRation: ratio,
      );
      var destination = UberMarker(
        position: request.passenger.position!,
        type: UberMarkerType.passenger,
        pixelRation: ratio,
      );

      _showBothMarkers(origin, destination);
    } else {
      var origin = UberMarker(
        position: widget.request.driver!.position!,
        type: UberMarkerType.driver,
        pixelRation: ratio,
      );
      var destination = UberMarker(
        position: widget.request.passenger.position!,
        type: UberMarkerType.passenger,
        pixelRation: ratio,
      );

      _showBothMarkers(origin, destination);
    }
  }

  _showBothMarkers(UberMarker origin, UberMarker destination) async {
    Set<Marker> markerList = {};

    var originMarker = await origin.getMarker();
    var destinationMarker = await destination.getMarker();

    markerList.add(originMarker);
    markerList.add(destinationMarker);

    setState(() {
      _markers = markerList;
    });

    _moveCameraBounds(
      LatLng(origin.position.latitude, origin.position.longitude),
      LatLng(destination.position.latitude, destination.position.longitude),
    );
  }

  _acceptRequest(UberRequest request) async {
    var driver = await UberUser.current();
    request.driverAcceptRequest(driver, _currentLocation);
    _showPassengerLocation();
  }

  _confirmTripEnded(UberRequest request){
    request.completeTrip();
  }

  // Bottom Button
  _statusWaiting(UberRequest request) {
    _updateWidgets(
      appbarMessage: request.passenger.name,
      message: "Accept ride",
      color: Color(0xff1ebbd8),
      function: () => _acceptRequest(request),
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

  _statusGoingToThePassenger(UberRequest request) {
    var ratio = MediaQuery.of(context).devicePixelRatio;

    _updateWidgets(
      appbarMessage: "Going to the passenger",
      message: "Start trip",
      color: Color(0xff1ebbd8),
      function: () => request.startTrip(),
    );

    var origin = UberMarker(
      position: request.driver!.position!,
      type: UberMarkerType.driver,
      pixelRation: ratio,
    );
    var destination = UberMarker(
      position: request.passenger.position!,
      type: UberMarkerType.passenger,
      pixelRation: ratio,
    );

    _showBothMarkers(origin, destination);
  }

  _statusOnTrip(UberRequest request) {
    var ratio = MediaQuery.of(context).devicePixelRatio;

    _updateWidgets(
      appbarMessage: "On a trip",
      message: "Finish trip",
      color: Color(0xff1ebbd8),
      function: () => request.finishTrip(),
    );

    var origin = UberMarker(
      position: request.driver!.position!,
      type: UberMarkerType.driver,
      pixelRation: ratio,
    );
    var destination = UberMarker(
      position: request.destination.position,
      type: UberMarkerType.destination,
      pixelRation: ratio,
    );

    _showBothMarkers(origin, destination);
  }

  _statusTripEnded(UberRequest request) {
    _updateWidgets(
      appbarMessage: "Trip ended",
      message: "Confirm - R\$${request.price}",
      color: Color(0xff1ebbd8),
      function: () => _confirmTripEnded(request),
    );

    var endTripPosition = request.destination.position;
    _showMarker(endTripPosition, "assets/images/destination.png", "Destination arrived");
    _moveCamera(
      CameraPosition(
        target: LatLng(endTripPosition.latitude, endTripPosition.longitude),
        zoom: 19,
      ),
    );
  }

  _statusTripCompleted() {
    Navigator.pushReplacementNamed(context, RouteGenerator.driverHome);
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

    // _getDriverLocation();
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
