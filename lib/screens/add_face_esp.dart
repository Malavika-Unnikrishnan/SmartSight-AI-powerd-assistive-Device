import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddFaceESP extends StatefulWidget {
  @override
  _AddFaceESPState createState() => _AddFaceESPState();
}

class _AddFaceESPState extends State<AddFaceESP> {
  String esp32Link = "";
  String capturedImageUrl = "";
  String personName = "";
  bool isListening = false;
  stt.SpeechToText speech = stt.SpeechToText();

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
      _showMessage("ESP32 link not found. Please connect your device.");
    }
  }

  Future<void> _captureImageFromESP32() async {
    try {
      final response = await http.get(Uri.parse(esp32Link));
      if (response.statusCode == 200) {
        setState(() {
          capturedImageUrl = esp32Link;
        });
        _showMessage("Image captured successfully.");
        _startListeningForName();
      } else {
        _showMessage("Failed to capture image.");
      }
    } catch (e) {
      _showMessage("Error capturing image.");
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
      _showMessage("Voice recognition not available.");
    }
  }

  void _confirmName() {
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
    final url = Uri.parse("https://your-api.com/register");
    final response = await http.post(
      url,
      body: jsonEncode({"name": personName, "image": capturedImageUrl}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      _showMessage("$personName added successfully.");
    } else {
      _showMessage("Failed to register face.");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Face via ESP32")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ensure the person is in front of SmartSight."),
            SizedBox(height: 20),
            capturedImageUrl.isNotEmpty
                ? Image.network(capturedImageUrl, height: 200)
                : CircularProgressIndicator(),
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
