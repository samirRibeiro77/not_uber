import 'package:flutter/material.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordObscure = true;
  bool _isDriver = false;
  String _errorMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registration"),
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
      ),
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
                filled: true,
                fillColor: Colors.white,
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
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff1ebbd8),
                padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Sign up",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            SizedBox(child: Container(height: 32)),
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
