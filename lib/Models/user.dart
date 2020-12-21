import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String name;
  final String photoUrl;
  final String createdAt;

  User({
    this.id,
    this.name,
    this.photoUrl,
    this.createdAt,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc.documentID,
      photoUrl: doc['photoUrl'],
      name: doc['name'],
      createdAt: doc['createdAt'],
    );
  }
}