import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:not_uber/src/helper/firebase_helper.dart';
import 'package:not_uber/src/helper/route_generator.dart';
import 'package:not_uber/src/model/uber_user.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordObscure = true;
  bool _isDriver = false;
  bool _loading = false;
  String _errorMessage = "";

  _validateFields() {
    setState(() {
      _loading = true;
    });
    var user = UberUser(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      isDriver: _isDriver,
    );

    var error = user.validateUser();
    if (error.isNotEmpty) {
      setState(() {
        _errorMessage = error;
        _loading = false;
      });
      return;
    }

    _createUser(user);
  }

  _createUser(UberUser user) {
    _auth
        .createUserWithEmailAndPassword(
          email: user.email,
          password: user.password,
        )
        .then((fbUser) {
          _saveUser(firebaseUser: fbUser.user!, uberUser: user);
        })
        .catchError((e) {
          setState(() {
            _errorMessage = "Error creating user: ${e.toString()}";
            _loading = false;
          });
        });
  }

  _saveUser({required User firebaseUser, required UberUser uberUser}) {
    _db
        .collection(FirebaseHelper.collections.user)
        .doc(firebaseUser.uid)
        .set(uberUser.toJson());

    _goToHome(uberUser.isDriver);
  }

  _goToHome(bool isDriver) {
    setState(() {
      _loading = false;
    });

    var homePage = isDriver
        ? RouteGenerator.driverHome
        : RouteGenerator.passengerHome;

    Navigator.pushNamedAndRemoveUntil(context, homePage, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registration")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                hintText: "Full name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            SizedBox(child: Container(height: 8)),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                hintText: "E-mail",
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                suffixIcon: IconButton(
                  padding: EdgeInsets.only(right: 8),
                  icon: Icon(
                    _passwordObscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordObscure = !_passwordObscure;
                    });
                  },
                ),
              ),
            ),
            SizedBox(child: Container(height: 8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Passenger"),
                Switch(
                  value: _isDriver,
                  onChanged: (value) {
                    setState(() {
                      _isDriver = value;
                    });
                  },
                ),
                Text("Driver"),
              ],
            ),
            SizedBox(child: Container(height: 16)),
            ElevatedButton(
              onPressed: _validateFields,
              child: Text(
                "Sign up",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            SizedBox(child: Container(height: 32)),
            _loading
                ? Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.white,
                      ),
                    ),
                  )
                : Container(),
            Center(
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
