import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator
  // If running on a real device, replace with your PC's local IP address (e.g., 192.168.1.x)
  static const String baseUrl = 'http://10.0.2.2:8000'; 
  
  Future<Map<String, dynamic>> analyzeMeal(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze-meal'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to analyze meal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }
}
