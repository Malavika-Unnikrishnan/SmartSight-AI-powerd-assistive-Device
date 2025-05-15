import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ObjectDetectionScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ObjectDetectionScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  late CameraController _cameraController;
  FlutterVision vision = FlutterVision();
  FlutterTts flutterTts = FlutterTts();

  bool isDetecting = false;
  bool isSpeaking = false;
  bool isCameraInitialized = false;
  bool isModelLoaded = false;

  List<String> detectedLabels = [];
  Map<String, int> detectedObjects = {}; // Track detected objects
  Timer? cooldownTimer;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadModel();
    configureTTS();
  }

  /// Initializes the camera
  Future<void> initializeCamera() async {
    try {
      _cameraController = CameraController(widget.cameras[0], ResolutionPreset.medium);
      await _cameraController.initialize();
      if (!mounted) return;
      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  /// Loads YOLO model
  Future<void> loadModel() async {
    try {
      await vision.loadYoloModel(
        labels: 'assets/labels.txt',
        modelPath: 'assets/yolov8.tflite',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: false,
      );
      setState(() {
        isModelLoaded = true;
      });
    } catch (e) {
      print("Model loading error: $e");
    }
  }

  /// Configures text-to-speech
  void configureTTS() {
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  /// Starts object detection
  void startDetection() async {
    if (!isCameraInitialized || !isModelLoaded) return;
    await flutterTts.speak("Keep the device in the direction you move.");
    await Future.delayed(Duration(seconds: 3));

    if (!_cameraController.value.isStreamingImages) {
      _cameraController.startImageStream((CameraImage cameraImage) async {
        if (!isDetecting) {
          isDetecting = true;
          await processFrame(cameraImage);
          isDetecting = false;
        }
      });
    }
  }

  /// Processes a camera frame and detects objects
  Future<void> processFrame(CameraImage cameraImage) async {
    final List<Uint8List> bytesList = cameraImage.planes.map((plane) => plane.bytes).toList();

    final result = await vision.yoloOnFrame(
      bytesList: bytesList,
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      iouThreshold: 0.4,
      confThreshold: 0.4,
      classThreshold: 0.4,
    );

    setState(() {
      detectedLabels = result.map((detection) => detection["tag"] as String).toList();
    });

    if (result.isNotEmpty) {
      handleObjectSpeech(result, cameraImage.width);
    }
  }

  /// Handles speech output for detected objects
  void handleObjectSpeech(List<Map<String, dynamic>> objects, int imageWidth) {
    detectedObjects.removeWhere((key, value) => DateTime.now().millisecondsSinceEpoch - value > 3000);

    List<String> newObjectsToSpeak = [];

    for (var obj in objects) {
      String label = obj["tag"];
      List<dynamic> box = obj["box"];

      if (box.length < 3) continue;

      double x = box[0];
      double width = box[2];
      double objCenter = x + (width / 2);

      String position = determinePosition(objCenter, imageWidth);
      String spokenLabel = "$label on the $position";

      if (!detectedObjects.containsKey(spokenLabel)) {
        newObjectsToSpeak.add(spokenLabel);
        detectedObjects[spokenLabel] = DateTime.now().millisecondsSinceEpoch;
      }
    }

    if (newObjectsToSpeak.isNotEmpty && !isSpeaking) {
      speakDetectedObjects(newObjectsToSpeak);
    }
  }

  /// Determines object position (left, center, right)
  String determinePosition(double objCenter, int imageWidth) {
    if (objCenter < imageWidth / 3) {
      return "left";
    } else if (objCenter > 2 * imageWidth / 3) {
      return "right";
    } else {
      return "center";
    }
  }

  /// Speaks detected objects
  Future<void> speakDetectedObjects(List<String> objects) async {
    if (isSpeaking) return;

    isSpeaking = true;
    String message = objects.join(", ");
    await flutterTts.speak(message);

    cooldownTimer?.cancel();
    cooldownTimer = Timer(Duration(seconds: 2), () {
      isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    vision.closeYoloModel();
    flutterTts.stop();
    cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text("Object Detection")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Navigation assistance")),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          if (!isModelLoaded)
            Center(child: CircularProgressIndicator()), // Show while loading model
          if (detectedLabels.isNotEmpty)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.black54,
                child: Text(
                  "Detected: ${detectedLabels.join(", ")}",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: startDetection,
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
