import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';

class UberUser {
  late DocumentReference? ref;
  late String name;
  late String email;
  String? _password;
  late bool isDriver;

  UberUser({
    this.name = "",
    required this.email,
    this.isDriver = false,
    String password = "",
  }) {
    _password = password;
  }

  UberUser.fromFirebase({this.ref, Map<String, dynamic>? map}) {
    if (map == null) {
      throw Exception("UberUser needs to be initialized correctly");
    }

    name = map["name"] ?? "";
    email = map["email"] ?? "";
    isDriver = map["isDriver"] ?? false;
  }

  static Future<UberUser> current() async {
    var snapshot = await FirebaseFirestore.instance
        .collection(FirebaseHelper.collections.user)
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    return UberUser.fromFirebase(map: snapshot.data(), ref: snapshot.reference);
  }

  String validateUser({
    bool validateName = true,
    bool validateEmail = true,
    bool validatePassword = true,
  }) {
    var errorMessages = [];

    if (validateName) errorMessages.add(_validName);
    if (validateEmail) errorMessages.add(_validEmail);
    if (validatePassword) errorMessages.add(_validPassword);

    return errorMessages.join("\n").trim();
  }

  String get _validName => name.isNotEmpty ? "" : "Name can't be empty";

  String get _validEmail =>
      email.isNotEmpty && email.contains("@") ? "" : "Must be a valid email";

  String get _validPassword => _password!.isNotEmpty && _password!.length > 6
      ? ""
      : "Password must have at least 6 characters";

  Map<String, dynamic> toMap() {
    return {"name": name, "email": email, "isDriver": isDriver};
  }

  String get userType => isDriver ? "Driver" : "Passenger";

  String get password => _password ?? "";
}
