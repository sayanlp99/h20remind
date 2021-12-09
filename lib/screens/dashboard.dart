import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:h20remind/screens/login.dart';
import 'package:h20remind/screens/upload.dart';
import 'package:h20remind/widgets/h20remind_drawer.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';

late Map<String, double> dataMap;
late String drankPercent;
late double goal;
late double drank;
late double left;
late String now_date;

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    drankPercent = "0%";
    goal = 3000;
    drank = 0;
    now_date = DateFormat('dd-MM-yyyy').format(DateTime.now()).toString();
    left = goal - drank;
    dataMap = {
      "drank": drank,
      "notdrank": left,
    };
    updatePieChart();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        now_date = DateFormat('dd-MM-yyyy').format(DateTime.now()).toString();
        debugPrint("Date: " + now_date);
      });
    }
  }

  void updatePieChart() {
    FirebaseFirestore.instance
        .collection('track')
        .where('user_date',
            isEqualTo:
                googleSignIn.currentUser!.email.toString() + "_" + now_date)
        .snapshots()
        .listen((snapshot) {
      double tempTotal = snapshot.docs
          .fold(0, (drank, doc) => drank + double.parse(doc.data()['drank']));
      setState(() {
        drank = tempTotal;
        left = goal - drank;
        drankPercent = ((drank * 100) / goal).toStringAsFixed(0) + "%";
        dataMap = {
          "drank": drank,
          "notdrank": left,
        };
      });
      debugPrint(drank.toString());
      debugPrint(dataMap.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: h20remindDrawer(context),
      appBar: AppBar(
        title: const Text('h20remind'),
        flexibleSpace: Container(
          color: Colors.lightBlueAccent,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Container(
            margin: const EdgeInsets.all(10),
            child: Column(
              children: [
                Card(
                  elevation: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(20),
                        child: PieChart(
                          initialAngleInDegree: 270,
                          centerText: drankPercent,
                          chartValuesOptions: const ChartValuesOptions(
                            showChartValues: false,
                          ),
                          dataMap: dataMap,
                          chartType: ChartType.ring,
                          colorList: const [
                            Colors.lightBlueAccent,
                            Colors.grey,
                          ],
                          chartRadius: 100,
                          legendOptions: const LegendOptions(
                            showLegends: false,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Goal: $goal ml"),
                          Text("Drank: $drank ml"),
                          Text("Left: $left ml"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("track")
                      .where('user_date',
                          isEqualTo:
                              googleSignIn.currentUser!.email.toString() +
                                  "_" +
                                  now_date)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Something went wrong"),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("Drink some water"),
                      );
                    }
                    if (snapshot.hasData) {
                      return ListView(
                        physics: const ScrollPhysics(),
                        shrinkWrap: true,
                        children:
                            snapshot.data!.docs.map((DocumentSnapshot ds) {
                          Map<String, dynamic> data =
                              ds.data() as Map<String, dynamic>;
                          return ListTile(
                              title: Text(data['drank'] + " ml"),
                              subtitle: Text(data['date'] + " " + data['time']),
                              trailing: const Icon(
                                Icons.opacity,
                                color: Colors.lightBlueAccent,
                              ));
                        }).toList(),
                      );
                    }
                    return Container();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlueAccent,
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Upload()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }
}
