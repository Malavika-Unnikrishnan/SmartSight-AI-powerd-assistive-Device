import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_face.dart'; // ESP32 add face screen
import 'detect_face.dart'; // ESP32 detect face
import 'phone_camera_face.dart'; // Phone camera add face
import 'detect_face_phone.dart'; // Phone camera detect face

class FaceScreen extends StatelessWidget {
  const FaceScreen({super.key});

  Future<void> _handleFace(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int esp32Status = prefs.getInt('esp32ConnectionStatus') ?? 0;

    if (esp32Status == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddFaceScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PhoneCameraScreen()),
      );
    }
  }

  Future<void> _handleFace2(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int esp32Status = prefs.getInt('esp32ConnectionStatus') ?? 0;

    if (esp32Status == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetectFaceESP32Screen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetectFacePhoneScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Face Recognition Options"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton(context, "Add Face", () => _handleFace(context)),
            buildButton(context, "Detect Face", () => _handleFace2(context)),
          ],
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        width: 250,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
