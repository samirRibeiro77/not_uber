import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:not_uber/src/model/destination.dart';

class UberRequest {
  late String _id;
  late Destination _destination;
  late DocumentReference _passenger;
  late DocumentReference? _driver;
  late UberRequestStatus _status;

  UberRequest({
    String id = "",
    required Destination destination,
    required DocumentReference passenger,
    DocumentReference? driver,
  }) {
    _id = id;
    _destination = destination;
    _passenger = passenger;
    _driver = driver;
    _status = UberRequestStatus.waiting;
  }

  driverOnTheWay() {
    _status = UberRequestStatus.onTheWay;
  }

  startTrip() {
    _status = UberRequestStatus.trip;
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

  String get status => _status.value;
}

enum UberRequestStatus {
  waiting("Waiting driver"),
  onTheWay("Driver is on your way"),
  trip("On the trip"),
  done("Finished"),
  canceled("Canceled");

  final String value;
  const UberRequestStatus(this.value);
}
