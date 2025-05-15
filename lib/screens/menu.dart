import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  TextEditingController ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    ipController.text = prefs.getString('ip_address') ?? 'http://192.168.205.200';
  }

  void _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip_address', ipController.text);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Menu")),
      body: ListView(
        children: [
          ListTile(
            title: Text("Settings"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Camera Settings"),
                    content: TextField(
                      controller: ipController,
                      decoration: InputDecoration(labelText: "Camera IP Address"),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: _saveSettings,
                        child: Text("Save"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            title: Text("Contact"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Contact Developers"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Amy M Elamblasserial"),
                        Text("Malavika Unnikrishnan"),
                        Text("Marina Rose Shaju"),
                        Text("Email: smartsight789@gmail.com"),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
