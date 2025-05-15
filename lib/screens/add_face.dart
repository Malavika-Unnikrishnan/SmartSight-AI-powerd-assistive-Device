// File: add_face_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'phone_camera_face.dart';

class AddFaceScreen extends StatefulWidget {
  @override
  _AddFaceScreenState createState() => _AddFaceScreenState();
}

class _AddFaceScreenState extends State<AddFaceScreen> {
  FlutterTts tts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();

  File? _capturedImage;
  String _name = "";
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _attemptESP32Capture();
  }

  Future<void> _attemptESP32Capture() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? baseUrl = prefs.getString('esp32_link');
    if (baseUrl == null) {
      await _speak("ESP32 link not set.");
      return;
    }
    String esp32Url = '$baseUrl/capture';

    try {
      final response = await http.get(Uri.parse(esp32Url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(tempDir.path, '${DateTime.now()}.jpg');
        final imageFile = File(filePath);
        await imageFile.writeAsBytes(response.bodyBytes);
        setState(() {
          _capturedImage = imageFile;
        });
        await _speak("Image captured from ESP32. Please say the name of the person.");
        await Future.delayed(Duration(seconds: 5));
        _getNameFromSpeech();
      } else {
        await _handleESP32Failure();
      }
    } catch (e) {
      await _handleESP32Failure();
    }
  }

  Future<void> _handleESP32Failure() async {
    await _speak("Unable to access SmartSight. Would you like to shift to the phone camera?");
    await Future.delayed(Duration(seconds: 4));
    _listenForCameraSwitch();
  }

  Future<void> _listenForCameraSwitch() async {
    bool available = await speech.initialize();
    if (available) {
      speech.listen(onResult: (result) async {
        if (result.finalResult) {
          String response = result.recognizedWords.toLowerCase();
          speech.stop();
          if (response.contains("yes")) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PhoneCameraScreen()));
          }
        }
      });
    }
  }

  Future<void> _getNameFromSpeech() async {
    bool available = await speech.initialize();
    if (available) {
      speech.listen(onResult: (result) async {
        if (result.finalResult) {
          setState(() => _name = result.recognizedWords);
          speech.stop();
          await _speak("Name recorded: $_name. Please say yes to confirm.");
          await Future.delayed(Duration(seconds: 5));
          _confirmName();
        }
      });
    }
  }

  Future<void> _confirmName() async {
    setState(() => _confirming = true);
    bool available = await speech.initialize();
    if (available) {
      speech.listen(onResult: (result) async {
        if (result.finalResult) {
          if (result.recognizedWords.toLowerCase() == "yes") {
            speech.stop();
            _submitData();
          } else {
            await _speak("Confirmation not received. Please use the Submit button.");
            speech.stop();
          }
          setState(() => _confirming = false);
        }
      });
    }
  }

  Future<void> _submitData() async {
    if (_capturedImage == null || _name.isEmpty) {
      await _speak("Missing image or name. Please try again.");
      return;
    }

    var uri = Uri.parse("https://deepfacenet.onrender.com/add_face");
    var request = http.MultipartRequest("POST", uri)
      ..fields['name'] = _name
      ..files.add(await http.MultipartFile.fromPath('image', _capturedImage!.path));

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();
    var jsonRes = jsonDecode(responseBody);
    String result = jsonRes['result'] ?? "No response from server";
    await _speak(result);
  }

  Future<void> _speak(String text) async {
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.45);
    await tts.speak(text);
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Face")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_capturedImage != null)
                Image.file(_capturedImage!, height: 300)
              else
                Text("No image captured yet."),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: TextField(
                  decoration: InputDecoration(labelText: "Name"),
                  controller: TextEditingController(text: _name),
                  onChanged: (val) => _name = val,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitData,
                child: Text("Submit"),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PhoneCameraScreen()));
                },
                child: Text("Use Phone Camera"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
