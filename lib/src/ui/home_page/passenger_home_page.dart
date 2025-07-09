import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/location_helper.dart';
import 'package:not_uber/src/model/UberMarker.dart';
import 'package:not_uber/src/model/destination.dart';
import 'package:not_uber/src/model/uber_active_request.dart';
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
  StreamSubscription? _subscription;

  var _cameraPosition = CameraPosition(target: LatLng(0, 0));
  Set<Marker> _markers = {};
  var _lastRequestId = "";
  var _currentLocation = GeoPoint(0, 0);
  UberRequest? _currentRequest;

  // Control screen widgets
  var _loading = false;
  var _showAddressField = true;
  var _bottomButtonText = "Call an Uber";
  var _bottomButtonColor = Color(0xff1ebbd8);
  VoidCallback? _bottomButtonFunction;

  _createActiveRequestListener() async {
    var currentUser = await UberUser.current();
    var snapshot = await _db
        .collection(FirebaseHelper.collections.activeRequest)
        .doc(currentUser.id).get();

    if (snapshot.data() != null) {
      var activeRequest = UberActiveRequest.fromFirebase(map: snapshot.data());
      _lastRequestId = activeRequest.requestId;
      _createRequestListener(_lastRequestId);
    }
    else {
      _statusEmptyTrip();
    }
  }

  _createRequestListener(String requestId) async {
    _subscription = _db
        .collection(FirebaseHelper.collections.request)
        .doc(requestId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.data() != null) {
        _currentRequest = UberRequest.fromFirebase(map: snapshot.data());
        switch (_currentRequest!.status) {
          case UberRequestStatus.waiting:
            _statusWaiting();
            break;
          case UberRequestStatus.onTheWay:
            _statusDriverOnTheWay(_currentRequest!);
            break;
          case UberRequestStatus.onTrip:
            _statusOnTrip(_currentRequest!);
            break;
          case UberRequestStatus.waitingPayment:
            _statusTripEnded(_currentRequest!);
          case UberRequestStatus.done:
          case UberRequestStatus.canceled:
            _statusTripComplete();
            break;
        }
      }
    });
  }

  // Map Functions
  _createPassengerLocationListener() async {
    await LocationHelper.isLocationEnabled();

    var settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    Geolocator.getPositionStream(locationSettings: settings).listen((position) {
      _updateLocation(position: position);

      if (_lastRequestId.isNotEmpty) {
        _updatePassengerLocation();
      }
    });
  }

  _updateLocation({Position? position}) {
    if (position != null) {
      setState(() {
        _currentLocation = GeoPoint(position.latitude, position.longitude);
      });
    }

    if (_currentRequest == null) {
      _showMarker(_currentLocation, "assets/images/passenger.png", "My location");
      _moveCamera(
        CameraPosition(
          target: LatLng(_currentLocation.latitude, _currentLocation.longitude),
          zoom: 16,
        ),
      );
    }
  }
  
  _updatePassengerLocation() async {
    var passenger = await UberUser.current();
    passenger.updateLocation(_lastRequestId, _currentLocation);
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

  _showDriverLocation(UberRequest request) {
    var ratio = MediaQuery.of(context).devicePixelRatio;

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
          content: Text(destination.toLongString()),
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
    passenger.position = _currentLocation;

    var driverRequest = UberRequest(
      destination: destination,
      passenger: passenger,
    );

    _db
        .collection(FirebaseHelper.collections.request)
        .doc(driverRequest.id)
        .set(driverRequest.toJson());

    var activeRequest = UberActiveRequest.fromRequest(driverRequest);
    _db
        .collection(FirebaseHelper.collections.activeRequest)
        .doc(passenger.id)
        .set(activeRequest.toJson());

    _statusWaiting();

    setState(() {
      _lastRequestId = driverRequest.id;
    });
  }

  _cancelUber() async {
    if (_currentRequest != null) {
      _currentRequest!.cancelTrip();
    }
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }

    setState(() {
      _lastRequestId = "";
    });
  }

  // Widgets
  _statusEmptyTrip() {
    _updateButtonWidget(
      message: "Call an Uber",
      showAddress: true,
      color: Color(0xff1ebbd8),
      function: _callUber,
    );

    _updateLocation();
  }

  _statusWaiting() {
    _updateButtonWidget(
      message: "Cancel",
      showAddress: false,
      color: Colors.red,
      function: _cancelUber,
    );
  }

  _statusDriverOnTheWay(UberRequest request) {
    _updateButtonWidget(
      message: "Driver on your way",
      showAddress: false,
    );

    _showDriverLocation(request);
  }

  _statusOnTrip(UberRequest request) {
    var ratio = MediaQuery.of(context).devicePixelRatio;

    _updateButtonWidget(
      message: "On a trip",
      showAddress: false,
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
    _updateButtonWidget(
      message: "Price - R\$${request.price}",
      color: Colors.green,
      showAddress: false,
      function: (){}
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

  _statusTripComplete() {
    if (_subscription != null) {
      _subscription!.cancel();
      _subscription = null;
    }

    _statusEmptyTrip();
  }

  _updateButtonWidget({
    required String message,
    required bool showAddress,
    Color color = Colors.transparent,
    VoidCallback? function,
  }) {
    setState(() {
      _showAddressField = showAddress;
      _bottomButtonText = message;
      _bottomButtonColor = color;
      _bottomButtonFunction = function;
    });
  }

  @override
  void initState() {
    super.initState();
    _createPassengerLocationListener();

    _statusEmptyTrip();
    _createActiveRequestListener();
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
            bottom: MediaQuery
                .of(context)
                .viewInsets
                .bottom == 0 ? 25 : 0,
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
