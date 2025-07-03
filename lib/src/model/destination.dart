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

  Map<String, dynamic> toJson() {
    return {
      "street": _street,
      "number": _number,
      "neighborhood": _neighborhood,
      "city": _city,
      "countryCode": _countryCode,
      "postalCode": _postalCode,
      "latLng": _latLng,
    };
  }

  @override
  String toString() {
    return "$_street, $_number, $_neighborhood"
        "\n$_city, $_state - $_countryCode"
        "\n$_postalCode";
  }
}
