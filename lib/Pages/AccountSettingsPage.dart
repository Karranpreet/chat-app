import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:telegramchatapp/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          "Account Settings",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TextEditingController nameEdit;
  SharedPreferences preferences;
  String id = "";
  String name = "";
  String photoUrl = "";
  bool isLoading = false;
  File imageAvatar;
  final FocusNode nameFocusNode = FocusNode();
  @override
  void initState() {
    readDataFromLocal();
    // TODO: implement initState
    super.initState();
  }

  Future getImage() async {
    File imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() {
        imageAvatar = imageFile;
        isLoading = true;
      });
      uploadImagetoFireStoreAndStorage();
    }
  }

  Future uploadImagetoFireStoreAndStorage() async {
    StorageReference storage = FirebaseStorage.instance.ref().child(id);
    StorageUploadTask storageuploadTask = storage.putFile(imageAvatar);
    StorageTaskSnapshot snapshot;
    storageuploadTask.onComplete.then((value) {
      if (value.error == null) {
        snapshot = value;
        snapshot.ref.getDownloadURL().then((value) {
          photoUrl = value;
          Firestore.instance
              .collection("users")
              .document(id)
              .updateData({"photoUrl": photoUrl}).then((value) async {
            await preferences.setString("photoUrl", photoUrl);
            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Updated Succesfully!");
          });
        }, onError: (errorMsg) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: errorMsg.toString());
        });
      }
    });
  }

  updateData() {
    nameFocusNode.unfocus();
    setState(() {
      isLoading = false;
    });
    Firestore.instance
        .collection("users")
        .document(id)
        .updateData({"photoUrl": photoUrl}).then((value) async {
      await preferences.setString("photoUrl", photoUrl);
      await preferences.setString("name", name);

      Fluttertoast.showToast(msg: "Updated Succesfully!");
    });
  }

  void readDataFromLocal() async {
    preferences = await SharedPreferences.getInstance();
    id = preferences.getString("id");
    name = preferences.getString("name");
    photoUrl = preferences.getString("photoUrl");
    nameEdit = TextEditingController(text: name);
    setState(() {});
  }

  final GoogleSignIn googleSignIn = GoogleSignIn();
  Future<Null> logoutuser() async {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
            child: Center(
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.start,crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              (imageAvatar == null)
                  ? (photoUrl != "")
                      ? Material(
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                              width: 200,
                              height: 200,
                            ),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(125.5)),
                        )
                      : Icon(Icons.account_circle, color: Colors.grey)
                  : Material(
                      child: Image.file(
                        imageAvatar,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(125.5))),
              IconButton(
                icon: Icon(
                  Icons.camera_alt,
                  size: 100,
                  color: Colors.grey,
                ),
                onPressed: getImage,
                padding: EdgeInsets.all(0.0),
                iconSize: 200,
              ),
              Column(children: [
                Padding(
                  padding: EdgeInsets.all(1.0),
                  child: isLoading ? circularProgress() : Container(),
                ),
                Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: TextField(
                      decoration: InputDecoration(hintText: "karan .."),
                      controller: nameEdit,
                      onChanged: (value) {
                        name = value;
                      },
                      focusNode: nameFocusNode,
                    ))
              ]),
              SizedBox(
                height: 20,
              ),
              Container(
                color: Colors.blueAccent,
                child: FlatButton(
                  child: Text(
                    "Update",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  color: Colors.blueAccent,
                  padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                  onPressed: updateData,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                  padding: EdgeInsets.only(left: 50, right: 50),
                  child: RaisedButton(
                      color: Colors.red,
                      child: Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: logoutuser))
            ],
          ),
        ))
      ],
    );
  }
}
