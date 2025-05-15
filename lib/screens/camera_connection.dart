import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CameraConnection {
  static Future<bool> connect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String ipAddress = prefs.getString('ip_address') ?? 'http://192.168.101.26';

    try {
      var response = await http.get(Uri.parse(ipAddress));
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
