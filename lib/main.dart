import "package:flutter/material.dart";
import "package:flutter/services.dart";
import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIOverlays([]);
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft])
      .then((_) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DinoJump',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: gameWindow(),
    );
  }
}