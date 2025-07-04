import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/model/destination.dart';

class UberRequest {
  late DocumentReference _reference;
  late Destination _destination;
  late DocumentReference _passenger;
  late DocumentReference? _driver;
  late UberRequestStatus _status;

  UberRequest({
    required Destination destination,
    required DocumentReference passenger,
    DocumentReference? driver,
  }) {
    _reference = FirebaseFirestore.instance.collection(FirebaseHelper.collections.request).doc();
    _destination = destination;
    _passenger = passenger;
    _driver = driver;
    _status = UberRequestStatus.waiting;
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
      "passenger": _passenger,
      "driver": _driver,
    };
  }

  UberRequestStatus get status => _status;

  DocumentReference? get driver => _driver;

  DocumentReference get passenger => _passenger;

  Destination get destination => _destination;

  String get id => _reference.id;

  DocumentReference get reference => _reference;
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
