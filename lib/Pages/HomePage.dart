import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telegramchatapp/Models/user.dart';
import 'package:telegramchatapp/Pages/ChattingPage.dart';
import 'package:telegramchatapp/Pages/AccountSettingsPage.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;
  HomeScreen({this.currentUserId});
  @override
  State createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  TextEditingController searchText = TextEditingController();
  Future<QuerySnapshot> futureSearchResult;
  Future<QuerySnapshot> allUsers = Firestore.instance.collection("users").getDocuments();
  homePageHeader() {
    return AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: Icon(Icons.settings, size: 30, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Settings())))
        ],
        title: Container(
          margin: EdgeInsets.only(bottom: 4.0),
          child: TextFormField(
            style: TextStyle(fontSize: 18, color: Colors.white),
            controller: searchText,
            decoration: InputDecoration(
                hintText: "Search here ...",
                hintStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                filled: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white,
                  ),
                  onPressed: () => searchText.clear(),
                )),
            onFieldSubmitted: controlSearching,
          ),
        ));
  }

  controlSearching(String userName) {
    Future<QuerySnapshot> allFoundUsers =
        Firestore.instance.collection("users").where("name", isGreaterThanOrEqualTo: userName.toUpperCase()).where("name", isLessThanOrEqualTo: userName.toLowerCase()).getDocuments();
    setState(() {
      futureSearchResult = allFoundUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: homePageHeader(),
      body: futureSearchResult == null ? displayNoSearchResultScreen() : displaySearchResultScreen(),
    );
  }

  displayNoSearchResultScreen() {
     
    return FutureBuilder(
        future: allUsers,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          List<UserResult> searchResult = [];
          snapshot.data.documents.forEach((document) {
            User eachUser = User.fromDocument(document);
            UserResult userResult = UserResult(eachUser);
            if (widget.currentUserId != document['id']) {
              searchResult.add(userResult);
            }
          });
          return ListView(children: searchResult);
        });
  
    // return Container(
    //   child: Center(
    //       child: ListView(shrinkWrap: true, children: [
    //     Icon(
    //       Icons.group,
    //       color: Colors.lightBlueAccent,
    //       size: 200,
    //     ),
    //     Text(
    //       "Search Users",
    //       textAlign: TextAlign.center,
    //       style: TextStyle(fontSize: 50, color: Colors.lightBlueAccent),
    //     )
    //   ])),
    // );
  }

  displaySearchResultScreen() {
    return FutureBuilder(
        future: futureSearchResult,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          List<UserResult> searchResult = [];
          snapshot.data.documents.forEach((document) {
            User eachUser = User.fromDocument(document);
            UserResult userResult = UserResult(eachUser);
            if (widget.currentUserId != document['id']) {
              searchResult.add(userResult);
            }
          });
          return ListView(children: searchResult);
        });
  }
  // final GoogleSignIn googleSignIn = GoogleSignIn();
  // Future<Null> logoutuser() async {
  //   await FirebaseAuth.instance.signOut();
  //   await googleSignIn.disconnect();
  //   await googleSignIn.signOut();
  //   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
  // }
}

class UserResult extends StatelessWidget {
  final User eachUser;
  UserResult(this.eachUser);
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(4.0),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              InkWell( onTap: ()=>  Navigator.push(context, MaterialPageRoute(builder: (_) => Chat(id: eachUser.id,name: eachUser.name,photoUrl: eachUser.photoUrl,))),
                  child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.black,
                    backgroundImage: CachedNetworkImageProvider(eachUser.photoUrl)),
                title: Text(
                  eachUser.name,
                  style: TextStyle(color: Colors.black),
                ),
              ))
            ],
          ),
        ));
  }
}
