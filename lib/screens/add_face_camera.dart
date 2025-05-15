import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddFaceCamera extends StatefulWidget {
  @override
  _AddFaceCameraState createState() => _AddFaceCameraState();
}

class _AddFaceCameraState extends State<AddFaceCamera> {
  File? _capturedImage;
  String personName = "";
  bool isListening = false;
  stt.SpeechToText speech = stt.SpeechToText();
  FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speak("Please make sure the person is in front of the camera.");
  }

  Future<void> _speak(String text) async {
    await tts.speak(text);
  }

  Future<void> _captureImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
      });
      _speak("Image captured successfully.");
      _startListeningForName();
    } else {
      _speak("Failed to capture image.");
    }
  }

  void _startListeningForName() async {
    bool available = await speech.initialize();
    if (available) {
      setState(() {
        isListening = true;
      });

      speech.listen(onResult: (result) {
        setState(() {
          personName = result.recognizedWords;
        });
      });

      await Future.delayed(Duration(seconds: 3));
      speech.stop();
      setState(() {
        isListening = false;
      });

      _confirmName();
    } else {
      _speak("Voice recognition not available.");
    }
  }

  void _confirmName() {
    _speak("You said $personName. Say 'yes' to confirm or 'no' to retry.");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Name"),
        content: Text("You said: $personName\nSay 'yes' to confirm or 'no' to retry."),
        actions: [
          TextButton(
            onPressed: () => _registerFace(),
            child: Text("Yes"),
          ),
          TextButton(
            onPressed: () => _startListeningForName(),
            child: Text("No"),
          ),
        ],
      ),
    );
  }

  Future<void> _registerFace() async {
    if (_capturedImage == null) {
      _speak("No image captured. Please try again.");
      return;
    }

    final url = Uri.parse("https://your-api.com/register");
    final request = http.MultipartRequest("POST", url);
    request.fields['name'] = personName;
    request.files.add(await http.MultipartFile.fromPath("image", _capturedImage!.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      _speak("$personName added successfully.");
    } else {
      _speak("Failed to register face.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Face via Camera")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ensure the person is in front of the camera."),
            SizedBox(height: 20),
            _capturedImage != null
                ? Image.file(_capturedImage!, height: 200)
                : ElevatedButton(
              onPressed: _captureImageFromCamera,
              child: Text("Capture Image"),
            ),
            SizedBox(height: 20),
            Text("Captured Name: $personName"),
            isListening ? CircularProgressIndicator() : SizedBox(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startListeningForName,
              child: Text("Retry Voice Input"),
            ),
            SizedBox(height: 20),
            TextField(
              onChanged: (value) => setState(() => personName = value),
              decoration: InputDecoration(labelText: "Enter Name Manually"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerFace,
              child: Text("Confirm and Register"),
            ),
          ],
        ),
      ),
    );
  }
}
