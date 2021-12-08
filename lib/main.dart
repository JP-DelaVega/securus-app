import 'package:flutter/material.dart';
import 'package:splashscreen/splashscreen.dart';
import './pages/home.dart';
import 'package:flutter/services.dart';


void main() {
    runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Securus',
        debugShowCheckedModeBanner: false,
        home: new SplashScreen(
            seconds: 5,
            navigateAfterSeconds: new Home(),
            image: new Image.asset('assets/log_in_logo.png'),
            backgroundColor: Colors.grey[900],
            styleTextUnderTheLoader: new TextStyle(),
            photoSize: 100.0,
            loaderColor: Colors.blue)
        
        );
  }
}
