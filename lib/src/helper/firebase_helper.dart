class FirebaseHelper {
  static FirebaseHelpersCollections collections =
      const FirebaseHelpersCollections();
}

class FirebaseHelpersCollections {
  const FirebaseHelpersCollections();

  String get user => "Uber-User";

  String get request => "Uber-Request";

  String get activeRequest => "Uber-Active-Request";
}
