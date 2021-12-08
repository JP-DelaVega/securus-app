import 'package:blackfox/widgets/post.dart';
import 'package:blackfox/widgets/progress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class News extends StatefulWidget {
  final String profileId;

  News({this.profileId});
  @override
  _NewsState createState() => _NewsState();
}

class _NewsState extends State<News> {
  List<Post> posts = [];
  bool isLoading = false;
  int postCount = 0;

  @override
  void initState() {
    super.initState();
    getProfilePosts();
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else {
      return ListView(
        children: posts,
      );
    }
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await newsFeedRef
        .document('getAllPost')
        .collection('allPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  /*getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(currentUser.id)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Newsfeed"),backgroundColor: Colors.black12, automaticallyImplyLeading: false,),
      backgroundColor: Colors.blueGrey[900],
      body: buildProfilePosts(),
    );
  }
}
