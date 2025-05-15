import 'package:flutter/material.dart';

class DummyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Connection Error")),
      body: Center(
        child: Text(
          "ESP32 not connected!",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
    );
  }
}
