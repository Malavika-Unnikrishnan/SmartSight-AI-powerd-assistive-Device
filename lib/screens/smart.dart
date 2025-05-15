import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'phone_camera_screen.dart';

class SmartScreen extends StatefulWidget {
  @override
  _SmartScreenState createState() => _SmartScreenState();
}

class _SmartScreenState extends State<SmartScreen> {
  String extractedText = "Capturing from ESP32...";
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speechToText = stt.SpeechToText();
  File? displayedImage;

  final String geminiUrl = "https://smart-read.onrender.com/ask_gemini";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => captureFromESP32());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smart OCR & QnA")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (displayedImage != null)
                Image.file(displayedImage!, height: 250, fit: BoxFit.contain),
              SizedBox(height: 20),
              Text(
                extractedText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: captureFromESP32,
                child: Text("Recapture from ESP32"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PhoneCameraScreen3()),
                  );
                },
                child: Text("Capture from Phone Camera"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> captureFromESP32() async {
    setState(() {
      extractedText = "Capturing image...";
      displayedImage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? esp32Link = prefs.getString('esp32_link');

      if (esp32Link == null || esp32Link.isEmpty) {
        throw Exception("ESP32 link not found in settings");
      }

      final response = await http.get(Uri.parse("$esp32Link/capture"));

      if (response.statusCode == 200) {
        Uint8List imageBytes = response.bodyBytes;
        File imageFile = await saveImage(imageBytes);
        setState(() {
          displayedImage = imageFile;
        });
        await speakText("Image captured successfully");
        await processImage(imageFile);
        await deleteImage(imageFile);
      } else {
        throw Exception("Failed to capture image from ESP32");
      }
    } catch (e) {
      setState(() {
        extractedText = "Error: ${e.toString()}";
      });
      await speakText("Failed to capture image");
    }
  }

  Future<File> saveImage(Uint8List imageBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/captured_image.jpg";
    File file = File(filePath);
    if (file.existsSync()) {
      await file.delete(); // delete old image first
    }
    await file.writeAsBytes(imageBytes);
    return file;
  }

  Future<void> deleteImage(File imageFile) async {
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

  Future<void> processImage(File imageFile) async {
    String text = await extractTextFromImage(imageFile);
    setState(() {
      extractedText = text.isNotEmpty ? text : "No text found!";
    });
    await speakText("Text extracted successfully");
    await Future.delayed(Duration(seconds: 2));
    speakText("What do you want to ask?");
    await Future.delayed(Duration(seconds: 2));
    listenForQuestion();
  }

  Future<String> extractTextFromImage(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  Future<void> listenForQuestion() async {
    bool available = await speechToText.initialize();
    if (available) {
      speechToText.listen(onResult: (result) {
        if (result.finalResult) {
          sendToGemini(result.recognizedWords);
        }
      });
      await Future.delayed(Duration(seconds: 5));
      speechToText.stop();
    } else {
      speakText("Speech recognition not available");
    }
  }

  Future<void> sendToGemini(String question) async {
    try {
      var response = await http.post(
        Uri.parse(geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": extractedText, "question": question}),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        speakText(data["answer"]);
      } else {
        speakText("Failed to get response from Gemini");
      }
    } catch (e) {
      speakText("Error: ${e.toString()}");
    }
  }

  Future<void> speakText(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }
}
