import 'package:flutter/material.dart';

class SceneAnalysisScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scene Analysis (No ESP32)")),
      body: Center(
        child: Text(
          "ESP32 is not connected. Running limited scene analysis.",
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
