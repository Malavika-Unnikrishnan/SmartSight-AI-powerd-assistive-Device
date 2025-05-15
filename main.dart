import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(SmartSightApp());
}

class SmartSightApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartSight',
      theme: ThemeData.dark(), // Using a minimal black-and-white theme
      home: SplashScreen(),
    );
  }
}
