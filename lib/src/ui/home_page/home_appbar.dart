import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:not_uber/src/helper/route_generator.dart';

class HomeAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  HomeAppbar({super.key, required this.title});

  final _auth = FirebaseAuth.instance;

  final _menuItems = ["Settings", "Logout"];

  _menuSelected(BuildContext context, String selectedMenu) {
    switch(selectedMenu) {
      case "Settings":
        break;
      case "Logout":
        _auth.signOut();
        Navigator.pushReplacementNamed(context, RouteGenerator.login);
        break;
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        PopupMenuButton(
          onSelected: (selected) => _menuSelected(context, selected),
          itemBuilder: (context) {
            return _menuItems.map((String item) {
              return PopupMenuItem(value: item, child: Text(item));
            }).toList();
          },
        ),
      ],
    );
  }
}