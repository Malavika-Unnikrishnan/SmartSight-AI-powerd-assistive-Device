import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

class SocialScreen extends StatefulWidget {
  @override
  _SocialScreenState createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  List<Map<String, String>> savedEntries = [];
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _loadSavedEntries();
  }

  Future<void> _loadSavedEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedData = prefs.getStringList('social_entries');
    if (savedData != null) {
      setState(() {
        savedEntries = savedData
            .map((entry) {
          List<String> parts = entry.split('|');
          return {"username": parts[0], "relation": parts[1]};
        })
            .toList();
      });
    }
  }

  Future<void> _saveEntry(String username, String relation) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedEntries.add({"username": username, "relation": relation});
    List<String> savedData =
    savedEntries.map((entry) => "${entry['username']}|${entry['relation']}").toList();
    await prefs.setStringList('social_entries', savedData);
    setState(() {});
  }

  Future<void> _removeEntry(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedEntries.removeAt(index);
    List<String> savedData =
    savedEntries.map((entry) => "${entry['username']}|${entry['relation']}").toList();
    await prefs.setStringList('social_entries', savedData);
    setState(() {});
  }

  Future<void> _fetchAndRead(String username, String relation) async {
    final url = Uri.parse("https://socialmediaa-f0ly.onrender.com/predict");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "name_or_relation": relation}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body)['result'];
        if (result != null && result.isNotEmpty) {
          _speak(result);
          _showMessage(result, success: true);
        } else {
          _showMessage("No updates found.", success: false);
        }
      } else {
        _showMessage("Error fetching data. Try again later.", success: false);
      }
    } catch (e) {
      _showMessage("Failed to connect to server.", success: false);
    }
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _showMessage(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _showAddDialog() {
    TextEditingController usernameController = TextEditingController();
    TextEditingController relationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Instagram User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: "Instagram Username"),
            ),
            TextField(
              controller: relationController,
              decoration: InputDecoration(labelText: "Name or Relation"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String username = usernameController.text.trim();
              String relation = relationController.text.trim();
              if (username.isNotEmpty && relation.isNotEmpty) {
                _saveEntry(username, relation);
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Instagram Updates"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: savedEntries.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(savedEntries[index]["relation"]!),
                      subtitle: Text(savedEntries[index]["username"]!),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeEntry(index),
                      ),
                      onTap: () {
                        _fetchAndRead(
                          savedEntries[index]["username"]!,
                          savedEntries[index]["relation"]!,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
