import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telegramchatapp/Pages/HomePage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth fireBaseAuth = FirebaseAuth.instance;
  SharedPreferences sharedPreferences;

  bool isLoggedIn = false;
  bool isLoading = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    isSignedin();
  }
    void isSignedin() async{
      setState(() {
        isLoggedIn = true;
      });
      sharedPreferences = await SharedPreferences.getInstance();
      isLoggedIn = await googleSignIn.isSignedIn();
      if(isLoggedIn){
        Navigator.push(context, MaterialPageRoute(builder: (_)=>HomeScreen(currentUserId:sharedPreferences.getString("id"))));
      }
      setState(() {
        isLoggedIn = false;
      });
    }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Colors.purpleAccent, Colors.blueAccent])),
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Let's chat",
                    style: TextStyle(
                      fontSize: 80,
                      color: Colors.white,
                    )),
                GestureDetector(
                    onTap: () => controlSignIn(),
                    child: Column(
                      children: [
                        Container(
                          width: 270,
                          height: 65,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage("assets/images/google_signin_button.png"),
                                  fit: BoxFit.cover)),
                        ),
                        Padding(
                            padding: EdgeInsets.all(1.0), child: isLoading ? circularProgress() : Container())
                      ],
                    ))
              ],
            )));
  }

  Future<Null> controlSignIn() async {
    setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuthentication = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
        idToken: googleAuthentication.idToken, accessToken: googleAuthentication.accessToken);
    FirebaseUser firebaseUser = (await fireBaseAuth.signInWithCredential(credential)).user;
    if (firebaseUser != null) {
      //check if already signup
      final QuerySnapshot resultQuery = await Firestore.instance
          .collection("users")
          .where("id", isEqualTo: firebaseUser.uid)
          .getDocuments();
      final List<DocumentSnapshot> documentSnapshots = resultQuery.documents;

      //save data if new user
      if (documentSnapshots.length == 0) {
        Firestore.instance.collection("users").document(firebaseUser.uid).setData({
          "name": firebaseUser.displayName,
          "photoUrl": firebaseUser.photoUrl,
          "id": firebaseUser.uid,
          "createdAt": DateTime.now().millisecondsSinceEpoch.toString(),
          "chattingWith": null
        });

        //save to local
        currentUser = firebaseUser;
        await sharedPreferences.setString("id", currentUser.uid);
        await sharedPreferences.setString("name", currentUser.displayName);
        await sharedPreferences.setString("photoUrl", currentUser.photoUrl);
      } else {
        currentUser = firebaseUser;
        await sharedPreferences.setString("id", documentSnapshots[0]["id"]);
        await sharedPreferences.setString("name", documentSnapshots[0]["name"]);
        await sharedPreferences.setString("photoUrl", documentSnapshots[0]["photoUrl"]);
      }
         Fluttertoast.showToast(msg: "Congratulations. Sign In successfull");
     setState(() {
       isLoading = false;
     });

      Navigator.push(context, MaterialPageRoute(builder: (_)=>HomeScreen(currentUserId:firebaseUser.uid)));
    } else {
      Fluttertoast.showToast(msg: "Try again signin failed");
      setState(() {
        isLoading = false;
      });
    }
  }
}
