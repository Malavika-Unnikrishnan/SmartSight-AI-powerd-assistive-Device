import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';

class PhoneCameraCaptureScreen extends StatefulWidget {
  @override
  _PhoneCameraCaptureScreenState createState() => _PhoneCameraCaptureScreenState();
}

class _PhoneCameraCaptureScreenState extends State<PhoneCameraCaptureScreen> {
  late List<CameraDescription> _cameras;
  late CameraController _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  File? _capturedImage;
  FlutterTts flutterTts = FlutterTts();
  final String apiUrl = 'https://handwritten-7bo7.onrender.com/extract_text';

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
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);
        String extractedText = data['extracted_text'] ?? 'No text found';
        await _speak(extractedText);
      } else {
        await _speak("Failed to extract text.");
      }
    } catch (e) {
      await _speak("Error connecting to server.");
    }
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Phone Camera Capture')),
      body: Center(
        child: _isProcessing
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_capturedImage != null)
              Image.file(
                _capturedImage!,
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _captureAndAnalyze,
              icon: Icon(Icons.camera),
              label: Text("Capture Again"),
            ),
          ],
        ),
      ),
    );
  }
}
