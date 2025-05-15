import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PrintPhoneScreen extends StatefulWidget {
  @override
  _PrintPhoneScreenState createState() => _PrintPhoneScreenState();
}

class _PrintPhoneScreenState extends State<PrintPhoneScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  File? _capturedImage;
  String _extractedText = "Capturing image...";
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    await Future.delayed(Duration(seconds: 1));
    _captureAndExtractText();
  }

  Future<void> _captureAndExtractText() async {
    setState(() => _isProcessing = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, 'captured_image.jpg');

      XFile image = await _cameraController.takePicture();
      await image.saveTo(filePath);
      File capturedImage = File(filePath);

      setState(() => _capturedImage = capturedImage);

      await _speak("Image captured. Extracting text.");
      await Future.delayed(Duration(milliseconds: 500));

      String extractedText = await _extractText(capturedImage);

      setState(() {
        _extractedText = extractedText.isNotEmpty ? extractedText : "No text found!";
      });

      await _speak(_extractedText);
    } catch (e) {
      print("Error during capture: $e");
      setState(() => _extractedText = "Error: ${e.toString()}");
      await _speak("Failed to capture or analyze.");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<String> _extractText(File image) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(image);
    final recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Auto-Capture & Text Extract")),
      body: Center(
        child: _isProcessing
            ? CircularProgressIndicator()
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_capturedImage != null)
                Image.file(_capturedImage!, height: 200),
              if (_capturedImage == null && _isCameraInitialized)
                SizedBox(
                  height: 200,
                  child: CameraPreview(_cameraController),
                ),
              SizedBox(height: 20),
              Text(
                _extractedText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isCameraInitialized ? _captureAndExtractText : null,
                child: Text("Retake"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
