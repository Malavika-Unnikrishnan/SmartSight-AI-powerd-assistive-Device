import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class SceneAnalysisScreen extends StatefulWidget {
  @override
  _SceneAnalysisScreenState createState() => _SceneAnalysisScreenState();
}

class _SceneAnalysisScreenState extends State<SceneAnalysisScreen> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraReady = false;
  String _caption = '';
  final FlutterTts flutterTts = FlutterTts();
  bool _imageCaptured = false;

  @override
  void initState() {
    super.initState();
    _captureImageFromESP32();
  }

  Future<void> _captureImageFromESP32() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.101.26/capture'));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        File tempImage = File('${Directory.systemTemp.path}/esp32_image.jpg');
        await tempImage.writeAsBytes(bytes);
        _imageCaptured = true;
        await _sendImageToAPI(tempImage);
      } else {
        print('ESP32 capture failed, switching to phone camera.');
        _initializePhoneCamera();
      }
    } catch (e) {
      print('ESP32 capture error: $e');
      _initializePhoneCamera();
    }
  }

  Future<void> _initializePhoneCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras.first, ResolutionPreset.high);

    try {
      await _cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
        _captureImageFromPhone();
      }
    } catch (e) {
      print("Phone camera initialization failed: $e");
    }
  }

  Future<void> _captureImageFromPhone() async {
    if (_isCameraReady) {
      XFile image = await _cameraController.takePicture();
      await _sendImageToAPI(File(image.path));
    }
  }

  Future<void> _sendImageToAPI(File imageFile) async {
    final Uri url = Uri.parse('https://scene-flask.onrender.com/predict');
    var request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);
      if (data['result'] != null) {
        setState(() {
          _caption = data['result']['caption'];
        });
        await flutterTts.speak(_caption);
      }
    } else {
      print('Error sending image to backend: ${response.statusCode}');
    }
  }

  @override
  void dispose() {
    if (_isCameraReady) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scene Analysis'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _imageCaptured || _isCameraReady
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isCameraReady)
              SizedBox(
                width: 300,
                height: 400,
                child: CameraPreview(_cameraController),
              ),
            const SizedBox(height: 20),
            if (_caption.isNotEmpty)
              Text(
                'Caption: $_caption',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ],
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
