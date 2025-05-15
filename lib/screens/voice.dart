import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';

import 'scene_analysis_esp.dart';

import 'object_detection.dart';
import 'package:camera/camera.dart';

import 'add_face_esp.dart';

import 'print.dart';

import 'handwritten.dart';

import 'smart.dart';
import 'map.dart';

import 'social.dart';
import 'scene_analysis_camera.dart';
import 'add_face.dart'; // ESP32 add face screen
import 'detect_face.dart'; // ESP32 detect face
import 'phone_camera_face.dart'; // Phone camera add face
import 'detect_face_phone.dart'; // Phone camera detect face
import 'print_phone_screen.dart';
import 'PhoneCameraCaptureScreen.dart';
import 'phone_camera_screen.dart';

class VoiceCommandHandler {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final BuildContext context;

  VoiceCommandHandler(this.context);

  Future<void> startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      _speech.listen(onResult: (result) {
        String command = result.recognizedWords.toLowerCase();
        _processCommand(command);
      });
    } else {
      _showError("Speech recognition not available");
    }
  }

  void _processCommand(String command) async {
    final prefs = await SharedPreferences.getInstance();
    int esp32Status = prefs.getInt('esp32ConnectionStatus') ?? 0;

    if (command.contains("describe")) {
      if (esp32Status == 1) {
        _navigateTo(SceneAnalysisESP());
      } else {
        _navigateTo(SceneAnalysisCamera());
      }
    } else if (command.contains("detect")) {
      if (esp32Status == 1) {
        _navigateTo(DetectFaceESP32Screen());
      } else {
        _navigateTo(DetectFacePhoneScreen());
      }
    } else if (command.contains("add face")) {
      if (esp32Status == 1) {
        _navigateTo(AddFaceScreen());
      } else {
        _navigateTo(PhoneCameraScreen());
      }
    } else if (command.contains("printed")) {
      if (esp32Status == 1) {
        _navigateTo(PrintScreen());
      } else {
        _navigateTo(PrintPhoneScreen());
      }
    } else if (command.contains("handwritten")) {
      if (esp32Status == 1) {
        _navigateTo(HandwrittenScreen());
      } else {
        _navigateTo(PhoneCameraCaptureScreen());
      }
    } else if (command.contains("smart read")) {
      if (esp32Status == 1) {
        _navigateTo(SmartScreen());
      } else {
        _navigateTo(PhoneCameraScreen3());
      }
    } else if (command.contains("instagram")) {
      _navigateTo(SocialScreen());
    } else if (command.contains("navigation")) {
      try {
        final cameras = await availableCameras();
        _navigateTo(ObjectDetectionScreen(cameras: cameras));
      } catch (e) {
        _showError("Failed to initialize camera: $e");
      }
    } else if (command.contains("google maps")) {
      _navigateTo(MapScreen()); // Placeholder
    } else if (command.contains("help")) {
      _showHelpDialog();
    } else {
      _showError("Say Help if needed");
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Voice Commands"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• Describe → Scene Analysis"),
              Text("• Detect → Face/Object Detection"),
              Text("• Add face → Add Face Recognition"),
              Text("• Printed → Printed Text Reading"),
              Text("• Handwritten → Handwritten Text Reading"),
              Text("• Smart read → Smart Reading Mode"),
              Text("• Instagram → Social Media Module"),
              Text("• Navigation → ClassTwo()"),
              Text("• Google Maps → ClassThree()"),
              Text("• Help → Show this help menu"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
