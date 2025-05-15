import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetectFaceESP extends StatefulWidget {
  @override
  _DetectFaceESPState createState() => _DetectFaceESPState();
}

class _DetectFaceESPState extends State<DetectFaceESP> {
  String? esp32Link;
  String? capturedImageUrl;
  String detectedName = "Detecting...";
  bool isDetecting = false;
  FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speak("Please make sure the person is in front of SmartSight.");
    _fetchESP32Link();
  }

  Future<void> _speak(String text) async {
    await tts.speak(text);
  }

  Future<void> _fetchESP32Link() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedLink = prefs.getString('esp32_link');
    if (storedLink != null) {
      setState(() {
        esp32Link = storedLink + "/capture";
      });
      _captureImageFromESP32();
    } else {
      _speak("ESP32 connection not found.");
    }
  }

  Future<void> _captureImageFromESP32() async {
    if (esp32Link == null) return;

    setState(() {
      isDetecting = true;
      capturedImageUrl = null;
      detectedName = "Detecting...";
    });

    try {
      final response = await http.get(Uri.parse(esp32Link!));

      if (response.statusCode == 200) {
        setState(() {
          capturedImageUrl = esp32Link;
        });

        _speak("Image captured successfully.");
        _detectFace();
      } else {
        _speak("Failed to capture image. Please try again.");
      }
    } catch (e) {
      _speak("Error capturing image. Please check your connection.");
    }
  }

  Future<void> _detectFace() async {
    if (capturedImageUrl == null) return;

    setState(() {
      detectedName = "Detecting...";
      isDetecting = true;
    });

    _speak("Detecting face, please wait...");

    final url = Uri.parse("https://your-api.com/detect");
    final response = await http.post(url, body: json.encode({'image_url': capturedImageUrl}));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String? name = data['name'];

      if (name != null && name.isNotEmpty) {
        setState(() {
          detectedName = name;
          isDetecting = false;
        });

        _speak("Face detected. Name is $name.");
      } else {
        setState(() {
          detectedName = "No face detected.";
          isDetecting = false;
        });

        _speak("No face detected, try again.");
      }
    } else {
      setState(() {
        detectedName = "Detection failed.";
        isDetecting = false;
      });

      _speak("Face detection failed. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detect Face via ESP32")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ensure the person is in front of SmartSight."),
            SizedBox(height: 20),
            capturedImageUrl != null
                ? Image.network(capturedImageUrl!, height: 200)
                : ElevatedButton(
              onPressed: _captureImageFromESP32,
              child: Text("Capture Image"),
            ),
            SizedBox(height: 20),
            Text(detectedName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            isDetecting ? CircularProgressIndicator() : SizedBox(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/detect_face_camera');
              },
              child: Text("Use Camera Instead"),
            ),
          ],
        ),
      ),
    );
  }
}
