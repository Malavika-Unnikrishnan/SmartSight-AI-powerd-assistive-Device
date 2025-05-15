import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController _esp32Controller = TextEditingController();
  String? _savedLink;

  @override
  void initState() {
    super.initState();
    _loadSavedLink();
  }

  Future<void> _loadSavedLink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedLink = prefs.getString('esp32_link');
      _esp32Controller.text = _savedLink ?? "";
    });
  }

  Future<void> _saveLink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_link', _esp32Controller.text);
    setState(() {
      _savedLink = _esp32Controller.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ESP32-CAM Link Saved!")));
  }

  Future<void> _removeLink() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('esp32_link');
    setState(() {
      _savedLink = null;
      _esp32Controller.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ESP32-CAM Link Removed!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ESP32-CAM Link",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _esp32Controller,
              decoration: InputDecoration(
                hintText: "Enter ESP32-CAM Link",
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _esp32Controller.clear();
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveLink,
                  child: Text("Save"),
                ),
                ElevatedButton(
                  onPressed: _removeLink,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Remove"),
                ),
              ],
            ),
            if (_savedLink != null) ...[
              SizedBox(height: 20),
              Text("Saved Link:", style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_savedLink ?? ""),
            ]
          ],
        ),
      ),
    );
  }
}
