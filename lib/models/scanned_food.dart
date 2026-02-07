class ScannedFood {
  final String name;
  final double detectionConfidence;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double defaultPortionG;
  final bool nutritionEstimated;
  final double fiberPer100g;
  final double sugarPer100g;
  final double sodiumPer100g;
  final int? fdcId;
  final String? calculationSource;

  ScannedFood({
    required this.name,
    required this.detectionConfidence,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g = 0.0,
    this.sugarPer100g = 0.0,
    this.sodiumPer100g = 0.0,
    required this.defaultPortionG,
    required this.nutritionEstimated,
    this.fdcId,
    this.calculationSource,
  });

  factory ScannedFood.fromJson(Map<String, dynamic> json) {
    return ScannedFood(
      name: json['name'],
      detectionConfidence: (json['detection_confidence'] as num).toDouble(),
      caloriesPer100g: (json['calories_per_100g'] as num).toDouble(),
      proteinPer100g: (json['protein_per_100g'] as num).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num).toDouble(),
      fatPer100g: (json['fat_per_100g'] as num).toDouble(),
      fiberPer100g: (json['fiber_per_100g'] as num ?? 0.0).toDouble(),
      sugarPer100g: (json['sugar_per_100g'] as num ?? 0.0).toDouble(),
      sodiumPer100g: (json['sodium_per_100g'] as num ?? 0.0).toDouble(),
      defaultPortionG: (json['default_portion_g'] as num).toDouble(),
      nutritionEstimated: json['nutrition_estimated'] ?? false,
      fdcId: json['fdc_id'],
      calculationSource: json['calculation_source'],
    );
  }
}
