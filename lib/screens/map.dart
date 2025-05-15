import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  TextEditingController textController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts _tts = FlutterTts();

  String _voiceQuery = "";
  bool _awaitingYes = false;

  @override
  void initState() {
    super.initState();
    _initVoiceInteraction();
  }

  Future<void> _initVoiceInteraction() async {
    await _speak("Please tell the destination or query regarding nearby places.");
    await Future.delayed(Duration(seconds: 4));
    await _startListening();
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      await _speech.listen(
        onResult: (result) async {
          setState(() {
            _voiceQuery = result.recognizedWords;
          });

          if (_voiceQuery.isNotEmpty && !_awaitingYes) {
            await _speech.stop();
            await _speak("You said $_voiceQuery. Say yes to launch Google Maps.");
            _awaitingYes = true;
            await Future.delayed(Duration(seconds: 5));
            await _listenForYes();
          }
        },
      );
    } else {
      _showMessage("Speech recognition unavailable");
    }
  }

  Future<void> _listenForYes() async {
    bool available = await _speech.initialize();
    if (available) {
      await _speech.listen(
        onResult: (result) {
          String response = result.recognizedWords.toLowerCase();
          if (response.contains("yes")) {
            MapsLauncher.launchQuery(_voiceQuery);
          }
        },
        listenFor: Duration(seconds: 4),
      );
    }
  }

  void _searchLocation() {
    String query = _voiceQuery.isNotEmpty ? _voiceQuery : textController.text;
    if (query.isNotEmpty) {
      MapsLauncher.launchQuery(query);
    } else {
      _showMessage("Enter or record a location");
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Maps Navigation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _startListening,
              child: Text("🎤 Record Voice"),
            ),
            Text(_voiceQuery.isEmpty ? "Tap to record" : "You said: $_voiceQuery"),
            SizedBox(height: 10),
            TextField(
              controller: textController,
              decoration: InputDecoration(labelText: "Enter location"),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _searchLocation,
              child: Text("Search Location"),
            ),
          ],
        ),
      ),
    );
  }
}
