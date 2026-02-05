enum FoodUnit {
  g('g', 1.0),
  mg('mg', 0.001),
  ml('ml', 1.0),
  l('L', 1000.0),
  tbsp('tbsp', 15.0), // approx 15g/ml
  tsp('tsp', 5.0),   // approx 5g/ml
  piece('piece', 1.0),
  slice('slice', 1.0); // usually treated as a piece or ~25-30g, here 1.0 multiplier assuming cal/piece logic

  final String label;
  final double multiplier; // Multiplier to get to base unit (g or ml or piece)
  const FoodUnit(this.label, this.multiplier);
}

  final List<FoodUnit> allowedUnits;
  final FoodUnit defaultUnit;

  // NEW (optional)
  final Map<String, double>? servingSizes; // label -> quantity in base unit

  Food({
    required this.name,
    required this.emoji,
    required this.caloriesPerUnit,
    required this.proteinPerUnit,
    required this.carbsPerUnit,
    required this.fatPerUnit,
    required this.allowedUnits,
    required this.defaultUnit,
    this.servingSizes,
  });
}

class MealComponent {
  final Food food;
  double quantity;
  FoodUnit unit;

  MealComponent({
    required this.food,
    required this.quantity,
    required this.unit,
  });

  double get baseQuantity => quantity * unit.multiplier;

  double get calories => food.caloriesPerUnit * baseQuantity;
  double get protein => food.proteinPerUnit * baseQuantity;
  double get carbs => food.carbsPerUnit * baseQuantity;
  double get fat => food.fatPerUnit * baseQuantity;
}
