import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

class PhoneCameraScreen extends StatefulWidget {
  @override
  _PhoneCameraScreenState createState() => _PhoneCameraScreenState();
}

class _PhoneCameraScreenState extends State<PhoneCameraScreen> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  FlutterTts tts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();

  bool _isInitialized = false;
  File? _capturedImage;
  String _name = "";
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _initializePhoneCamera();
  }

  Future<void> _initializePhoneCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras.first, ResolutionPreset.medium);
    await _controller.initialize();
    setState(() => _isInitialized = true);
    await Future.delayed(Duration(seconds: 2));
    _captureImageFromPhone();
  }

  Future<void> _captureImageFromPhone() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(tempDir.path, '${DateTime.now()}.jpg');
    await _controller.takePicture().then((XFile file) {
      setState(() {
        _capturedImage = File(file.path);
      });
    });
    await _speak("Image captured. Please say the name of the person.");
    await Future.delayed(Duration(seconds: 5));
    _getNameFromSpeech();
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
    if (_isInitialized) _controller.dispose();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Phone Camera Capture")),
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
            ],
          ),
        ),
      ),
    );
  }
}
