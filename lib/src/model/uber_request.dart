import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/model/destination.dart';
import 'package:not_uber/src/model/uber_user.dart';

class UberRequest {
  late DocumentReference _reference;
  late Destination _destination;
  late UberUser _passenger;
  late UberUser? _driver;
  late UberRequestStatus _status;

  UberRequest({
    required Destination destination,
    required UberUser passenger,
    UberUser? driver,
  }) {
    _reference = FirebaseFirestore.instance.collection(FirebaseHelper.collections.request).doc();
    _destination = destination;
    _passenger = passenger;
    _driver = driver;
    _status = UberRequestStatus.waiting;
  }


  UberRequest.fromFirebase({QueryDocumentSnapshot? snapshot}) {
    if (snapshot == null) {
      throw Exception("UberRequest needs to be initialized correctly");
    }

    _reference = snapshot.reference;
    _destination = Destination.fromFirebase(map: snapshot["destination"]);
    _passenger = UberUser.fromFirebase(map: snapshot["passenger"]);
    _driver = snapshot["driver"] != null ? UberUser.fromFirebase(map: snapshot["driver"]) : null;
    _status = UberRequestStatus.getByString(snapshot["status"]);
  }

  driverOnTheWay() {
    _status = UberRequestStatus.onTheWay;
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
      "status": _status.value,
      "destination": _destination.toJson(),
      "passenger": _passenger.toJson(),
      "driver": _driver?.toJson(),
    };
  }

  UberRequestStatus get status => _status;

  UberUser get passenger => _passenger;

  Destination get destination => _destination;

  String get id => _reference.id;

  DocumentReference get reference => _reference;

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

  static UberRequestStatus getByString(String text) {
    return UberRequestStatus.values.byName(text);
  }
}
