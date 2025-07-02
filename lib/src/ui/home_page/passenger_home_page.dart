import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:not_uber/src/helper/location_helper.dart';
import 'package:not_uber/src/ui/home_page/home_appbar.dart';

class PassengerHomePage extends StatefulWidget {
  const PassengerHomePage({super.key});

  @override
  State<PassengerHomePage> createState() => _PassengerHomePageState();
}

class _PassengerHomePageState extends State<PassengerHomePage> {
  final _mapController = Completer<GoogleMapController>();

  var _cameraPosition = CameraPosition(target: LatLng(0, 0));
  final Set<Marker> _markers = {};

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
        "assets/images/passenger.png"
    );

    var passengerMarker = Marker(
        markerId: MarkerId("passenger-marker"),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(
        title: "My local"
      ),
      icon: passengerIcon
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

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _createLocationListener();
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
                  controller: null,
                  keyboardType: TextInputType.streetAddress,
                  decoration: InputDecoration(
                    icon: Container(
                      margin: EdgeInsets.only(left: 20),
                      child: Icon(Icons.local_taxi, color: Colors.black,),
                    ),
                    contentPadding: EdgeInsets.only(left: 15),
                    hintText: "Destination",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom == 0 ? 25 : 0,
              left: 0,
              right: 0,
              child: Padding(
                  padding: EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: (){},
                    child: Text(
                      "Call an uber",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
              )
          )
        ],
      ),
    );
  }
}
