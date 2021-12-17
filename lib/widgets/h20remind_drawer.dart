import 'package:flutter/material.dart';
import 'package:h20remind/screens/login.dart';
import 'package:h20remind/screens/report.dart';
import 'package:h20remind/screens/settings.dart';

Drawer h20remindDrawer(context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.lightBlueAccent,
          ),
          child: Container(
            margin: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  child: ClipOval(
                    child: Image.network(
                      googleSignIn.currentUser!.photoUrl.toString(),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  googleSignIn.currentUser!.displayName.toString(),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.15,
                  ),
                ),
                Text(
                  googleSignIn.currentUser!.email.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          title: Row(
            children: const [
              Icon(
                Icons.settings,
              ),
              SizedBox(
                width: 25,
              ),
              Text('Settings')
            ],
          ),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Settings()));
          },
        ),
        ListTile(
          title: Row(
            children: const [
              Icon(Icons.assessment),
              SizedBox(
                width: 25,
              ),
              Text('Report')
            ],
          ),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Report()));
          },
        ),
        ListTile(
          title: Row(
            children: const [
              Icon(
                Icons.logout,
              ),
              SizedBox(
                width: 25,
              ),
              Text('Logout')
            ],
          ),
          onTap: () {
            googleSignIn.signOut();
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const Login(),
                ),
                (Route<dynamic> route) => false);
          },
        ),
      ],
    ),
  );
}
