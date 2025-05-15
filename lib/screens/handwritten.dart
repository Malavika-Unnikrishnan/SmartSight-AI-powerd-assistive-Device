import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 👇 Make sure this path is correct
import 'PhoneCameraCaptureScreen.dart';

class HandwrittenScreen extends StatefulWidget {
  @override
  _HandwrittenScreenState createState() => _HandwrittenScreenState();
}

class _HandwrittenScreenState extends State<HandwrittenScreen> {
  final String apiUrl = 'https://handwritten-7bo7.onrender.com/extract_text';
  FlutterTts flutterTts = FlutterTts();
  bool isLoading = false;
  String extractedText = "";

  @override
  void initState() {
    super.initState();
    captureAndExtractFromESP();
  }

  Future<void> captureAndExtractFromESP() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? esp32Url = prefs.getString('esp32_link');

      if (esp32Url == null || esp32Url.isEmpty) {
        throw Exception("ESP32 link not found in settings");
      }

      final fullUrl = "$esp32Url/capture";
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        await processImage(response.bodyBytes);
      } else {
        showError('Failed to capture image from ESP32');
      }
    } catch (e) {
      showError('Error: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> processImage(List<int> imageBytes) async {
    setState(() => isLoading = true);
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'captured.jpg'));
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var data = json.decode(responseBody);
        extractedText = data['extracted_text'] ?? 'No text found';
        speakText(extractedText);
      } else {
        showError('Failed to extract text');
      }
    } catch (e) {
      showError('Error: $e');
    }
    setState(() => isLoading = false);
  }

  void speakText(String text) async {
    await flutterTts.speak(text);
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void navigateToCameraScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PhoneCameraCaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Handwritten Text Recognition')),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: captureAndExtractFromESP,
              icon: Icon(Icons.refresh),
              label: Text('Retry ESP32'),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: navigateToCameraScreen,
              icon: Icon(Icons.camera),
              label: Text('Use Camera'),
            ),
            if (extractedText.isNotEmpty) ...[
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  extractedText,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
