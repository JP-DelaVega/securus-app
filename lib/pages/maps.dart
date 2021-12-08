import 'dart:io';
import 'dart:math';

import 'package:blackfox/models/user.dart';
import 'package:blackfox/pages/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//import '../widgets/post.dart';
import 'post_screen.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:firebase_messaging/firebase_messaging.dart';

//import '../requests/google_maps_requests.dart';

final postsRef2 = Firestore.instance.collection('posts');

class MapPage extends StatefulWidget {
  final User currentUser;

  MapPage({this.currentUser});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  //token
  final FirebaseMessaging _messaging = FirebaseMessaging();

  // GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  //static GoogleMap nmap = new GoogleMap(initialCameraPosition: null);
  GoogleMapController mapController;
  static LatLng _center;
  LatLng _lastPosition = _center; //initialposition
  static Set<Marker> _markers = {};
  static List _markers2 = [];
  List loadingMarkers = [];
  

  String _mapStyle;
  static Set<Circle> circles = {};
  static List getCoord = [];
  static List nearbyIncident = [];

  static LatLng user;

  File jsonFile;
  Directory dir;
  String fileName = "myFile.json";
  bool fileExists = false;

  Map<String, dynamic> fileContent;

  //static List color = ['0xFF003366', '0xFF663300', '0xFF006633'];

  createCircle(
      double lat, double long, double rad, Color strokeC, Color fillC) {
    return Circle(
      circleId: CircleId('a'),
      center: LatLng(lat, long),
      radius: rad,
//strokeColor: Color.fromRGBO(255, 0, 0, 0.1),
      // fillColor: Color.fromRGBO(255, 0, 0, 0.3),
      strokeColor: strokeC,
      fillColor: fillC,
      //fillColor: Colors.red
    );
  }

  circleCreate(double lat, double lng, String postId, String title) {
    //print("HAHAHAHAHAH: " + loadingMarkers.toString());
    //for (int i = 0; i < loadingMarkers.length; i++) {
    print("TRYRYT : " + (lat.toString() + ' ' + lng.toString()));
    List<String> redC = ['Murder', 'Hostage', 'Rape', 'Arson', 'Terrorism'];
    List<String> yellowC = ['Minor traffic incident', 'Theft', 'Street Fight'];
    List<String> orangeC = [
      'Epidemic outbreak',
      'Large Bldg fire',
      'Multi-house fire',
      'Multi-vehicle crashes'
    ];

    redC.forEach((element) => title == element
        ? circles.add(createCircle(lat, lng, 1000,
            Color.fromRGBO(255, 0, 0, 0.1), Color.fromRGBO(255, 0, 0, 0.3)))
        : yellowC.forEach((element) => title == element
            ? circles.add(createCircle(
                lat,
                lng,
                250,
                Color.fromRGBO(255, 255, 0, 0.1),
                Color.fromRGBO(255, 255, 0, 0.3)))
            : orangeC.forEach((element) => title == element
                ? circles.add(createCircle(
                    lat,
                    lng,
                    500,
                    Color.fromRGBO(255, 153, 51, 0.1),
                    Color.fromRGBO(255, 153, 51, 0.3)))
                : circles.add(createCircle(
                    lat,
                    lng,
                    250,
                    Color.fromRGBO(211, 211, 211, 0.1),
                    Color.fromRGBO(211, 211, 211, 0.3))))));

    getCoord.add([lat, lng, postId]);
  }

  notificationAlgo(List getCoord) async {
    Position pos = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double userLatitude = pos.latitude;
    //print("LAAAAATIIIII" + userLatitude.toString());
    double userLongitude = pos.longitude;
    //print("LAAAAATIIIII" + userLongitude.toString());

    //print(latitude.toString());
    getCoord.forEach((element) {
      //print(element);

      const double pi = 3.141592653589;
      double r = 6371e3;
      double lat1 = userLatitude * (pi / 180);
      double lng1 = userLongitude * (pi / 180);
      double difflat = (userLatitude - element[0]) * (pi / 180);
      double difflng = (userLongitude - element[1]) * (pi / 180);
      double a = sin(difflat / 2) * sin(difflat / 2) +
          cos(lat1) * cos(lng1) * sin(difflng / 2) * sin(difflng / 2);
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      double dist = r * c;
      // print("AAAAAAAAAAAAAAAA"+dist.toString());

      if (dist <= 1000 || dist.toString() == "NaN") {
        //print("NEARBY:" + dist.toString());
        print("POSTASDASDID : " + element[2].toString());
        //nearbyIncident.forEach((e) {element[2] != e?nearbyIncident.add(element[2]): print("QWERTY"+nearbyIncident.toString());});
        nearbyIncident.add(element[2]);
      }
      //print("NEARBYYYY: "+nearbyIncident.toString());
    });
    createPostInFirestore(nearbyIncident);
    
  }

