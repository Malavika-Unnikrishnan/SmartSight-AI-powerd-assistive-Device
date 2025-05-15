import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'print.dart';
import 'print_phone_screen.dart';
import 'handwritten.dart';
import 'PhoneCameraCaptureScreen.dart';
import 'smart.dart';
import 'phone_camera_screen.dart';

class ReadScreen extends StatelessWidget {
  const ReadScreen({super.key});

  Future<void> _handlePrintedText(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int esp32Status = prefs.getInt('esp32ConnectionStatus') ?? 0;

    if (esp32Status == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PrintScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PrintPhoneScreen()));
    }
  }

  Future<void> _handleHandwritten(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int esp32Status = prefs.getInt('esp32ConnectionStatus') ?? 0;

    if (esp32Status == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => HandwrittenScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PhoneCameraCaptureScreen()));
    }
  }

  Future<void> _handleSmartRead(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int esp32Status = prefs.getInt('esp32ConnectionStatus') ?? 0;

    if (esp32Status == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SmartScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PhoneCameraScreen3()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Read Options"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton(context, "Printed Text", () => _handlePrintedText(context)),
            buildButton(context, "Handwritten", () => _handleHandwritten(context)),
            buildButton(context, "Smart Read", () => _handleSmartRead(context)),
          ],
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        width: 250,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// Dummy placeholders for now
class Class1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Class1")));
}

class Class2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Class2")));
}

class Class3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Class3")));
}

class Class4 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Class4")));
}

class Class5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Class5")));
}

class Class6 extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text("Class6")));
}
