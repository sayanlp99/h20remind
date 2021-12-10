import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:h20remind/screens/dashboard.dart';
import 'package:h20remind/screens/login.dart';
import 'package:intl/intl.dart';

final drinkRef = FirebaseFirestore.instance
    .collection(googleSignIn.currentUser!.email.toString());

class Upload extends StatefulWidget {
  Upload({Key? key}) : super(key: key);

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  final TextEditingController drinkController = TextEditingController();
  bool submitting = false;
  bool error = false;

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(
          color: Colors.black,
        ),
        title: const Text(
          'Add',
          style: TextStyle(color: Colors.black),
        ),
        flexibleSpace: Container(
          color: Colors.white,
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              child: TextField(
                controller: drinkController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    suffixText: "ml",
                    labelText: "Water Quantity",
                    border: OutlineInputBorder()),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    submitData(drinkController.text);
                  },
                  child: const Text("Add"),
                ),
                const SizedBox(
                  width: 25,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void submitData(String quantity) async {
    if (quantity.isEmpty || quantity == "") {
      setState(() {
        error = true;
        submitting = false;
      });
    } else {
      drinkRef.add({
        "drank": quantity,
        "time": DateFormat('jm').format(DateTime.now()).toString(),
        "date": DateFormat('dd-MM-yyyy').format(DateTime.now()).toString(),
      });
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const Dashboard(),
          ),
          (Route<dynamic> route) => false);
      setState(() {
        submitting = false;
      });
    }
  }
}
