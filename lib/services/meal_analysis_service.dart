import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/scanned_food.dart';
import 'food_nlp_engine.dart';

class MealAnalysisService {
  // USDA API Key
  static const String usdaApiKey = 'FarFUhNBd1XLEy5g8AC0VwCDY9S7F5XK8YUkbldG'; 

  // Initialize the Advanced NLP Engine
  final FoodNlpEngine _nlpEngine = FoodNlpEngine();

  /// Smart Client-Side Analysis with Advanced NLP
  /// 
  /// Features:
  /// 1. [Fuzzy Food Matching]: Uses string similarity for typo tolerance.
  /// 2. [Household Measures]: Detects "plate", "bowl", "cup", "tablespoon", etc.
  /// 3. [Size Modifiers]: Handles "small", "large", "big".
  /// 4. [Number Words]: Converts "one", "two", "half" to numeric values.
  /// 5. [Explicit Units]: Parses "200g", "1.5kg", "250ml", "3oz".
  Future<List<ScannedFood>> analyzeText(String description) async {
    try {
      // STEP 1: Check for internet connectivity
      bool isOnline = false;
      try {
        final result = await InternetAddress.lookup('google.com');
        isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        isOnline = false;
      }

      // STEP 2: Use Advanced NLP to parse the input
      final List<UsdaFoodResult> nlpResults = _nlpEngine.parse(description);
      
      List<ScannedFood> results = [];

      // STEP 3: Query USDA for each identified food
      for (var item in nlpResults) {
        Map<String, dynamic> nutrition;
        String statusMsg;

        if (isOnline) {
          nutrition = await _fetchUsdaNutrition(item.description);
          statusMsg = "Nutrition calculated online.";
        } else {
          // Offline mode
          nutrition = _getFallbackNutrition(item.description);
          if (nutrition['found'] == false) {
             throw "Please connect to the internet to analyze this food ('${item.description}').";
          }
          statusMsg = "Nutrition calculated offline.";
        }
        
        // Add to results
        results.add(ScannedFood(
          name: nutrition['name'] ?? item.description,
          detectionConfidence: item.confidence,
          caloriesPer100g: nutrition['calories'] ?? 0.0,
          proteinPer100g: nutrition['protein'] ?? 0.0,
          carbsPer100g: nutrition['carbs'] ?? 0.0,
          fatPer100g: nutrition['fat'] ?? 0.0,
          fiberPer100g: nutrition['fiber'] ?? 0.0,
          sugarPer100g: nutrition['sugar'] ?? 0.0,
          sodiumPer100g: nutrition['sodium'] ?? 0.0,
          defaultPortionG: item.amount,
          nutritionEstimated: !nutrition['found'],
          fdcId: nutrition['fdc_id'],
          calculationSource: statusMsg,
        ));
      }

      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches nutrition from USDA FoodData Central with intelligent fallback
  Future<Map<String, dynamic>> _fetchUsdaNutrition(String query) async {
    if (query.isEmpty) return _getFallbackNutrition(query);

    // Step 1: Check if we should override this query with a specific USDA variant
    final overrideQuery = usdaOverrides[query.toLowerCase()] ?? query;

    final url = Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=$usdaApiKey&query=$overrideQuery&pageSize=3&dataType=Foundation,SR Legacy'
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['foods'] != null && (data['foods'] as List).isNotEmpty) {
          final food = data['foods'][0]; 
          final nutrients = food['foodNutrients'] as List;
          
          double getVal(int id) {
            final n = nutrients.firstWhere((n) => n['nutrientId'] == id, orElse: () => null);
            return n != null ? (n['value'] as num).toDouble() : 0.0;
          }

          final calories = getVal(1008);
          final protein = getVal(1003);
          final carbs = getVal(1005);
          final fat = getVal(1004);
          final fiber = getVal(1079);
          final sugar = getVal(2000);
          final sodium = getVal(1093);

          // Step 2: If API returned 0 values, fall back to offline database
          if (calories == 0.0 && protein == 0.0) {
            print("⚠️ USDA returned 0 for '$overrideQuery', using offline fallback...");
            return _getFallbackNutrition(overrideQuery);
          }

          return {
            'found': true,
            'name': food['description'],
            'calories': calories,
            'protein': protein,
            'carbs': carbs,
            'fat': fat, 
            'fiber': fiber,
            'sugar': sugar,
            'sodium': sodium,
            'fdc_id': food['fdcId'],
          };
        }
      }
    } catch (e) {
      print("USDA Error for $query: $e");
    }

    // Step 3: API failed or returned nothing, use fallback
    return _getFallbackNutrition(overrideQuery);
  }

  /// Returns offline nutrition values if available, otherwise returns empty data
  Map<String, dynamic> _getFallbackNutrition(String foodName) {
    final nutrition = nutritionOverrides[foodName];
    
    if (nutrition != null) {
      print("✅ Using offline nutrition for '$foodName'");
      return {
        'found': true,
        'name': foodName,
        'calories': nutrition['cal'] ?? 0.0,
        'protein': nutrition['protein'] ?? 0.0,
        'carbs': nutrition['carbs'] ?? 0.0,
        'fat': nutrition['fat'] ?? 0.0,
        'fiber': nutrition['fiber'] ?? 0.0,
        'sugar': nutrition['sugar'] ?? 0.0,
        'sodium': nutrition['sodium'] ?? 0.0,
        'fdc_id': null,
      };
    }

    // No fallback available
    return {
      'found': false,
      'name': foodName, 
      'calories': 0.0, 
      'protein': 0.0, 
      'carbs': 0.0, 
      'fat': 0.0,
      'fiber': 0.0,
      'sugar': 0.0,
      'sodium': 0.0,
    };
  }
}
