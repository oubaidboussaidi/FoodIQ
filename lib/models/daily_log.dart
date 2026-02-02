import 'package:hive/hive.dart';

part 'daily_log.g.dart';

@HiveType(typeId: 2)
class DailyLog extends HiveObject {
  @HiveField(0)
  final String dateKey; // Format: "yyyy-MM-dd"

  @HiveField(1)
  int waterIntake;

  @HiveField(2)
  int steps;

  DailyLog({
    required this.dateKey,
    this.waterIntake = 0,
    this.steps = 0,
  });
}
