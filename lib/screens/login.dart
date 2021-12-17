import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:h20remind/screens/dashboard.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isAuth = false;
  late PageController pageController;
  int pageIndex = 0;
  bool loading = true;

  handleSignIn(GoogleSignInAccount account) {
    if (account != null) {
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
    setState(() {
      loading = false;
    });
  }

  login() {
    googleSignIn.signIn();
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account!);
    }, onError: (err) {});
    googleSignIn.signInSilently(suppressErrors: true).then((account) {
      handleSignIn(account!);
    }).catchError((err) {});
    setState(() {
      loading = false;
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Scaffold signedOutUser() {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(15),
        child: MediaQuery.of(context).size.width < 600
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  signedOutUserOne(),
                  signedOutUserTwo(),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  signedOutUserOne(),
                  const SizedBox(
                    width: 20,
                  ),
                  signedOutUserTwo(),
                ],
              ),
      ),
    );
  }

  Container signedOutUserOne() {
    return Container(
      margin: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.opacity_outlined,
            size: 100,
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            "h20remind",
            style: TextStyle(
              fontFamily: "Poppins",
              fontWeight: FontWeight.w600,
              fontSize: 30,
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: const Text(
              "Keep track of your water input on all of your devices",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "Poppins"),
            ),
          ),
        ],
      ),
    );
  }

  Container signedOutUserTwo() {
    return Container(
      padding: const EdgeInsets.only(top: 60),
      child: ElevatedButton(
        onPressed: () {
          debugPrint("Sign in");
          login();
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            Colors.lightBlueAccent,
          ),
        ),
        child: const Text(
          "Sign in",
          style: TextStyle(fontFamily: "Poppins"),
        ),
      ),
    );
  }

  Container loadingUserScreen() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 10.0),
      child: const CircularProgressIndicator(
        color: Colors.lightBlueAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isAuth == true) {
      return const Dashboard();
    } else {
      return signedOutUser();
    }
  }
}
