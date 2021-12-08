import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import './home.dart';
import '../widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  CommentsState({
    this.postId,
    this.postOwnerId,
    this.postMediaUrl,
  });

  buildComments() {
    return StreamBuilder(
        stream: commentsRef
            .document(postId)
            .collection('comments')
            .orderBy("timestamp", descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<Comment> comments = [];
          snapshot.data.documents.forEach((doc) {
            comments.add(Comment.fromDocument(doc));
          });
          return ListView(
            children: comments,
          );
        });
  }

  addComment() {
    if (commentController.text.length > 2) {
      commentsRef.document(postId).collection("comments").add({
        "username": currentUser.username,
        "comment": commentController.text,
        "timestamp": timestamp,
        "avatarUrl": currentUser.photoUrl,
        "userId": currentUser.id,
      });

      activityFeedRef.document(postOwnerId).collection('feedItems').add({
        "type": "comment",
        "commentData": commentController.text,
        "timestamp": timestamp,
        "postId": postId,
        "userId": currentUser.id,
        "username": currentUser.username,
        "userProfileImg": currentUser.photoUrl,
        "mediaUrl": postMediaUrl,
      });
      commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments',
            style: TextStyle(color: Colors.grey[200], fontSize: 20.0)),
        backgroundColor: Colors.black12,
      ),
      backgroundColor: Colors.grey[900],
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(currentUser.photoUrl),
            ),
            title: TextFormField(
              validator: (value) {
                if (value.isEmpty || value.length < 8) {
                  return "Details must be at least 8 characters long.";
                }
                return null;
              },
              autovalidate: false,
              controller: commentController,
              style: TextStyle(color: Colors.grey[200]),
              decoration: InputDecoration(
                  labelText: "Add a comment...",
                  labelStyle: TextStyle(color: Colors.grey[200])),
            ),
            trailing: OutlineButton(
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text("Post",
                  style: TextStyle(color: Colors.blue, fontSize: 15.0)),
            ),
          ),
          SizedBox(
            height: 5.0,
          )
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    this.username,
    this.userId,
    this.avatarUrl,
    this.comment,
    this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
      avatarUrl: doc['avatarUrl'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            username + ' • ' + timeago.format(timestamp.toDate()),
            style: TextStyle(color: Colors.grey[400], fontSize: 12.0),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(
            comment,
            style: TextStyle(color: Colors.grey[100], fontSize: 15.0),
          ),
        ),
        Divider(),
      ],
    );
  }
}
