import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/location_helper.dart';
import 'package:not_uber/src/model/destination.dart';
import 'package:not_uber/src/model/uber_request.dart';
import 'package:not_uber/src/model/uber_user.dart';
import 'package:not_uber/src/ui/home_page/home_appbar.dart';

class PassengerHomePage extends StatefulWidget {
  const PassengerHomePage({super.key});

  @override
  State<PassengerHomePage> createState() => _PassengerHomePageState();
}

class _PassengerHomePageState extends State<PassengerHomePage> {
  final _db = FirebaseFirestore.instance;

  final _mapController = Completer<GoogleMapController>();
  final _destinationController = TextEditingController();

  var _cameraPosition = CameraPosition(target: LatLng(0, 0));
  final Set<Marker> _markers = {};

  // Control screen widgets
  var _loading = false;
  var _showAddressField = true;
  var _bottomButtonText = "Call an Uber";
  var _bottomButtonColor = Color(0xff1ebbd8);
  late Function _bottomButtonFunction;

  _widgetsDefaultValue() {
    _showAddressField = true;
    _changeBottomButton("Call an Uber", Color(0xff1ebbd8), _callUber());
  }

  _widgetsWaitingUber() {
    _showAddressField = false;
    _changeBottomButton("Cancel", Colors.red, _cancelRequest());
  }

  _changeBottomButton(String text, Color color, Function function) {
    setState(() {
      _bottomButtonText = text;
      _bottomButtonColor = color;
      _bottomButtonFunction = function;
    });
  }

  // Map Functions
  _getUserLocation() async {
    var lastPosition = await Geolocator.getLastKnownPosition();

    if (lastPosition != null) {
      _showUserMarker(lastPosition);
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
      _showUserMarker(position);
      _moveCamera(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 16,
        ),
      );
    });
  }

  _showUserMarker(Position position) async {
    var ratio = MediaQuery.of(context).devicePixelRatio;
    var passengerIcon = await BitmapDescriptor.asset(
      ImageConfiguration(devicePixelRatio: ratio),
      "assets/images/passenger.png",
      height: 45,
    );

    var passengerMarker = Marker(
      markerId: MarkerId("passenger-marker"),
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

  // Request functions
  _callUber() async {
    setState(() {
      _loading = true;
    });

    var destination = _destinationController.text;
    if (destination.isEmpty) {
      return;
    }

    var locationList = await locationFromAddress(destination);
    var location = locationList.firstOrNull;
    if (location != null) {
      var placemarkList = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      var placemark = placemarkList.firstOrNull;
      if (placemark != null) {
        var destination = Destination.fromPlacemarkAndLocation(
          placemark: placemark,
          location: location,
        );

        _callUberConfirmationDialog(destination);
      }
    }

    setState(() {
      _loading = false;
    });
  }

  _callUberConfirmationDialog(Destination destination) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm address"),
          content: Text(destination.toString()),
          contentPadding: EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                _requestRide(destination);
                Navigator.pop(context);
              },
              child: Text("Confirm", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  _requestRide(Destination destination) async {
    var passenger = await UberUser.current();
    var driverRequest = UberRequest(
      destination: destination,
      passenger: passenger.ref!,
    );

    _db
        .collection(FirebaseHelper.collections.request)
        .add(driverRequest.toJson());

    _widgetsWaitingUber();
  }

  _cancelRequest() {}

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _createLocationListener();
    _widgetsDefaultValue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppbar(title: "Passenger"),
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
          Visibility(
            visible: _showAddressField,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.white,
                      ),
                      child: TextField(
                        readOnly: true,
                        keyboardType: TextInputType.streetAddress,
                        decoration: InputDecoration(
                          icon: Container(
                            margin: EdgeInsets.only(left: 20),
                            child: Icon(Icons.location_on, color: Colors.green),
                          ),
                          contentPadding: EdgeInsets.only(left: 15),
                          hintText: "My location",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 55,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.white,
                      ),
                      child: TextField(
                        controller: _destinationController,
                        keyboardType: TextInputType.streetAddress,
                        decoration: InputDecoration(
                          icon: Container(
                            margin: EdgeInsets.only(left: 20),
                            child: _loading
                                ? CircularProgressIndicator()
                                : Icon(Icons.local_taxi, color: Colors.black),
                          ),
                          contentPadding: EdgeInsets.only(left: 15),
                          hintText: "Destination",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom == 0 ? 25 : 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: ElevatedButton(
                onPressed: _callUber,
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
