import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class SceneAnalysisCamera extends StatefulWidget {
  @override
  _SceneAnalysisCameraState createState() => _SceneAnalysisCameraState();
}

class _SceneAnalysisCameraState extends State<SceneAnalysisCamera> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraReady = false;
  String _caption = '';
  File? _capturedImage;
  final FlutterTts flutterTts = FlutterTts();
  Timer? _analyzingTimer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras.first, ResolutionPreset.high);
    await _cameraController.initialize();

    if (mounted) {
      setState(() {
        _isCameraReady = true;
      });

      // Auto-capture image once camera is ready
      await Future.delayed(Duration(milliseconds: 500)); // Small delay to stabilize
      _captureImageFromPhone();
    }
  }

  Future<void> _captureImageFromPhone() async {
    if (_isCameraReady) {
      XFile image = await _cameraController.takePicture();
      File imageFile = File(image.path);

      setState(() {
        _capturedImage = imageFile;
      });

      await flutterTts.speak("Image captured.");
      await Future.delayed(Duration(seconds: 2));
      _startAnalyzingAudio();
      _sendImageToAPI(imageFile);
    }
  }

  void _startAnalyzingAudio() {
    _analyzingTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (_isProcessing) {
        await flutterTts.speak("Analyzing the scene.");
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _sendImageToAPI(File imageFile) async {
    final Uri url = Uri.parse('https://scene-flask.onrender.com/predict');
    var request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    setState(() {
      _isProcessing = true;
    });

    var response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      if (data['result'] != null) {
        setState(() {
          _caption = data['result']['caption'];
          _isProcessing = false;
        });

        _analyzingTimer?.cancel();
        await flutterTts.speak(_caption);
      }
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _analyzingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scene Analysis (Camera)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_capturedImage != null)
              Image.file(_capturedImage!, width: 300, height: 300),
            SizedBox(height: 20),
            if (_caption.isNotEmpty)
              Text('Caption: $_caption', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
