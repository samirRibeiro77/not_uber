import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/route_generator.dart';
import 'package:not_uber/src/model/uber_user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordObscure = true;
  String _errorMessage = "";
  bool _loading = false;

  _validateFields() {
    setState(() {
      _loading = true;
    });

    var user = UberUser(
      email: _emailController.text,
      password: _passwordController.text,
    );

    var error = user.validateUser(validateName: false);
    if (error.isNotEmpty) {
      setState(() {
        _errorMessage = error;
        _loading = false;
      });
      return;
    }

    _login(user);
  }

  _login(UberUser user) {
    _auth
        .signInWithEmailAndPassword(email: user.email, password: user.password)
        .then((fbUser) {
          _getUserData(fbUser.user!.uid);
        })
        .catchError((e) {
          setState(() {
            _errorMessage = "Check your email and password, then try again";
            _loading = false;
          });
        });
  }

  _getUserData(String uid) async {
    var snapshot = await _db
        .collection(FirebaseHelper.collections.user)
        .doc(uid)
        .get();

    var user = UberUser.fromFirebase(map: snapshot.data());

    _goToHome(user.isDriver);
  }

  _goToHome(bool isDriver) {
    setState(() {
      _loading = false;
    });

    var homePage = isDriver
        ? RouteGenerator.driverHome
        : RouteGenerator.passengerHome;

    Navigator.pushReplacementNamed(context, homePage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset("assets/images/logo.png", width: 200, height: 150),
                _loading
                    ? CircularProgressIndicator(backgroundColor: Colors.white)
                    : Container(),
                SizedBox(child: Container(height: 32)),
                TextField(
                  controller: _emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    hintText: "E-mail",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                SizedBox(child: Container(height: 8)),
                TextField(
                  controller: _passwordController,
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _passwordObscure,
                  style: TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    hintText: "Password",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    suffixIcon: IconButton(
                      padding: EdgeInsets.only(right: 8),
                      icon: Icon(
                        _passwordObscure
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordObscure = !_passwordObscure;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(child: Container(height: 16)),
                ElevatedButton(
                  onPressed: _validateFields,
                  child: Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
                SizedBox(child: Container(height: 8)),
                Center(
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, RouteGenerator.register),
                    child: Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
                SizedBox(child: Container(height: 16)),
                Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
