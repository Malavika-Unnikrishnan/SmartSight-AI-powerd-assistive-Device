import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scene_analysis.dart';
import 'profile_manager.dart';
import 'read.dart';
import 'social.dart';
import 'OutScreen.dart';
import 'settings_screen.dart'; // Import Settings Screen
import 'dummy.dart';
import'scene_analysis_esp.dart';
import 'scene_analysis_camera.dart';
import 'face.dart';
import 'voice.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProfileManager profileManager = ProfileManager();

  @override
  void initState() {
    super.initState();
    profileManager.loadUserData(context);
  }

  void _openProfile() {
    profileManager.showProfileDialog(context);
  }

  Future<void> _handleSceneAnalysis() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int esp32Status = prefs.getInt('esp32ConnectionStatus') ?? 0;

    if (esp32Status == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SceneAnalysisESP()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SceneAnalysisCamera()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SmartSight"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: _openProfile,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.only(top: 50), // Move items higher
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "SmartSight Menu",
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text("Developers"),
              subtitle: Text("Amy, Malavika, Marina"),
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text("Feedback"),
              subtitle: Text("Reach out at:\nmalavikaunnikrishnan2016@gmail.com"),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton('Scene Analysis', onPressed: _handleSceneAnalysis),
            buildButton('Navigation', onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => OutScreen()));
            }),
            buildButton('Read', onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ReadScreen()));
            }),
            buildButton('Face Recognition', onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => FaceScreen()));

            }),
            buildButton('Instagram', onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SocialScreen()));
            }),
            buildButton('Speak Now',  onPressed: () {
              VoiceCommandHandler(context).startListening();

            }),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String text, {bool isSpeakButton = false, VoidCallback? onPressed}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        width: 250,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSpeakButton ? Colors.black : Colors.grey[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

