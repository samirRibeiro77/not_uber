import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:not_uber/src/model/uber_request.dart';

class UberActiveRequest {
  late DocumentReference _request;
  late UberRequestStatus _status;

  UberActiveRequest(this._request, this._status);

  UberActiveRequest.fromRequest(UberRequest request) {
    _request = request.reference;
    _status = request.status;
  }

  UberActiveRequest.fromFirebase({Map<String, dynamic>? map}) {
    if (map == null) {
      throw Exception("UberActiveRequest needs to be initialized correctly");
    }

    _request = map["request"];
    _status = UberRequestStatus.getByString(map["status"]);
}

  UberRequestStatus get status => _status;

  DocumentReference get request => _request;

  Map<String, dynamic> toJson() {
    return {
      "request": _request,
      "status": _status.value,
    };
  }
}