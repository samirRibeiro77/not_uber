class UberUser {
  String name;
  String email;
  String? _password;
  bool isDriver;

  UberUser({
    required this.name,
    required this.email,
    required this.isDriver,
    String password = "",
  }) {
    _password = password;
  }

  String validateUser() {
    var errorMessages = [];

    if (name.isEmpty) {
      errorMessages.add("Name can't be empty");
    }

    if (email.isEmpty) {
      errorMessages.add("Email can't be empty");
    }
    if (email.isNotEmpty && !email.contains("@")) {
      errorMessages.add("Must be a valid email");
    }

    if (_password!.isEmpty) {
      errorMessages.add("Password can't be empty");
    }

    return errorMessages.join("\n");
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "email": email,
      "isDriver": isDriver,
    };
  }

  String get userType => isDriver ? "Driver" : "Passenger";

  String get password => _password ?? "";
}
