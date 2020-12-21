import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:telegramchatapp/Widgets/FullImageWidget.dart';
import 'package:telegramchatapp/Widgets/ProgressWidget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatelessWidget {
  String id;
  String photoUrl;
  String name;
  Chat({this.id, this.name, this.photoUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
                backgroundColor: Colors.black, backgroundImage: CachedNetworkImageProvider(photoUrl)),
          ),
        ],
        title: Text(name),
        centerTitle: true,
      ),
      body: ChatScreen(
        id: id,
        photoUrl: photoUrl,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  String id;
  String photoUrl;
  ChatScreen({this.photoUrl, this.id});

  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();
  FocusNode focusNode = FocusNode();
  bool isLoading;
  bool isDisplaaySticker;
  File imageFile;
  String imageUrl;
  String myId;
  String chatId;
  SharedPreferences preferences;
  var listMessages;

  @override
  void initState() {
    focusNode.addListener(onFocusChange);
    // TODO: implement initState
    isLoading = false;
    isDisplaaySticker = false;
    chatId = "";
    readLocal();
    super.initState();
  }

  readLocal() async {
    preferences = await SharedPreferences.getInstance();
    myId = preferences.getString("id") ?? "";
    if (myId.hashCode <= widget.id.hashCode) {
      chatId = "$myId-${widget.id}";
    } else {
      chatId = "${widget.id}-$myId";
    }
    Firestore.instance.collection("users").document(myId).updateData({"chattingWith": widget.id});
    setState(() {});
  }

  onFocusChange() {
    // hide sticker when keyboard open
    if (focusNode.hasFocus) {
      setState(() {
        isDisplaaySticker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Stack(
          children: [
            Column(
              children: [
                createListMessages(),
                isDisplaaySticker ? createStickers() : Container(),
                createInput()
              ],
            )
          ],
        ),
        onWillPop: backPress);
  }

  Future<bool> backPress() {
    if (isDisplaaySticker) {
      setState(() {
        isDisplaaySticker = false;
      });
    } else {
      Navigator.of(context).pop();
    }
    return Future.value(true);
  }

  createStickers() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.blueGrey[50], border: Border(top: BorderSide(color: Colors.grey, width: 0.5))),
      height: 100,
      padding: EdgeInsets.all(5.0),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FlatButton(
              child: Image.asset(
                "images/mimi1.gif",
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              onPressed: null,
            ),
            FlatButton(
              child: Image.asset(
                "images/mimi2.gif",
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              onPressed: null,
            ),
            FlatButton(
              child: Image.asset(
                "images/mimi3.gif",
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              onPressed: null,
            ),
          ],
        ),
      ]),
    );
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isDisplaaySticker = !isDisplaaySticker;
    });
  }

  createListMessages() {
    return Expanded(
      child: chatId.isEmpty
          ? Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder(
              stream: Firestore.instance
                  .collection("messages")
                  .document(chatId)
                  .collection(chatId)
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  listMessages = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) => createItem(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: scrollController,
                  );
                }
              }),
    );
  }

  createItem(int index, DocumentSnapshot document) {
    if (document['idFrom'] == myId) {
      return Padding(
        padding: const EdgeInsets.only(bottom:8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            document['type'] == 0
                ?
                // message
                Container(
                    child: Text(
                      document['content'],
                      style: TextStyle(color: Colors.white),
                    ),
                    padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                    width: 200,
                    decoration:
                        BoxDecoration(color: Colors.lightBlueAccent, borderRadius: BorderRadius.circular(15.0)),
                  )
                : document['type'] == 1
                    ?
                    //image
                    Container(
                        child: FlatButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => FullPhoto(photoUrl: document['content']))),
                            child: Material(
                                child: CachedNetworkImage(
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              imageUrl: document['content'],
                              placeholder: (context, url) => Container(
                                width: 200,
                                height: 200,
                                padding: EdgeInsets.all(70),
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Material(
                                child: Image.asset(
                                  "images/img_not_available.jpeg",
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              ),
                            ))),
                        // margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20 : 10, right: 10),
                      )
                    :
                    //sticker
                    Container(
                        child: Image.asset("images/${document['content']}.gif",
                            width: 100, height: 100, fit: BoxFit.cover),
                      )
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            document['type'] == 0
                ?
                // message
                Container(
                    
                    child: Text(
                      document['content'],
                      style: TextStyle(color: Colors.black),
                    ),
                    padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                    width: 200,
                    decoration:
                        BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(15.0)),
                  )
                : document['type'] == 1
                    ?
                    //image
                    Container(
                        child: FlatButton(
                            onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => FullPhoto(photoUrl: document['content']))),
                            child: Material(
                                child: CachedNetworkImage(
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              imageUrl: document['content'],
                              placeholder: (context, url) => Container(
                                width: 200,
                                height: 200,
                                padding: EdgeInsets.all(70),
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Material(
                                child: Image.asset(
                                  "images/img_not_available.jpeg",
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              ),
                            ))),
                        // margin: EdgeInsets.only(bottom: isLastMsgRight(index) ? 20 : 10, right: 10),
                      )
                    :
                    //sticker
                    Container(
                        child: Image.asset("images/${document['content']}.gif",
                            width: 100, height: 100, fit: BoxFit.cover),
                      )
          ],
        ),
      );
    }
  }

  Future getImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
    imageFile = File(pickedFile.path);
    if (imageFile != null) {
      uploadImageFile();
      // onSendMessage(message, 1)
    }
  }

  onSendMessage(String message, int type) {
    //0 msg
    //1 image
    //2 sticker
    if (message.isNotEmpty) {
      controller.clear();
      var docref = Firestore.instance
          .collection("messages")
          .document(chatId)
          .collection(chatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());
      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(docref, {
          "idFrom": myId,
          "idTo": widget.id,
          "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
          "content": message,
          "type": type
        });
      });
      scrollController.animateTo(0.0, duration: Duration(microseconds: 300), curve: Curves.easeOut);
    }
  }

  uploadImageFile() {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference storage = FirebaseStorage.instance.ref().child("chat images").child(fileName);
    StorageUploadTask storageuploadTask = storage.putFile(imageFile);
    StorageTaskSnapshot snapshot;
    storageuploadTask.onComplete.then((value) {
      if (value.error == null) {
        snapshot = value;
        snapshot.ref.getDownloadURL().then((downloadUrl) {
          imageUrl = downloadUrl;
          onSendMessage(imageUrl, 1);
        }
            //  {

            //   photoUrl = value;
            //   Firestore.instance
            //       .collection("users")
            //       .document(id)
            //       .updateData({"photoUrl": photoUrl}).then((value) async {
            //     await preferences.setString("photoUrl", photoUrl);
            //     setState(() {
            //       isLoading = false;
            //     });
            //     Fluttertoast.showToast(msg: "Updated Succesfully!");
            //   });
            // }
            , onError: (errorMsg) {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: errorMsg.toString());
        });
      }
    });
  }

  createInput() {
    return Container(
      child: Row(
        children: [
          Material(
            color: Colors.white,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(icon: Icon(Icons.image), onPressed: getImage),
            ),
          ),
          Material(
            color: Colors.white,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(icon: Icon(Icons.face), onPressed: getSticker),
            ),
          ),
          Flexible(
              child: Container(
            child: TextField(
              focusNode: focusNode,
              style: TextStyle(color: Colors.black, fontSize: 15.0),
              controller: controller,
              decoration: InputDecoration.collapsed(hintText: "write here..."),
            ),
          )),
          InkWell(
            child: Material(
              color: Colors.white,
              child: Container(margin: EdgeInsets.symmetric(horizontal: 1.0), child: Icon(Icons.send)),
            ),
            onTap: () => onSendMessage(controller.text, 0),
          ),
        ],
      ),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
    );
  }
}
