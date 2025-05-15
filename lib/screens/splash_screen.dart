import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speakOpeningMessage();

    // Navigate to Home Screen after 3 seconds
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  Future<void> _speakOpeningMessage() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0); // Normal pitch
    await flutterTts.setSpeechRate(0.5); // Normal speed
    await flutterTts.setVolume(1.0);

    // Using a more human-like voice (Google's WaveNet voices for Android/iOS)
    await flutterTts.setVoice({"name": "en-us-x-sfg#male_1-local", "locale": "en-US"});

    await flutterTts.speak("Opening SmartSight");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "SMARTSIGHT",
          style: TextStyle(
            color: Colors.white,
            fontSize: 40, // Bigger text
            fontWeight: FontWeight.w900, // Extra Bold
          ),
        ),
      ),
    );
  }
}
