import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UberMarker {
  GeoPoint position;
  UberMarkerType type;
  double pixelRation;

  UberMarker({required this.position, required this.type, required this.pixelRation});

  Future<Marker> getMarker() async {
    var destinationIcon = await BitmapDescriptor.asset(
      ImageConfiguration(devicePixelRatio: pixelRation),
      "assets/images/${type.name}.png",
      height: 45,
    );

    return Marker(
      markerId: MarkerId("${type.name}-marker"),
      position: LatLng(position.latitude, position.longitude),
      infoWindow: InfoWindow(title: "Destination"),
      icon: destinationIcon,
    );
  }
}

enum UberMarkerType {
  passenger,
  driver,
  destination;
}