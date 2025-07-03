import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:not_uber/src/model/destination.dart';

class UberRequest {
  late String _id;
  late Destination _destination;
  late DocumentReference _passenger;
  late DocumentReference? _driver;

  // Posible values: waiting, onGoing, done
  late String _status;

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
    _status = "waiting";
  }

  waitingDriver() {
    _status = "waiting";
  }

  traveling() {
    _status = "onGoing";
  }

  done() {
    _status = "done";
  }

  Map<String, dynamic> toJson() {
    return {
      "status": _status,
      "destination": _destination.toJson(),
      "passenger": _passenger,
      "driver": _driver,
    };
  }
}
