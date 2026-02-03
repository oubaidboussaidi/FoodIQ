import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 1)
class UserSettings extends HiveObject {
  @HiveField(0)
  int age;

  @HiveField(1)
  double weight;

  @HiveField(2)
  double bodyFat;

  @HiveField(3)
  String gender; // 'Male' or 'Female'

  @HiveField(4)
  String goal; // 'Cut', 'Bulk', 'Maintain', 'Heavy Bulk', 'Slight Cut'

  @HiveField(5)
  bool autoGenerateGoal;

  @HiveField(6)
  int manualCalorieGoal;

  @HiveField(7)
  int manualProteinGoal;

  @HiveField(8)
  int manualCarbsGoal;

  @HiveField(9)
  int manualFatGoal;

  @HiveField(10)
  int height; // in cm

  @HiveField(11)
  double? goalWeight;

  @HiveField(12)
  List<String>? weightHistory; // Stored as "ISO8601String|Weight"

  @HiveField(13)
  double goalIntensity; // 0.0 to 1.0 (Percentage of intensity)

  @HiveField(14)
  int stepGoal;

  @HiveField(15)
  bool notifyWater;

  @HiveField(16)
  bool notifyProtein;

  @HiveField(17)
  bool notifyCalories;

  @HiveField(18)
  bool notifyWorkouts;

  @HiveField(19)
  bool notifyMotivation;

  UserSettings({
    this.age = 25,
    this.weight = 70.0,
    this.bodyFat = 15.0,
    this.gender = 'Male',
    this.goal = 'Maintain',
    this.autoGenerateGoal = true,
    this.manualCalorieGoal = 2000,
    this.manualProteinGoal = 150,
    this.manualCarbsGoal = 200,
    this.manualFatGoal = 65,
    this.height = 175,
    this.goalWeight,
    this.weightHistory,
    this.goalIntensity = 0.5,
    this.stepGoal = 10000,
    this.notifyWater = true,
    this.notifyProtein = true,
    this.notifyCalories = true,
    this.notifyWorkouts = true,
    this.notifyMotivation = true,
  });

  void updateWeight(double newWeight) {
    weight = newWeight;
    weightHistory ??= [];
    weightHistory!.add('${DateTime.now().toIso8601String()}|$newWeight');
    save(); // Save self since it extends HiveObject
  }

  // Delete a weight history entry by index
  void deleteWeightEntry(int index) {
    if (weightHistory == null || index < 0 || index >= weightHistory!.length) {
      return;
    }
    
    final isLastEntry = index == weightHistory!.length - 1;
    weightHistory!.removeAt(index);
    
    // If we deleted the most recent weight entry, update current weight to the new last entry
    if (isLastEntry && weightHistory!.isNotEmpty) {
      final newLastEntry = weightHistory!.last;
      weight = double.tryParse(newLastEntry.split('|')[1]) ?? weight;
    }
    
    save();
  }

  // Calculate TDEE (Total Daily Energy Expenditure) using Mifflin-St Jeor
  int calculateTDEE() {
    double bmr;
    if (gender == 'Male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
    
    // Activity multiplier (assuming moderate activity)
    double tdee = bmr * 1.55;
    
    // Intensity multiplier based on goal percentage
    double adjustment = 0;
    
    // Determine direction
    final double gWeight = goalWeight ?? weight;
    if (gWeight > weight) {
      // Bulking: Range 150 to 500 calories
      adjustment = 150 + (goalIntensity * 350);
    } else if (gWeight < weight) {
      // Cutting: Range -200 to -800 calories
      adjustment = -200 - (goalIntensity * 600);
    } else {
      adjustment = 0; // Maintain
    }
    
    return (tdee + adjustment).toInt();
  }

  int getCalorieGoal() {
    return autoGenerateGoal ? calculateTDEE() : manualCalorieGoal;
  }

  int getProteinGoal() {
    if (!autoGenerateGoal) return manualProteinGoal;
    // 2g per kg body weight
    return (weight * 2).toInt();
  }

  int getCarbsGoal() {
    if (!autoGenerateGoal) return manualCarbsGoal;
    int calories = getCalorieGoal();
    int proteinCals = getProteinGoal() * 4;
    int fatCals = getFatGoal() * 9;
    int carbsCals = calories - proteinCals - fatCals;
    return (carbsCals / 4).toInt();
  }

  int getFatGoal() {
    if (!autoGenerateGoal) return manualFatGoal;
    // 0.8-1g per kg body weight
    return (weight * 0.9).toInt();
  }
}
