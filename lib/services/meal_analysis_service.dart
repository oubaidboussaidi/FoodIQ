import 'dart:convert';
import '../models/scanned_food.dart';
import '../models/food.dart';
import 'food_nlp_engine.dart';
import 'food_database.dart';

class MealAnalysisService {
  // Initialize the Advanced NLP Engine
  final FoodNlpEngine _nlpEngine = FoodNlpEngine();

  /// Purely Local Analysis with Advanced NLP (Fully Offline)
  Future<List<ScannedFood>> analyzeText(String description) async {
    if (description.trim().isEmpty) {
      throw "Describe your meal first! I can't track silence (yet).";
    }

    try {
      // STEP 1: Use Advanced NLP to parse the input locally
      final List<UsdaFoodResult> nlpResults = _nlpEngine.parse(description);
      
      // FUNNY CHECK: If no food items were detected at all
      if (nlpResults.isEmpty) {
        final funnyMessages = [
          "Nice try, but I don't see any food here. Are you trying to track air?",
          "I'm a calorie tracker, not a philosopher. Please enter something edible!",
          "That sounds... interesting, but my database says it's not food. Don't eat your shoes!",
          "If that's a meal, I'm a toaster. Tell me what you *actually* ate!",
          "I searched high and low, but 'stuff' isn't on the menu today.",
          "Even a hungry Gazelle wouldn't eat that. Try entering some real food!",
        ];
        throw funnyMessages[description.length % funnyMessages.length];
      }

      List<ScannedFood> results = [];

      // STEP 2: Resolve nutrition from Local Database
      for (var item in nlpResults) {
        final nutrition = _getDatabaseNutrition(item.description);
        
        if (nutrition['found'] == false) {
           throw "I know what '${item.description}' is, but I don't have its macros yet. Try something common like 'Chicken' or 'Pasta'.";
        }
        
        // Add to results
        results.add(ScannedFood(
          name: nutrition['name'] ?? item.description,
          detectionConfidence: item.confidence,
          // DB values are per 1g base unit, ScannedFood expects per 100g/unit for consistency in UI
          caloriesPer100g: (nutrition['calories'] ?? 0.0).toDouble() * 100,
          proteinPer100g: (nutrition['protein'] ?? 0.0).toDouble() * 100,
          carbsPer100g: (nutrition['carbs'] ?? 0.0).toDouble() * 100,
          fatPer100g: (nutrition['fat'] ?? 0.0).toDouble() * 100,
          fiberPer100g: 0.0,
          sugarPer100g: 0.0,
          sodiumPer100g: 0.0,
          defaultPortionG: item.amount,
          nutritionEstimated: false,
          fdcId: null,
          calculationSource: "Local Intelligence (Offline)",
        ));
      }

      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// Returns nutrition values from the central FoodDatabase
  Map<String, dynamic> _getDatabaseNutrition(String foodName) {
    final lowercaseName = foodName.toLowerCase();
    
    // Look through all foods in the unified database
    final results = FoodDatabase.allFoods.where((f) => 
      f.name.toLowerCase() == lowercaseName || 
      f.name.toLowerCase().contains(lowercaseName)
    ).toList();

    if (results.isNotEmpty) {
      // Prioritize exact match if multiple found
      final dbFood = results.firstWhere(
        (f) => f.name.toLowerCase() == lowercaseName,
        orElse: () => results.first,
      );

      return {
        'found': true,
        'name': dbFood.name,
        'calories': dbFood.caloriesPerUnit,
        'protein': dbFood.proteinPerUnit,
        'carbs': dbFood.carbsPerUnit,
        'fat': dbFood.fatPerUnit,
      };
    }

    return {'found': false};
  }
}
