import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class Destination {
  late String _street;
  late String _number;
  late String _neighborhood;
  late String _city;
  late String _state;
  late String _countryCode;
  late String _postalCode;
  late GeoPoint _latLng;

  Destination.fromPlacemarkAndLocation({
    required Placemark placemark,
    required Location location,
  }) {
    _street = placemark.thoroughfare!;
    _number = placemark.subThoroughfare!;
    _neighborhood = placemark.subLocality!;
    _city = placemark.subAdministrativeArea!;
    _state = placemark.administrativeArea!;
    _countryCode = placemark.isoCountryCode!;
    _postalCode = placemark.postalCode!;
    _latLng = GeoPoint(location.latitude, location.longitude);
  }

  Destination.fromFirebase({Map<String, dynamic>? map}) {
    if (map == null) {
      throw Exception("UberRequest needs to be initialized correctly");
    }

    _street = map["street"];
    _number = map["number"];
    _neighborhood = map["neighborhood"];
    _city = map["city"];
    _state = map["state"];
    _countryCode = map["countryCode"];
    _postalCode = map["postalCode"];
    _latLng = map["latLng"];
  }

  Map<String, dynamic> toJson() {
    return {
      "street": _street,
      "number": _number,
      "neighborhood": _neighborhood,
      "city": _city,
      "state": _state,
      "countryCode": _countryCode,
      "postalCode": _postalCode,
      "latLng": _latLng,
    };
  }

  String toShortString() {
    return "$_street, $_number, $_neighborhood";
  }

  String toLongString() {
    return "$_street, $_number, $_neighborhood"
        "\n$_city, $_state - $_countryCode"
        "\n$_postalCode";
  }
}
