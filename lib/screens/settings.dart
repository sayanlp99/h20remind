import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:h20remind/screens/dashboard.dart';
import 'package:h20remind/screens/login.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

double goal = 0.0;
TextEditingController goalController = TextEditingController();

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Settings> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    getGoalFromFirestore();
    Future.delayed(const Duration(seconds: 2), () {});
  }

  void getGoalFromFirestore() {
    FirebaseFirestore.instance
        .collection(googleSignIn.currentUser!.email.toString())
        .doc("goal")
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        debugPrint('Document data: ${documentSnapshot.data()}');
        Map<String, dynamic> data =
            documentSnapshot.data()! as Map<String, dynamic>;
        setState(() {
          goal = double.parse(data['goal']);
        });
      } else {
        debugPrint('Document does not exist on the database');
      }
    });
  }

  openGoalSetter(context) {
    Alert(
        context: context,
        title: "Set Goal",
        content: Column(
          children: <Widget>[
            const SizedBox(
              height: 10,
            ),
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Goal',
                suffixText: "ml",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection(googleSignIn.currentUser!.email.toString())
                  .doc("goal")
                  .set({"goal": goalController.text});
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Dashboard(),
                  ),
                  (Route<dynamic> route) => false);
            },
            child: const Text(
              "SET",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
        ]).show();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getGoalFromFirestore();
    }
  }

  Container settingsOne() {
    return Container(
      margin: const EdgeInsets.all(10),
      child: ListView(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        children: [
          ListTile(
            title: const Text("Set Goal"),
            trailing: Text(goal.toString() + " ml"),
            onTap: () => openGoalSetter(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(
          color: Colors.black,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        flexibleSpace: Container(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: MediaQuery.of(context).size.width < 600
              ? Column(
                  children: [
                    settingsOne(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: (MediaQuery.of(context).size.width / 2) - 10,
                      child: settingsOne(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
