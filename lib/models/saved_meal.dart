import 'package:hive/hive.dart';

part 'saved_meal.g.dart';

@HiveType(typeId: 4)
class SavedMeal extends HiveObject {
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
  String imagePath;

  @HiveField(7)
  int fiber;

  @HiveField(8)
  int sugar;

  @HiveField(9)
  int sodium;

  SavedMeal({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imagePath = '',
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });
}
