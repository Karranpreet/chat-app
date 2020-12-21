import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullPhoto extends StatelessWidget {
  String photoUrl;
  FullPhoto({this.photoUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.lightBlue),
      body: FullPhotoScreen(url: photoUrl),
    );
  }
}

class FullPhotoScreen extends StatefulWidget {
  String url;
  FullPhotoScreen({this.url});
  @override
  State createState() => FullPhotoScreenState();
}

class FullPhotoScreenState extends State<FullPhotoScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: PhotoView(
        imageProvider: NetworkImage(widget.url),
      ),
    );
  }
}
