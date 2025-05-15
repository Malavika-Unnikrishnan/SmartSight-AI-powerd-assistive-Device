import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'object_detection.dart';
import 'map.dart';

class OutScreen extends StatefulWidget {
  @override
  _OutScreenState createState() => _OutScreenState();
}

class _OutScreenState extends State<OutScreen> {
  List<CameraDescription>? cameras;
  bool _isLoading = true;
  String? _error;
  stt.SpeechToText _speech = stt.SpeechToText();
  String _voiceQuery = "";

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      _error = "Failed to initialize camera: $e";
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get user's current location
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _showMessage("Location permission denied");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String location = "${position.latitude}, ${position.longitude}";
    MapsLauncher.launchQuery(location);
  }

  // Start voice recognition
  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      await _speech.listen(onResult: (result) {
        setState(() {
          _voiceQuery = result.recognizedWords;
        });
      });
    } else {
      _showMessage("Speech recognition unavailable");
    }
  }

  // Show pop-up dialog
  void _showInputDialog() {
    TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Destination"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Voice Input Button
              ElevatedButton(
                onPressed: _startListening,
                child: Text("🎤 Record Voice"),
              ),
              Text(_voiceQuery.isEmpty ? "Tap to record" : "You said: $_voiceQuery"),
              SizedBox(height: 10),

              // Manual Text Input
              TextField(
                controller: textController,
                decoration: InputDecoration(labelText: "Enter location"),
              ),
              SizedBox(height: 10),

              // Use My Location Button
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: Text("📍 Use My Location"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                String query = _voiceQuery.isNotEmpty ? _voiceQuery : textController.text;
                if (query.isNotEmpty) {
                  MapsLauncher.launchQuery(query);
                } else {
                  _showMessage("Enter or record a location");
                }
                Navigator.pop(context);
              },
              child: Text("Search"),
            ),
          ],
        );
      },
    );
  }

  // Show a message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation Options')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red))
            else
              ElevatedButton(
                onPressed: cameras == null
                    ? null
                    : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ObjectDetectionScreen(cameras: cameras!),
                    ),
                  );
                },
                child: Text('CAM Navigation'),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );
              },
              child: Text('Open Google Maps'),
            ),
          ],
        ),
      ),
    );
  }
}
