import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/model/destination.dart';
import 'package:not_uber/src/model/uber_user.dart';

class UberRequest {
  late String _id;
  late Destination _destination;
  late UberUser _passenger;
  late UberUser? _driver;
  late UberRequestStatus _status;

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
    } else if (map != null) {
      _id = map["id"];
      _destination = Destination.fromFirebase(map: map["destination"]);
      _passenger = UberUser.fromFirebase(map: map["passenger"]);
      _driver = UberUser.fromFirebaseOrNull(map: map["driver"]);
      _status = UberRequestStatus.getByString(map["status"]);
    } else {
      throw Exception("UberRequest needs to be initialized correctly");
    }
  }

  driverAcceptRequest(UberUser driver) {
    _status = UberRequestStatus.onTheWay;
    _driver = driver;
  }

  startTrip() {
    _status = UberRequestStatus.onTrip;
  }

  finishTrip() {
    _status = UberRequestStatus.done;
  }

  cancelTrip() {
    _status = UberRequestStatus.done;
  }

  Map<String, dynamic> toJson() {
    return {
      "id": _id,
      "status": _status.value,
      "destination": _destination.toJson(),
      "passenger": _passenger.toJson(),
      "driver": _driver?.toJson(),
    };
  }

  UberRequestStatus get status => _status;

  UberUser get passenger => _passenger;

  Destination get destination => _destination;

  String get id => _id;

  UberUser? get driver => _driver;
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
