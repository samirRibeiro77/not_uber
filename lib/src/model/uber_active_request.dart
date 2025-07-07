import 'package:not_uber/src/model/uber_request.dart';

class UberActiveRequest {
  late String _requestId;
  late UberRequestStatus _status;
  late String _passengerId;
  late String? _driverId;

  UberActiveRequest(
    this._requestId,
    this._status,
    this._passengerId,
    this._driverId,
  );

  UberActiveRequest.fromRequest(UberRequest request) {
    _requestId = request.id;
    _status = request.status;
    _passengerId = request.passenger.id;
    _driverId = request.driver?.id;
  }

  UberActiveRequest.fromFirebase({Map<String, dynamic>? map}) {
    if (map == null) {
      throw Exception("UberActiveRequest needs to be initialized correctly");
    }

    _requestId = map["requestId"];
    _status = UberRequestStatus.getByString(map["status"]);
    _passengerId = map["passengerId"];
    _driverId = map["driverId"];
  }

  Map<String, dynamic> toJson() {
    return {
      "requestId": _requestId,
      "status": _status.value,
      "passengerId": _passengerId,
      "driverId": _driverId,
    };
  }

  String get requestId => _requestId;

  UberRequestStatus get status => _status;

  String get passengerId => _passengerId;

  String get driverId => _driverId ?? "";
}
