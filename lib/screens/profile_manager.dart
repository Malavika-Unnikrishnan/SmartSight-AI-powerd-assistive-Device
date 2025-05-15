import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'package:http/http.dart' as http;

class ProfileManager {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();
  String userName = "";
  String emergencyContact = "";
  int connectionMode = -1; // 0 = ESP32, 1 = Mobile Camera

  Future<void> loadUserData(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName') ?? "";
    emergencyContact = prefs.getString('emergencyContact') ?? "";

    if (userName.isEmpty || emergencyContact.isEmpty) {
      Future.delayed(Duration(milliseconds: 500), () => askForUserDetails(context));
    } else {
      speak("Welcome to SmartSight, $userName!");
      Future.delayed(Duration(seconds: 2), () => askToConnectSmartSight());
    }
  }

  Future<void> saveUserData(String name, String contact) async {
    if (name.isEmpty || contact.isEmpty) {
      speak("Name and emergency contact cannot be empty.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('emergencyContact', contact);
    userName = name;
    emergencyContact = contact;
    speak("Profile completed.");
    Future.delayed(Duration(seconds: 2), () => askToConnectSmartSight());
  }

  Future<void> removeUserData(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('emergencyContact');
    userName = "";
    emergencyContact = "";
    speak("Profile removed. Please set up your profile again.");
    askForUserDetails(context);
  }

  Future<void> speak(String text) async {
    try {
      await flutterTts.speak(text);
    } catch (e) {
      print("Error in TTS: $e");
    }
  }

  Future<void> askForUserDetails(BuildContext context) async {
    String name = await listenForInput("Please say your name.");
    String contact = await listenForInput("Please say your emergency contact number.");

    if (name.isNotEmpty && contact.isNotEmpty) {
      await saveUserData(name, contact);
    } else {
      speak("Please provide valid details.");
    }
  }

  Future<String> listenForInput(String prompt) async {
    await speak(prompt);
    await Future.delayed(Duration(seconds: 2));

    bool available = await speech.initialize();
    if (available) {
      Completer<String> completer = Completer();
      bool isCompleted = false;

      Timer(Duration(seconds: 10), () {
        if (!isCompleted) {
          completer.complete("");
          speech.stop();
        }
      });

      speech.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            isCompleted = true;
            completer.complete(result.recognizedWords);
            speech.stop();
          }
        },
      );

      return completer.future;
    }
    return "";
  }

  Future<void> askToConnectSmartSight() async {
    String response = await listenForInput("Please say yes to connect to SmartSight.");

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (response.toLowerCase() == "yes") {
      connectToESP32();
    } else {
      await prefs.setInt('esp32ConnectionStatus', 0); // Save 0 if user says anything other than "yes"
      speak("Skipping connection to SmartSight.");
    }
    Future.delayed(Duration(seconds: 2), () => askForHelp());
  }

  Future<void> connectToESP32() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? esp32BaseUrl = prefs.getString('esp32_link');

      if (esp32BaseUrl == null || esp32BaseUrl.isEmpty) {
        speak("No ESP32 link found. Please set it up in Settings.");
        await prefs.setInt('esp32ConnectionStatus', 0); // Save 0 if no URL is found
        return;
      }

      String captureUrl = "$esp32BaseUrl/capture";
      final response = await http.get(Uri.parse(captureUrl)).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        connectionMode = 0;
        await prefs.setInt('esp32ConnectionStatus', 1); // Save 1 if connection succeeds
        speak("Connected to SmartSight.");
      } else {
        connectionMode = 1;
        await prefs.setInt('esp32ConnectionStatus', 0); // Save 0 if connection fails
        speak("Failed to connect. Using mobile camera instead.");
      }

    } catch (e) {
      connectionMode = 1;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('esp32ConnectionStatus', 0); // Save 0 if an error occurs
      speak("Failed to connect. Using mobile camera instead.");
    }
  }



  Future<void> askForHelp() async {
    await speak("Say 'Help' if you need a guide on using SmartSight.");

    // **Increase delay before recording starts**
    await Future.delayed(Duration(seconds: 5));

    String response = await listenForInput("");

    if (response.toLowerCase() == "help") {
      speak("Here’s what you can do:");
      await Future.delayed(Duration(seconds: 3));

      speak("Say 'Describe' to understand your surroundings.");
      await Future.delayed(Duration(seconds: 4));

      speak("Say 'Navigate' to start navigation.");
      await Future.delayed(Duration(seconds: 3));

      speak("Say 'Google Maps' to get directions.");
      await Future.delayed(Duration(seconds: 3));

      speak("Say 'Add Face' to register a loved one.");
      await Future.delayed(Duration(seconds: 3));

      speak("Say 'Find Face' to detect nearby loved ones.");
      await Future.delayed(Duration(seconds: 4));

      speak("Say 'Read' to scan printed text.");
      await Future.delayed(Duration(seconds: 3));

      speak("Say 'Handwritten' to read handwritten text.");
      await Future.delayed(Duration(seconds: 3));

      speak("Say 'Smart Read' to scan text and ask questions.");
      await Future.delayed(Duration(seconds: 5));

      speak("Say 'Instagram' to get updates from your loved ones.");
    }
  }

  void showProfileDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: userName);
    TextEditingController contactController = TextEditingController(text: emergencyContact);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: contactController, decoration: InputDecoration(labelText: "Emergency Contact"), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && contactController.text.isNotEmpty) {
                saveUserData(nameController.text, contactController.text);
                Navigator.pop(context);
              } else {
                speak("Please fill in all fields.");
              }
            },
            child: Text("Save"),
          ),
          TextButton(
            onPressed: () {
              removeUserData(context);
              Navigator.pop(context);
            },
            child: Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}