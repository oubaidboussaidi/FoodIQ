import 'package:string_similarity/string_similarity.dart';
import 'food_database.dart';
import '../models/food.dart';

/// =======================================================
/// FoodIQ NEURAL OFFLINE ENGINE (SYNCED WITH DATABASE)
/// =======================================================

class FoodNlpEngine {
  /// Fuse the manual Food Database with the NLP engine
  /// This ensures that every food in the DB is scannable by AI
  static final List<String> foodDb = _generateNlpDb();

  static List<String> _generateNlpDb() {
    final Set<String> uniqueFoods = {};
    
    // 1. Add everything from the manual FoodDatabase
    for (var food in FoodDatabase.allFoods) {
      uniqueFoods.add(food.name.toLowerCase());
      
      // Also add common shorthands (e.g., "Egg Whites" -> "egg whites", "Chicken Breast" -> "chicken")
      final parts = food.name.toLowerCase().split(' ');
      if (parts.length > 1) {
        // Add the primary keyword (e.g., "chicken", "beef", "rice")
        uniqueFoods.add(parts[0]);
      }
    }

    // 2. Add high-level categories and synonyms not explicitly in names
    final extraSynonyms = [
      "pasta", "spaghetti", "macaroni", "penne", "lasagna", "toast", "pancake", "waffle",
      "cereal", "donut", "pastry", "eggs", "boiled egg", "fried egg", "scrambled eggs", "omelette",
      "cheese", "sausage", "pepperoni", "salami", "prosciutto", "prawns", "calamari", "lettuce",
      "squash", "grapes", "cranberry", "nuts", "hummus", "pizza", "burger", "hamburger",
      "cheeseburger", "fries", "french fries", "taco", "burrito", "nachos", "chips", "nuggets",
      "sandwich", "wrap", "sushi", "kebab", "shawarma", "falafel", "cookie", "cake", "ice cream",
      "jam", "candy", "water", "cola", "coke", "soda", "lemonade", "mayo", "pesto", "guacamole", "salsa"
    ];
    uniqueFoods.addAll(extraSynonyms);

    return uniqueFoods.toList();
  }

  /// Maps internal food names to USDA/Database entries
  static final Map<String, String> usdaNames = _generateUsdaNames();

  static Map<String, String> _generateUsdaNames() {
    final Map<String, String> map = {
      // Manual mappings for categories/synonyms
      "egg": "Egg (Whole Boiled)",
      "eggs": "Egg (Whole Boiled)",
      "boiled egg": "Egg (Whole Boiled)",
      "fried egg": "Egg (Fried)",
      "scrambled eggs": "Egg (Scrambled)",
      "omelette": "Egg (Scrambled)",
      "pasta": "Pasta (Cooked)",
      "spaghetti": "Pasta (Cooked)",
      "cheese": "Cheddar Cheese",
      "burger": "hamburger", // USDA fallback
      "burgers": "hamburger",
      "fries": "Fast foods, potatoes, french fried",
    };

    // Add direct matches and shorthands from our Database
    for (var food in FoodDatabase.allFoods) {
      final fullName = food.name.toLowerCase();
      map[fullName] = food.name;
      
      // Add primary keyword (e.g., "chicken" for "Chicken Breast")
      final parts = fullName.split(' ');
      if (parts.length > 1) {
        // We use putIfAbsent to ensure we don't overwrite more specific mappings
        map.putIfAbsent(parts[0], () => food.name);
      }
    }

    return map;
  }

  /// USDA Specific Overrides (kept for high-accuracy searches)
  static final Map<String, String> usdaOverrides = {
    "hamburger": "Fast foods, hamburger; single, regular patty; plain",
    "french fries": "Fast foods, potatoes, french fried",
    "pizza": "Pizza, cheese topping, regular crust",
  };

  /// Mapping nutrition for ScannedFood when offline
  static final Map<String, Map<String, double>> nutritionOverrides = _generateNutritionMap();

  static Map<String, Map<String, double>> _generateNutritionMap() {
    final Map<String, Map<String, double>> map = {};
    
    for (var food in FoodDatabase.allFoods) {
      map[food.name] = {
        "cal": food.caloriesPerUnit,
        "protein": food.proteinPerUnit,
        "fat": food.fatPerUnit,
        "carbs": food.carbsPerUnit,
        "fiber": 0, // DB doesn't have fiber yet
        "sugar": 0,
        "sodium": 0,
      };
    }
    return map;
  }

  final Map<String, double> portionMap = {
    "plate": 250, "bowl": 200, "cup": 150, "glass": 200, "mug": 250,
    "tablespoon": 15, "tbsp": 15, "teaspoon": 5, "tsp": 5,
    "slice": 30, "piece": 50, "item": 100, "unit": 100, "handful": 30,
  };

  final Map<String, double> numberMap = {
    "a": 1, "an": 1, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "half": 0.5, "quarter": 0.25,
  };

  final Map<String, double> sizeModifiers = {
    "small": 0.7, "medium": 1.0, "large": 1.4, "big": 1.4, "huge": 1.7, "tiny": 0.4,
  };

