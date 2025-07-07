import 'package:flutter/material.dart';
import 'package:not_uber/src/model/uber_request.dart';
import 'package:not_uber/src/splashscreen.dart';
import 'package:not_uber/src/ui/home_page/driver_home_page.dart';
import 'package:not_uber/src/ui/login_page.dart';
import 'package:not_uber/src/ui/home_page/passenger_home_page.dart';
import 'package:not_uber/src/ui/registration_page.dart';
import 'package:not_uber/src/ui/ride_page.dart';

class RouteGenerator {
  static const String initial = "/";
  static const String login = "/login";
  static const String register = "/register";
  static const String driverHome = "/driver_home";
  static const String passengerHome = "/passenger_home";
  static const String onTrip = "/on_a_trip";

  static Route<dynamic> generateRoutes(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case initial:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => RegistrationPage());
      case driverHome:
        return MaterialPageRoute(builder: (_) => DriverHomePage());
      case passengerHome:
        return MaterialPageRoute(builder: (_) => PassengerHomePage());
      case onTrip:
        return MaterialPageRoute(
          builder: (_) =>
              RidePage(request: routeSettings.arguments as UberRequest),
        );
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: Text("Page not found")),
          body: Center(child: Text("Error: This route does not exist")),
        );
      },
    );
  }
}
