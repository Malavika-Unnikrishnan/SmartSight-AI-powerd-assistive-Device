import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'detect_face_phone.dart'; // Make sure this exists

class DetectFaceESP32Screen extends StatefulWidget {
  @override
  _DetectFaceESP32ScreenState createState() => _DetectFaceESP32ScreenState();
}

class _DetectFaceESP32ScreenState extends State<DetectFaceESP32Screen> {
  FlutterTts tts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();

  bool _isProcessing = false;
  File? _capturedImage;
  String _result = "";

  @override
  void initState() {
    super.initState();
    _startProcess();
  }

  Future<void> _startProcess() async {
    setState(() => _isProcessing = true);
    await _speak("Capturing image from Smart Sight.");
    await Future.delayed(Duration(seconds: 2));
    bool success = await _captureImageFromESP32();
    if (success) {
      await _speak("Analyzing faces.");
      await Future.delayed(Duration(seconds: 1));
      await _sendToBackend();
    } else {
      await _speak("Unable to connect to Smart Sight. Would you like to switch to phone camera?");
      await Future.delayed(Duration(seconds: 5));
      await _listenForSwitchCommand();
    }
    setState(() => _isProcessing = false);
  }

  Future<bool> _captureImageFromESP32() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? esp32Url = prefs.getString('esp32_link');
      if (esp32Url == null) return false;

      final captureUrl = Uri.parse('$esp32Url/capture');
      final response = await http.get(captureUrl).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = path.join(tempDir.path, 'esp32_capture.jpg');
        File imageFile = File(filePath);
        await imageFile.writeAsBytes(response.bodyBytes);
        setState(() => _capturedImage = imageFile);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error capturing from ESP32: $e");
      return false;
    }
  }

  Future<void> _sendToBackend() async {
    if (_capturedImage == null) {
      await _speak("No image captured.");
      return;
    }

    try {
      var uri = Uri.parse("https://deepfacenet.onrender.com/recognize_face");
      var request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath('image', _capturedImage!.path));

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

  Future<void> _listenForSwitchCommand() async {
    bool available = await speech.initialize();
    if (available) {
      speech.listen(
        onResult: (val) async {
          if (val.recognizedWords.toLowerCase().contains("yes")) {
            await tts.stop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DetectFacePhoneScreen()),
            );
          } else {
            await _speak("Okay. Staying on Smart Sight mode.");
          }
        },
        listenFor: Duration(seconds: 5),
        pauseFor: Duration(seconds: 2),
        localeId: "en_US",
        cancelOnError: true,
        partialResults: false,
      );
    } else {
      await _speak("Speech recognition not available.");
    }
  }

  @override
  void dispose() {
    tts.stop();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Detect Face (ESP32)")),
      body: Center(
        child: _isProcessing
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _capturedImage != null
                ? Image.file(_capturedImage!, height: 300)
                : Text("No image captured yet."),
            SizedBox(height: 20),
            Text(_result.isEmpty ? "Waiting for result..." : "Result: $_result"),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _startProcess(),
              child: Text("Use ESP32 Cam"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => DetectFacePhoneScreen()),
                );
              },
              child: Text("Use Phone Camera"),
            ),
          ],
        ),
      ),
    );
  }
}
