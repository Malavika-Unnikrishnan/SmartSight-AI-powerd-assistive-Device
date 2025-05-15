import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'scene_analysis_camera.dart'; // Importing the camera-based file

class SceneAnalysisESP extends StatefulWidget {
  @override
  _SceneAnalysisESPState createState() => _SceneAnalysisESPState();
}

class _SceneAnalysisESPState extends State<SceneAnalysisESP> {
  String _caption = '';
  File? _capturedImage;
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  bool _isProcessing = false;
  Timer? _analyzingTimer;
  String? esp32Link;

  @override
  void initState() {
    super.initState();
    _fetchESP32Link();
  }

  Future<void> _fetchESP32Link() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedLink = prefs.getString('esp32_link');
    if (storedLink != null) {
      setState(() {
        esp32Link = storedLink + "/capture";
      });
      _captureImageFromESP32();
    } else {
      _handleCaptureFailure();
    }
  }

  Future<void> _captureImageFromESP32() async {
    if (esp32Link == null) return;

    try {
      final response = await http.get(Uri.parse(esp32Link!));

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        File tempImage = File('${Directory.systemTemp.path}/esp32_image.jpg');
        await tempImage.writeAsBytes(bytes);

        setState(() {
          _capturedImage = tempImage;
        });

        await flutterTts.speak("Image captured.");
        await Future.delayed(Duration(seconds: 2));
        _startAnalyzingAudio();
        _sendImageToAPI(tempImage);
      } else {
        _handleCaptureFailure();
      }
    } catch (e) {
      _handleCaptureFailure();
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
    } else {
      _isProcessing = false;
    }
  }

  Future<void> _handleCaptureFailure() async {
    await flutterTts.speak("Unable to capture image. Should we use the phone camera instead?");
    await Future.delayed(Duration(seconds: 3));

    bool available = await speech.initialize();
    if (available) {
      speech.listen(
        onResult: (result) async {
          String userResponse = result.recognizedWords.toLowerCase();
          if (userResponse == "yes") {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SceneAnalysisCamera()));
          }
        },
        listenFor: Duration(seconds: 5),
        pauseFor: Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    _analyzingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scene Analysis (ESP32)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_capturedImage != null)
              Image.file(_capturedImage!, width: 300, height: 300),
            SizedBox(height: 20),
            if (_caption.isNotEmpty)
              Text('Caption: $_caption', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SceneAnalysisCamera()));
              },
              child: Text("Use Camera Instead"),
            ),
          ],
        ),
      ),
    );
  }
}
