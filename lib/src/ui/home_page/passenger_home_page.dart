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

  _getUserLocation() async {
    var lastPosition = await Geolocator.getLastKnownPosition();

    if (lastPosition != null) {
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
      _moveCamera(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16,
          )
      );
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
    _getUserLocation();
    super.initState();
    _createLocationListener();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppbar(title: "Passenger"),
      body: GoogleMap(
        mapType: MapType.normal,
        myLocationEnabled: true,
        initialCameraPosition: _cameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _mapController.complete(controller);
        },
      ),
    );
  }
}
