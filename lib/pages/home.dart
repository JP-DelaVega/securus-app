import 'dart:io';
import 'package:blackfox/pages/newsfeed.dart';
import 'package:flutter_screen_scaler/flutter_screen_scaler.dart';
import 'package:flutter/material.dart';

import 'package:outline_material_icons/outline_material_icons.dart';
import '../models/user.dart';
import './account.dart';
import './maps.dart';
import './activity_feed.dart';
import './report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final markersRef = Firestore.instance.collection('markers');
final tokensRef = Firestore.instance.collection('tokens');
final newsFeedRef = Firestore.instance.collection('newsfeed');
//final nearby = Firestore.instance.collection('nearby');
final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
  String tokens;
  String username;

  @override
  void initState() {
    super.initState();

    //get tokens
    _firebaseMessaging.getToken().then((token) {
      tokens = token;
      print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + tokens);
      //enX-t2BN7qc:APA91bEvAcOLGuV4kcJu73x4PYB77Q2YIe0ZMLimj1mc-V5W4ppi61Wk7N32pJa603QcVh7oSfmXg7uk_HRPxXmwm3ewfUaeM4TRzf8DCRjLNqR38gh-r_SXymZUd6XLlN-gBbXF1jJ_
    });

    pageController = PageController();
    // Detects when user signed in
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
      print('Error signing in: $err');
    });
    // Reauthenticate user when app is opened
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print('Error signing in: $err');
    });
  }

  handleSignIn(GoogleSignInAccount account) async {
    // If account is not on the database then create new user on firebase
    if (account != null) {
      //print('User signed in!: $account');
      await createUserInFireStore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotifications() {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getiOSPermission();

    _firebaseMessaging.getToken().then((token) {
      print("Firebase Messaging Token: $token\n");
      usersRef
          .document(user.id)
          .updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (/*Map<String, dynamic>*/ message) async {
        print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          print("Notification shown!");
          SnackBar snackbar = SnackBar(
              content: Text(
            body,
            overflow: TextOverflow.ellipsis,
          ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notification NOT shown");
      },
    );
  }

  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }

  createUserInFireStore() async {
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef
        .document(user.id)
        .get(); // get the user.id of the google account

    // if an email currently has no given username, then go to CreatePage()
    if (!doc.exists) {
      // obtain the following datails from the google account
      usersRef.document(user.id).setData({
        "id": user.id,
        "username": user.displayName,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp,
        //"token": tokens
        //"token": _messaging.getToken()
      });

      tokensRef.document(user.id).setData({"id": user.id, "token": tokens});

      doc = await usersRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
      //loadMarkerFeed();
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 1),
      curve: Curves.linear,
    );
  }

  Scaffold buildAuthScreen() {
    ScreenScaler scaler = ScreenScaler()..init(context);
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Profile(profileId: currentUser?.id),
          News(profileId: currentUser?.id), //SosPage(),
          MapPage(
              currentUser:
                  currentUser), //(userLat: latitude, userLng: longitude),
          ActivityFeed(),
          ReportPage(currentUser: currentUser),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: pageIndex,
          onTap: onTap,
          selectedItemColor: Colors.blue,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          //iconSize: 10,
          backgroundColor:
              Color(0xff1a1a1a), //Colors.grey[900], //Colors.grey[900],
          unselectedItemColor: Colors.grey[300],
          selectedFontSize: scaler.getTextSize(8),
          unselectedFontSize: scaler.getTextSize(8),
          items: [
            BottomNavigationBarItem(
              icon: pageIndex == 0
                  ? Icon(Icons.person)
                  : Icon(Icons.person_outline),
              title: Text('Account'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.question_answer),
              //: Icon(OMIcons.home), //OMIcons.home;
              title: Text('News Feed'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              //: Icon(OMIcons.home), //OMIcons.home;
              title: Text('Home'),
            ),
            BottomNavigationBarItem(
              icon: pageIndex == 3
                  ? Icon(Icons.notifications)
                  : Icon(Icons.notifications_none),
              title: Text('Notifications'),
            ),
            BottomNavigationBarItem(
              icon: pageIndex == 4 ? Icon(Icons.add_box) : Icon(OMIcons.addBox),
              title: Text('Report'),
            ),
          ]),
    );
  }

  Scaffold buildUnAuthScreen() {
    ScreenScaler scaler = ScreenScaler()..init(context);
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [Colors.grey[800], Colors.black],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        )),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
                height: scaler.getHeight(50),
                width: scaler.getWidth(50),
                child: Image.asset('assets/log_in_logo.png')),
            SizedBox(height: scaler.getHeight(10)),
            GestureDetector(
              onTap: login,
              child: Container(
                height: scaler.getHeight(30),
                width: scaler.getWidth(55),
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/google_signin_button.png'),
                      fit: BoxFit.contain),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