  final Map<String, double> unitToGrams = {
    "g": 1, "gram": 1, "grams": 1, "kg": 1000, "ml": 1, "l": 1000, "oz": 28.35, "lb": 453.6,
  };

  List<UsdaFoodResult> parse(String input) {
    final clean = _normalize(input);
    final tokens = clean.split(' ');
    final results = <UsdaFoodResult>[];
    
    int i = 0;
    while (i < tokens.length) {
      double qty = 1;
      double sizeFactor = 1;
      String? portion;
      String? size;
      double? explicitGrams;

      if (i < tokens.length && _isNumber(tokens[i])) {
        qty = _parseNumber(tokens[i]);
        i++;
      }

      if (i < tokens.length && sizeModifiers.containsKey(tokens[i])) {
        size = tokens[i];
        sizeFactor = sizeModifiers[tokens[i]]!;
        i++;
      }

      if (i < tokens.length && _looksLikeUnit(tokens[i])) {
        explicitGrams = _parseUnit(tokens[i]);
        i++;
      }

      if (i < tokens.length && portionMap.containsKey(tokens[i])) {
        portion = tokens[i];
        i++;
        if (i < tokens.length && tokens[i] == "of") i++;
      }

      bool foundFood = false;
      for (int n = 4; n >= 1 && !foundFood; n--) {
        if (i + n > tokens.length) continue;
        final phrase = tokens.sublist(i, i + n).join(' ');
        final foodKey = _matchFood(phrase);
        
        if (foodKey != null) {
          final resolvedName = usdaNames[foodKey] ?? foodKey;
          // Try to find if this food has a specific base weight override
          final grams = explicitGrams ?? _resolveGrams(resolvedName, portion, qty, sizeFactor);
          results.add(UsdaFoodResult(
            description: resolvedName,
            amount: grams,
            householdMeasure: portion != null ? HouseholdMeasure(measure: portion, quantity: qty, modifier: size) : null,
            confidence: explicitGrams != null ? 0.98 : 0.9,
          ));
          i += n;
          foundFood = true;
        }
      }
      
      if (!foundFood) i++;
    }
    return _merge(results);
  }

  String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^\w\s.]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isNumber(String t) => numberMap.containsKey(t) || double.tryParse(t) != null;
  double _parseNumber(String t) => numberMap[t] ?? double.tryParse(t) ?? 1;
  bool _looksLikeUnit(String t) => RegExp(r'^\d+(\.\d+)?(g|kg|ml|l|oz|lb)$').hasMatch(t);

  double _parseUnit(String t) {
    final value = double.parse(RegExp(r'^\d+(\.\d+)?').firstMatch(t)!.group(0)!);
    final unit = RegExp(r'(g|kg|ml|l|oz|lb)$').firstMatch(t)!.group(0)!;
    return value * unitToGrams[unit]!;
  }

  String? _matchFood(String phrase) {
    for (final f in foodDb) {
      if (phrase == f) return f;
    }
    // Fallback to fuzzy matching
    for (final f in foodDb) {
      if (phrase.similarityTo(f) > 0.88) return f;
    }
    return null;
  }

  double _resolveGrams(String resolvedName, String? portion, double qty, double size) {
    // Try to get specific serving weight from FoodDatabase if available
    double baseWeight = 100; // Default fallback

    final dbFood = FoodDatabase.allFoods.firstWhere(
      (f) => f.name.toLowerCase() == resolvedName.toLowerCase(),
      orElse: () => FoodDatabase.allFoods[0], // fallback ignore
    );
    
    if (portion != null) {
       // If the portion matches a serving size key in DB
       final dbServing = dbFood.servingSizes?.entries.firstWhere(
         (e) => e.key.toLowerCase().contains(portion.toLowerCase()),
         orElse: () => MapEntry("", portionMap[portion]!),
       );
       baseWeight = dbServing?.value ?? portionMap[portion]!;
    } else if (dbFood.defaultUnit == FoodUnit.piece) {
       baseWeight = 1; // It's item based
    }

    return baseWeight * qty * size;
  }

  List<UsdaFoodResult> _merge(List<UsdaFoodResult> list) {
    final Map<String, UsdaFoodResult> map = {};
    for (final r in list) {
      if (!map.containsKey(r.description)) {
        map[r.description] = r;
      } else {
        map[r.description] = UsdaFoodResult(
          description: r.description,
          amount: map[r.description]!.amount + r.amount,
          householdMeasure: r.householdMeasure,
          confidence: map[r.description]!.confidence,
        );
      }
    }
    return map.values.toList();
  }
}

class HouseholdMeasure {
  final String measure;
  final double quantity;
  final String? modifier;
  HouseholdMeasure({required this.measure, required this.quantity, this.modifier});
  Map<String, dynamic> toJson() => {"measure": measure, "quantity": quantity, "modifier": modifier};
}

class UsdaFoodResult {
  final String description;
  final double amount;
  final String unit;
  final HouseholdMeasure? householdMeasure;
  final double confidence;
  UsdaFoodResult({required this.description, required this.amount, this.unit = "g", this.householdMeasure, required this.confidence});
  Map<String, dynamic> toJson() => {"description": description, "amount": amount, "unit": unit, "householdMeasure": householdMeasure?.toJson(), "confidence": confidence};
}