  createPostInFirestore(List nearbyIncident) {
    //nearbyIncident = nearbyIncident
    var ids = nearbyIncident.toSet().toList();
    if(ids.isNotEmpty){
    SnackBar(content: Text("STAY ALERT! Incident nearby!"));
        
    print("NEARBYYYY: " + ids.toString());
    activityFeedRef
        .document(widget.currentUser.id)
        .collection('feedItems')
        .document(widget.currentUser.id)
        .delete();
    activityFeedRef
        .document(widget.currentUser.id)
        .collection("feedItems")
        .document(widget.currentUser.id)
        .setData({
      "type": "nearby",
      "username": currentUser.username,
      "userId": currentUser.id,
      "userProfileImg": currentUser.photoUrl,
      "postId": widget.currentUser.id,
      "mediaUrl": null,
      "timestamp": timestamp,
    });}
  }
  /*activityFeedRef
        .document(widget.currentUser.id).collection('nearby').document(widget.currentUser.id).
        setData({
      "nearbyList": ids,
    });*/
  //nearbyIncident = [];

/*
  .document(currentUser.id)
        .collection('feedItems')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .getDocuments();
*/
  @override
  void initState() {
    super.initState();

    //get tokens
    _messaging.getToken().then((token) {
      print("This is token: " + token);
      //enX-t2BN7qc:APA91bEvAcOLGuV4kcJu73x4PYB77Q2YIe0ZMLimj1mc-V5W4ppi61Wk7N32pJa603QcVh7oSfmXg7uk_HRPxXmwm3ewfUaeM4TRzf8DCRjLNqR38gh-r_SXymZUd6XLlN-gBbXF1jJ_
    });

    rootBundle.loadString('assets/map_style.txt').then((string) {
      _mapStyle = string;
    });
    _getUserLocation();
    loadMarkerFeed();
    //createPostInFirestore(nearbyIncident);

    //wew();
    //placeMarkers();
  }

  //
  loadMarkerFeed() async {
    print('1');
    QuerySnapshot snapshot = await markersRef.getDocuments();
    print('2');
    //List<MarkerItems> feedItems = [];
    print('3');
    snapshot.documents.forEach((doc) {
      print('3');
      //feedItems.add(MarkerItems.fromDocument(doc));
      // print('Activity Feed Item: ${doc.data}');
    });
    //print(feedItems);
    //print(snapshot.documents.length);
    //print("LAT: "+snapshot.documents[0]['coords'].latitude.toString());
    for (int i = 0; i < snapshot.documents.length; i++) {
      loadingMarkers.add([
        snapshot.documents[i]['title'], //0
        snapshot.documents[i]['description'], //1
        snapshot.documents[i]['postId'], //2
        snapshot.documents[i]['ownerId'], //3
        snapshot.documents[i]['latitude'], //4
        snapshot.documents[i]['longitude'] //5
      ]);
    }
    print(loadingMarkers);
    //print(snapshot.documents[0]['coords'].latitude);
    //return feedItems;
    //
    setState(() {
      print("ASDFGHJKL");
      print(loadingMarkers);

      print("FAFAF" + loadingMarkers.length.toString());

      for (int i = 0; i < loadingMarkers.length; i++) {
        // _getUserLocation();
        circleCreate(loadingMarkers[i][4], loadingMarkers[i][5],
            loadingMarkers[i][2], loadingMarkers[i][0]);
        print("B00000000000III " + i.toString());
        _markers2.add(LatLng(loadingMarkers[i][4], loadingMarkers[i][5]));

        _markers.add(Marker(
          markerId: MarkerId(_lastPosition.toString()),
          //position: LatLng(loadingMarkers[i][4], loadingMarkers[i][5]),
          infoWindow: InfoWindow(
              title: loadingMarkers[i][0], snippet: loadingMarkers[i][1]),
          icon: BitmapDescriptor.defaultMarker,
        ));
      }
      print("AAAAAAAAAAAAAAAAAAAAAAAA" + getCoord.toString());
    });
    notificationAlgo(getCoord);
    nearbyIncident = [];
  }

  func(LatLng user) {
    double latitude = user.latitude;
    double longitude = user.longitude;
    print("PUMASOK!!!" + latitude.toString());
    print("PUMASOK!!!" + longitude.toString());

    for (int i = 0; i < loadingMarkers.length; i++) {
      print(loadingMarkers[i][4].toString());
      print(loadingMarkers[i][5].toString());
      const double pi = 3.141592653589;
      double r = 6371e3;
      double lat1 = latitude * (pi / 180);
      double lng1 = loadingMarkers[i][4] * (pi / 180);
      double difflat = (latitude - loadingMarkers[i][4]) * (pi / 180);
      double difflng = (longitude - loadingMarkers[i][5]) * (pi / 180);
      double a = sin(difflat / 2) * sin(difflat / 2) +
          cos(lat1) * cos(lng1) * sin(difflng / 2) * sin(difflng / 2);
      double c = 2 * atan2(sqrt(a), sqrt(1 - a));
      double dist = r * c;
      print("DDDDDDDDDDDD" + dist.toString());
      if (dist < 50) {
        print("Nice");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostScreen(
              postId: loadingMarkers[i][2],
              userId: loadingMarkers[i][3],
            ),
          ),
        );
      }
    }
    user = LatLng(0.0, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return _center == null
        ? Container(
            alignment: Alignment.center,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Stack(
            children: <Widget>[
              GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: _center, zoom: 15.0),
                onMapCreated: _onCreated,
                myLocationEnabled: true,
                //mapType: _mapStyle, //MapType.normal,
                compassEnabled: true,
                markers: _markers,
                onCameraMove: _onCameraMove,
                circles: circles,
                onTap: (LatLng userLatlng) {
                  user = userLatlng;
                  func(user);
                },
              )

              //GoogleMap().

              /*
              //Start - Add Marker Button 
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Column(
                    children: <Widget>[
                      FloatingActionButton(
                        onPressed: _onAddMarkerPressed,
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        backgroundColor: Colors.green,
                        child: const Icon(Icons.add_location, size: 36.0),
                      ),
                      SizedBox(height: 16.0),
                    ],
                  ),
                ),
              ),
              // End - Add Marker Button
              */
            ],
          );
  }

  _onCameraMove(CameraPosition position) {
    setState(() {
      _lastPosition = position.target;
    });
  }

  _onCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      mapController.setMapStyle(_mapStyle);
    });
  }

  void _getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    //List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      print("CENTER:" + _center.toString());
      //print(
      //    position.latitude.toString() + ' 0 ' + position.longitude.toString());
    });
  }
}
