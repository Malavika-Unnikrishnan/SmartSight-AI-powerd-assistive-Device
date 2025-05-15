import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'print_phone_screen.dart';

class PrintScreen extends StatefulWidget {
  @override
  _PrintScreenState createState() => _PrintScreenState();
}

class _PrintScreenState extends State<PrintScreen> {
  String extractedText = "Capturing image...";
  FlutterTts flutterTts = FlutterTts();
  File? imageFile;

  @override
  void initState() {
    super.initState();
    captureAndExtractFromESP();
  }

  Future<void> captureAndExtractFromESP() async {
    setState(() => extractedText = "Capturing image...");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? esp32Url = prefs.getString('esp32_link');

      if (esp32Url == null || esp32Url.isEmpty) {
        throw Exception("ESP32 link not found in settings");
      }

      final fullUrl = "$esp32Url/capture";
      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        Uint8List imageBytes = response.bodyBytes;
        final directory = await getApplicationDocumentsDirectory();
        final filePath = "${directory.path}/esp_captured.jpg";
        File file = File(filePath);
        await file.writeAsBytes(imageBytes);
        setState(() => imageFile = file);

        await processImage(file);
      } else {
        throw Exception("Failed to get image from ESP");
      }
    } catch (e) {
      setState(() => extractedText = "SmartSight not working. Would you like to shift to phone camera?");
      await flutterTts.speak("SmartSight not working. Would you like to shift to phone camera?");
      await Future.delayed(Duration(seconds: 5));
      // Simulating user voice input "yes" for now
      bool userSaidYes = true; // Replace this with actual speech recognition logic
      if (userSaidYes) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PrintPhoneScreen()),
        );
      }
    }
  }

  Future<void> processImage(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    setState(() {
      extractedText = recognizedText.text.isNotEmpty ? recognizedText.text : "No text found!";
    });

    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(extractedText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Printed Text Recognition"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageFile != null)
                Image.file(imageFile!, width: 300, height: 200, fit: BoxFit.cover),
              SizedBox(height: 20),
              Text(
                extractedText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: captureAndExtractFromESP,
                child: Text("Use ESP Camera"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PrintPhoneScreen()),
                ),
                child: Text("Use Phone Camera"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}