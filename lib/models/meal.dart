import 'package:hive/hive.dart';

part 'meal.g.dart';

@HiveType(typeId: 0)
class Meal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int calories;

  @HiveField(3)
  int protein;

  @HiveField(4)
  int carbs;

  @HiveField(5)
  int fat;

  @HiveField(6)
  final String? imagePath;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  int fiber;

  @HiveField(9)
  int sugar;

  @HiveField(10)
  int sodium;

  Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imagePath, // Optional named parameter
    required this.timestamp,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });
}
