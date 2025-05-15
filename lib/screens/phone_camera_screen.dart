import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';

class PhoneCameraScreen3 extends StatefulWidget {
  @override
  _PhoneCameraScreen3State createState() => _PhoneCameraScreen3State();
}

class _PhoneCameraScreen3State extends State<PhoneCameraScreen3> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  String? imagePath;
  String answerText = "";
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speechToText = stt.SpeechToText();
  final String geminiUrl = "https://smart-read.onrender.com/ask_gemini";
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    initCameraAndCapture();
  }

  Future<void> initCameraAndCapture() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.medium);
    await _cameraController!.initialize();
    setState(() {});
    await Future.delayed(Duration(seconds: 2));
    await captureImage();
  }

  Future<void> captureImage() async {
    if (!_cameraController!.value.isInitialized) return;
    XFile file = await _cameraController!.takePicture();
    setState(() {
      imagePath = file.path;
    });
    await speakText("Image captured");
    processImage(File(file.path));
  }

  Future<void> processImage(File imageFile) async {
    String text = await extractTextFromImage(imageFile);
    await speakText("Text extracted");
    await Future.delayed(Duration(seconds: 1));
    await speakText("What do you want to ask?");
    await Future.delayed(Duration(seconds: 2));
    listenForQuestion(text);
  }

  Future<String> extractTextFromImage(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  Future<void> listenForQuestion(String extractedText) async {
    bool available = await speechToText.initialize();
    if (available) {
      speechToText.listen(onResult: (result) {
        if (result.finalResult) {
          sendToGemini(extractedText, result.recognizedWords);
        }
      });
      await Future.delayed(Duration(seconds: 6));
      speechToText.stop();
    } else {
      speakText("Speech recognition not available");
    }
  }

  Future<void> sendToGemini(String text, String question) async {
    setState(() {
      isProcessing = true;
    });

    try {
      var response = await http.post(
        Uri.parse(geminiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text, "question": question}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        String answer = data["answer"];
        setState(() {
          answerText = answer;
        });
        speakText(answer);
      } else {
        speakText("Failed to get response from Gemini");
      }
    } catch (e) {
      speakText("Error: ${e.toString()}");
    }

    setState(() {
      isProcessing = false;
    });
  }

  Future<void> speakText(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smart Camera Q&A")),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_cameraController != null && _cameraController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                if (imagePath != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Image.file(
                      File(imagePath!),
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (isProcessing)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                if (answerText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      answerText,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
