import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screen_scaler/flutter_screen_scaler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'home.dart';
//import 'maps.dart';
import '../models/user.dart';

class ReportPage extends StatefulWidget {
  final User currentUser;

  ReportPage({this.currentUser});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController detailsController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  File file;
  bool isUploading = false;
  bool isImage = false;
  String postId = Uuid().v4();
  String latlong;
  var items = [
    'Minor traffic incident',
    'Theft',
    'Street Fight',
    'Epidemic outbreak',
    'Large Bldg fire',
    'Multi-house fire',
    'Multi-vehicle crashes',
    'Terrorism',
    'Arson',
    'Rape',
    'Hostage',
    'Murder'
  ];

  final Map<String, dynamic> _formData = {
    'title': null,
    'details': null,
    'location': null,
  };

  final _formKey = GlobalKey<FormState>();
  decoration(String label) {
    return InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)));
  }

  Widget _buildTitleTextField() {
    ScreenScaler scaler = ScreenScaler()..init(context);
    FocusNode _focus = new FocusNode();
    return Column(children: [
      Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(left: 25.0),
        child: Text(
          "TITLE",
          textAlign: TextAlign.left,
          style: TextStyle(
              color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
      ),
      new Padding(
        padding: const EdgeInsets.all(12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: scaler.getWidth(89),
            color: Colors.white,
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: new TextFormField(
                      validator: (value) {
                        if (value.isEmpty || value.length < 5) {
                          return "Title must be at least 5 characters long.";
                        }
                        return null;
                      },
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: ' Enter Title',
                      ),
                    ),
                  ),
                ),
                Container(
                  child: new PopupMenuButton<String>(
                    icon: const Icon(Icons.arrow_drop_down),
                    onSelected: (String value) {
                      titleController.text = value;
                      print(titleController.text);

                      /// dito na sasave yung galing sa dropbox
                    },
                    itemBuilder: (BuildContext context) {
                      return items.map<PopupMenuItem<String>>((String value) {
                        return new PopupMenuItem(
                            child: new Text(value), value: value);
                      }).toList();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDetailsTextField() {
    ScreenScaler scaler = ScreenScaler()..init(context);
    return Column(children: <Widget>[
      Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(left: 25.0),
        child: Text(
          "DETAILS",
          textAlign: TextAlign.left,
          style: TextStyle(
              color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
      ),
      ListTile(
        title: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              color: Colors.white,
              width: scaler.getWidth(90),
              child: TextFormField(
                validator: (value) {
                  if (value.isEmpty || value.length < 8) {
                    return "Details must be at least 8 characters long.";
                  }
                  return null;
                },
                autovalidate: false,
                controller: detailsController,
                decoration: decoration("Enter Details"),
                maxLines: 4,
                onSaved: (String value) {
                  _formData['details'] = value;
                },
              ),
            )),
      )
    ]);
  }

  Widget _buildLocationTextField() {
    return Column(children: <Widget>[
      Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.only(left: 25.0),
        child: Text(
          "LOCATION",
          textAlign: TextAlign.left,
          style: TextStyle(
              color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w500),
        ),
      ),
      ListTile(
        title: Container(
          width: 250.0,
          child: TextFormField(
            validator: (value) {
              if (value.isEmpty) {
                return "Location must not be left blank.";
              }
              return null;
            },
            //readOnly: true,
            controller: locationController,
            decoration: decoration("Enter Location"),
            onSaved: (String value) {
              _formData['location'] = value;
            },
          ),
        ),
      )
    ]);
  }

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.camera,
      maxHeight: 640,
      maxWidth: 640,
    );
    setState(() {
      this.file = file;
      isImage = true;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      this.file = file;
      isImage = true;
    });
  }

  selectImage(parentContext) {
    return showDialog(
      context: parentContext,
      builder: (context) {
        return SimpleDialog(
          title: Text("Upload Image"),
          children: <Widget>[
            SimpleDialogOption(
                child: Text("Photo with Camera"), onPressed: handleTakePhoto),
            SimpleDialogOption(
                child: Text("Image from Gallery"),
                onPressed: handleChooseFromGallery),
            SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  //
  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    //if(file == null){
    //  file =
    //Image.asset('assets/log_in_logo.png');
    //}
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      file = compressedImageFile;
    });
  }

  //

  //
  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child("post_$postId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore(
      {String mediaUrl,
      String title,
      String location,
      String description,
      String coordinates}) {
    postsRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "title": title,
      "description": description,
      "location": location,
      "coordinates": coordinates,
      "timestamp": timestamp,
      "likes": {},
      "dislikes": {},
    });
  }

  updateNewsFeed(
      {String mediaUrl,
      String title,
      String location,
      String description,
      String coordinates}) {
    newsFeedRef
        .document("getAllPost")
        .collection("allPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "title": title,
      "description": description,
      "location": location,
      "coordinates": coordinates,
      "timestamp": timestamp,
      "likes": {},
      "dislikes": {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);

    createPostInFirestore(
        mediaUrl: mediaUrl,
        title: titleController.text,
        location: locationController.text,
        description: detailsController.text,
        coordinates: latlong);
    updateNewsFeed(
        mediaUrl: mediaUrl,
        title: titleController.text,
        location: locationController.text,
        description: detailsController.text,
        coordinates: latlong);
    uploadMarkers();
    titleController.clear();
    detailsController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUploading = false;
      isImage = false;
      postId = Uuid().v4();
    });
  }

  buildMustHavePhoto() {
    if (file == null) {
      return Container(
          child: Text(
        "Image is required",
        style: TextStyle(color: Colors.red),
      ));
    } else if (file != null) {
      return Text("");
    } else {
      return Text("");
    }
  }

  Scaffold buildReportIncident() {
    ScreenScaler scaler = ScreenScaler()..init(context);
    return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Form(
          key: _formKey,
          child: ListView(children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                isUploading ? LinearProgressIndicator() : Text(""),
                Container(
                  height: 150.0,
                  width: MediaQuery.of(context).size.width * 0.90,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fitHeight,
                            image: file == null
                                ? AssetImage('assets/log_in_logo.png')
                                : FileImage(file),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                //isImage ?Center(child:Container()): ,
                Padding(
                  padding: EdgeInsets.only(top: 5.0),
                ),
                Container(
                  width: 380.0,
                  height: 70.0,
                  alignment: Alignment.center,
                  child: RaisedButton.icon(
                    label: Text(
                      "Upload Image",
                      style: TextStyle(color: Colors.black87),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    color: Colors.white,
                    onPressed: () => selectImage(context),
                    icon: Icon(
                      Icons.photo_camera,
                      color: Colors.black87,
                    ),
                  ),
                ),
                buildMustHavePhoto(),
                Divider(
                  color: Colors.grey,
                ),
                SizedBox(height: 10),
                _buildTitleTextField(),
                SizedBox(height: 12),
                _buildDetailsTextField(),
                SizedBox(height: 12),
                //_buildLocationTextField(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          color: Colors.white,
                          width: scaler.getWidth(70),
                          child: TextFormField(
                            enabled: false,
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Location must not be left blank.";
                              }
                              return null;
                            },
                            controller: locationController,
                            decoration: decoration("Use Current Location ->"),
                          ),
                        ),
                      ),
                      Container(
                          alignment: Alignment.center,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                                color: Colors.blue,
                                child: IconButton(
                                    icon: Icon(
                                      Icons.my_location,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => getUserLocation())),
                          )),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: 50.0,
                    child: RaisedButton(
                      onPressed: () {
                        if (!_formKey.currentState.validate()) {
                          return;
                        } else {
                          handleSubmit();
                        }
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(80.0)),
                      padding: EdgeInsets.all(0.0),
                      child: Ink(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red[800], Colors.blue[800]],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(30.0)),
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth: scaler.getWidth(90), minHeight: 50.0),
                          alignment: Alignment.center,
                          child: Text(
                            "Send Alert",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                isUploading ? LinearProgressIndicator() : Text(""),
              ],
            ),
          ]),
        ));
  }

  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    print(position.latitude.toString() + "," + position.longitude.toString());
    Placemark placemark = placemarks[0];
    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);
    String formattedAddress =
        "${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
    latlong =
        (position.latitude.toString() + ',' + position.longitude.toString());
  }

  uploadMarkers() {
    List<String> position = latlong.toString().split(',');

    markersRef.document(postId).setData({
      "latitude": double.parse(position[0]),
      "longitude": double.parse(position[1]),
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "title": titleController.text,
      "description": detailsController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return buildReportIncident();
  }
}
