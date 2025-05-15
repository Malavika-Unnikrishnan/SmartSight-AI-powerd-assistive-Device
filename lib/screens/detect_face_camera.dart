import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class DetectFaceCamera extends StatefulWidget {
  @override
  _DetectFaceCameraState createState() => _DetectFaceCameraState();
}

class _DetectFaceCameraState extends State<DetectFaceCamera> {
  File? _imageFile;
  String detectedName = "Detecting...";
  bool isDetecting = false;
  FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speak("Please make sure the person is in front of the camera.");
  }

  Future<void> _speak(String text) async {
    await tts.speak(text);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      _speak("Image captured successfully.");
      _detectFace();
    } else {
      _speak("Image capture canceled.");
    }
  }

  Future<void> _detectFace() async {
    if (_imageFile == null) return;

    setState(() {
      detectedName = "Detecting...";
      isDetecting = true;
    });

    _speak("Detecting face, please wait...");

    List<int> imageBytes = await _imageFile!.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    final url = Uri.parse("https://your-api.com/detect");
    final response = await http.post(
      url,
      body: json.encode({'image_base64': base64Image}),
      headers: {"Content-Type": "application/json"},
    );

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
      appBar: AppBar(title: Text("Detect Face via Camera")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ensure the person is in front of the camera."),
            SizedBox(height: 20),
            _imageFile != null
                ? Image.file(_imageFile!, height: 200)
                : ElevatedButton(
              onPressed: _pickImage,
              child: Text("Capture Image"),
            ),
            SizedBox(height: 20),
            Text(detectedName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            isDetecting ? CircularProgressIndicator() : SizedBox(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/detect_face_esp');
              },
              child: Text("Use ESP32 Instead"),
            ),
          ],
        ),
      ),
    );
  }
}
