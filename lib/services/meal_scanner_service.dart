import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/scanned_food.dart';

class MealScannerService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator
  // Change this to your deployed backend URL in production
  static const String baseUrl = 'http://10.0.2.2:8000'; 

  Future<List<ScannedFood>> scanMeal(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/scan-meal'));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> foodsJson = data['foods'];
        return foodsJson.map((json) => ScannedFood.fromJson(json)).toList();
      } else {
        throw Exception('Failed to scan meal: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to scanning service: $e');
    }
  }
}
