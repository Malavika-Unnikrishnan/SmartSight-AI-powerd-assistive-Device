import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';

class CamNavigationScreen extends StatefulWidget {
  @override
  _CamNavigationScreenState createState() => _CamNavigationScreenState();
}

class _CamNavigationScreenState extends State<CamNavigationScreen> {
  late CameraController _cameraController;
  FlutterVision vision = FlutterVision();
  bool isDetecting = false;
  List<Map<String, dynamic>> detections = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
    loadModel();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    if (!mounted) return;
    setState(() {});
    startDetection();
  }

  Future<void> loadModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/yolov8.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
  }

  void startDetection() {
    _cameraController.startImageStream((CameraImage cameraImage) async {
      if (!isDetecting) {
        isDetecting = true;
        final List<Uint8List> bytesList = cameraImage.planes.map((plane) => plane.bytes).toList();

        final result = await vision.yoloOnFrame(
          bytesList: bytesList,
          imageHeight: cameraImage.height,
          imageWidth: cameraImage.width,
          iouThreshold: 0.2,
          confThreshold: 0.2,
          classThreshold: 0.2,
        );

        setState(() {
          detections = result;
        });

        isDetecting = false;
      }
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("YOLOv8 Object Detection")),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          ...detections.map((detection) => Positioned(
            left: detection["box"][0].toDouble(),
            top: detection["box"][1].toDouble(),
            child: Container(
              padding: const EdgeInsets.all(4),
              color: Colors.red,
              child: Text(detection["tag"], style: const TextStyle(color: Colors.white)),
            ),
          )),
        ],
      ),
    );
  }
}
