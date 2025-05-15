import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DetectFacePhoneScreen extends StatefulWidget {
  @override
  _DetectFacePhoneScreenState createState() => _DetectFacePhoneScreenState();
}

class _DetectFacePhoneScreenState extends State<DetectFacePhoneScreen> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  File? _capturedImage;
  String _result = "";

  FlutterTts tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.medium);
    await _controller.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    await _speak("Phone camera ready.");
    await Future.delayed(Duration(seconds: 1));
    _captureAndAnalyze();
  }

  Future<void> _captureAndAnalyze() async {
    setState(() => _isProcessing = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, 'phone_capture.jpg');

      XFile image = await _controller.takePicture();
      await image.saveTo(filePath);
      File capturedImage = File(filePath);
      setState(() => _capturedImage = capturedImage);

      await _speak("Image captured. Analyzing now.");
      await Future.delayed(Duration(seconds: 1));
      await _sendToBackend(capturedImage);
    } catch (e) {
      print("Error capturing: $e");
      await _speak("Failed to capture image.");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendToBackend(File imageFile) async {
    try {
      var uri = Uri.parse("https://deepfacenet.onrender.com/recognize_face");
      var request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonRes = jsonDecode(responseBody);
      String result = jsonRes['result'] ?? "No response from server";

      setState(() => _result = result);
      await _speak(result);
    } catch (e) {
      await _speak("Error analyzing the image.");
      setState(() => _result = "Error contacting server.");
    }
  }

  Future<void> _speak(String text) async {
    await tts.setLanguage("en-US");
    await tts.setSpeechRate(0.45);
    await tts.speak(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detect Face (Phone)")),
      body: Center(
        child: _isProcessing
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _capturedImage != null
                ? Image.file(_capturedImage!, height: 300)
                : _isCameraInitialized
                ? CameraPreview(_controller)
                : Text("Loading camera..."),
            SizedBox(height: 20),
            Text(_result.isEmpty ? "Waiting for result..." : "Result: $_result"),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isCameraInitialized ? _captureAndAnalyze : null,
              child: Text("Retake & Analyze"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Back to ESP32"),
            ),
          ],
        ),
      ),
    );
  }
}
