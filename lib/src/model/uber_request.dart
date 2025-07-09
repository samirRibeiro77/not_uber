import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/model/destination.dart';
import 'package:not_uber/src/model/uber_active_request.dart';
import 'package:not_uber/src/model/uber_user.dart';

class UberRequest {
  late String _id;
  late Destination _destination;
  late GeoPoint? _origin;
  late UberUser _passenger;
  late UberUser? _driver;
  late UberRequestStatus _status;
  late double? _price;

  UberRequest({
    required Destination destination,
    required UberUser passenger,
    UberUser? driver,
  }) {
    _id = FirebaseFirestore.instance
        .collection(FirebaseHelper.collections.request)
        .doc()
        .id;
    _destination = destination;
    _passenger = passenger;
    _driver = driver;
    _status = UberRequestStatus.waiting;
  }

  UberRequest.fromFirebase({
    Map<String, dynamic>? map,
    QueryDocumentSnapshot? snapshot,
  }) {
    if (snapshot != null) {
      _id = snapshot["id"] ?? snapshot.id;
      _destination = Destination.fromFirebase(map: snapshot["destination"]);
      _passenger = UberUser.fromFirebase(map: snapshot["passenger"]);
      _driver = UberUser.fromFirebaseOrNull(map: snapshot["driver"]);
      _status = UberRequestStatus.getByString(snapshot["status"]);
      _origin = snapshot["origin"];
      _price = snapshot["price"];
    } else if (map != null) {
      _id = map["id"];
      _destination = Destination.fromFirebase(map: map["destination"]);
      _passenger = UberUser.fromFirebase(map: map["passenger"]);
      _driver = UberUser.fromFirebaseOrNull(map: map["driver"]);
      _status = UberRequestStatus.getByString(map["status"]);
      _origin = map["origin"];
      _price = map["price"];
    } else {
      throw Exception("UberRequest needs to be initialized correctly");
    }
  }

  driverAcceptRequest(UberUser driver, GeoPoint driverPosition) {
    driver.position = driverPosition;
    _driver = driver;

    // Active Request
    var activeRequest = UberActiveRequest.fromRequest(this);
    FirebaseFirestore.instance
        .collection(FirebaseHelper.collections.activeRequest)
        .doc(driver.id)
        .set(activeRequest.toJson());

    _updateStatus(UberRequestStatus.onTheWay);
  }

  startTrip() {
    _origin = driver!.position!;
    _updateStatus(UberRequestStatus.onTrip);
  }

  finishTrip() {
    var distanceKm =
        Geolocator.distanceBetween(
          _origin!.latitude,
          _origin!.longitude,
          _destination.position.latitude,
          _destination.position.longitude,
        ) /
        1000;

    // Price is R$8,00 per KM
    _price = distanceKm * 8;

    _updateStatus(UberRequestStatus.done);
  }

  cancelTrip() {
    _updateStatus(UberRequestStatus.canceled);
  }

  _updateStatus(UberRequestStatus uberRequestStatus) {
    _status = uberRequestStatus;
    final db = FirebaseFirestore.instance;

    // Active Request
    db
        .collection(FirebaseHelper.collections.activeRequest)
        .doc(_passenger.id)
        .update({"status": uberRequestStatus.value});

    if (driver != null) {
      db
          .collection(FirebaseHelper.collections.activeRequest)
          .doc(_driver?.id)
          .update({"status": uberRequestStatus.value});
    }

    // This Request
    db.collection(FirebaseHelper.collections.request).doc(_id).update(toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      "id": _id,
      "status": _status.value,
      "destination": _destination.toJson(),
      "origin": _origin,
      "passenger": _passenger.toJson(),
      "driver": _driver?.toJson(),
      "price": _price
    };
  }

  UberRequestStatus get status => _status;

  UberUser get passenger => _passenger;

  Destination get destination => _destination;

  String get id => _id;

  UberUser? get driver => _driver;

  GeoPoint? get origin => _origin;

  String get price => _getPrice();

  String _getPrice() {
    var formatter = NumberFormat("#,##0.00", "pt_BR");
    return formatter.format(_price);
  }
}

enum UberRequestStatus {
  waiting("waiting"),
  onTheWay("onTheWay"),
  onTrip("onTrip"),
  done("done"),
  canceled("canceled");

  final String value;

  const UberRequestStatus(this.value);

  bool withDriver() {
    return this == UberRequestStatus.onTheWay ||
        this == UberRequestStatus.onTrip;
  }

  static UberRequestStatus getByString(String text) {
    return UberRequestStatus.values.byName(text);
  }
}
