import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal.dart';
import '../models/user_settings.dart';
import '../models/daily_log.dart';

import '../models/app_notification.dart';
import '../models/saved_meal.dart';

class StorageService {
  static const String boxName = 'meals_box';
  static const String settingsBoxName = 'settings_box';
  static const String dailyLogsBoxName = 'daily_logs_box';
  static const String notificationsBoxName = 'notifications_box';
  static const String savedMealsBoxName = 'saved_meals_box';

  Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MealAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyLogAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AppNotificationAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SavedMealAdapter());
    }

    // Try to open boxes with error handling for schema changes
    try {
      await Hive.openBox<Meal>(boxName);
    } catch (e) {
      print("⚠️ Meal box schema error, clearing old data: $e");
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<Meal>(boxName);
    }

    try {
      await Hive.openBox<UserSettings>(settingsBoxName);
    } catch (e) {
      print("⚠️ Settings box schema error, clearing old data: $e");
      if (Hive.isBoxOpen(settingsBoxName)) {
        await Hive.box(settingsBoxName).close();
      }
      await Hive.deleteBoxFromDisk(settingsBoxName);
      await Hive.openBox<UserSettings>(settingsBoxName);
    }

    try {
      await Hive.openBox<DailyLog>(dailyLogsBoxName);
    } catch (e) {
      print("⚠️ DailyLog box schema error, clearing old data: $e");
      if (Hive.isBoxOpen(dailyLogsBoxName)) {
        await Hive.box(dailyLogsBoxName).close();
      }
      await Hive.deleteBoxFromDisk(dailyLogsBoxName);
      await Hive.openBox<DailyLog>(dailyLogsBoxName);
    }

    try {
      await Hive.openBox<AppNotification>(notificationsBoxName);
    } catch (e) {
      print("⚠️ Notification box schema error, clearing old data: $e");
      if (Hive.isBoxOpen(notificationsBoxName)) {
        await Hive.box(notificationsBoxName).close();
      }
      await Hive.deleteBoxFromDisk(notificationsBoxName);
      await Hive.openBox<AppNotification>(notificationsBoxName);
    }

    try {
      await Hive.openBox<SavedMeal>(savedMealsBoxName);
    } catch (e) {
      print("⚠️ SavedMeal box schema error, clearing old data: $e");
      if (Hive.isBoxOpen(savedMealsBoxName)) {
        await Hive.box(savedMealsBoxName).close();
      }
      await Hive.deleteBoxFromDisk(savedMealsBoxName);
      await Hive.openBox<SavedMeal>(savedMealsBoxName);
    }
  }

  Box<Meal> get _box => Hive.box<Meal>(boxName);
  Box<DailyLog> get _dailyLogsBox => Hive.box<DailyLog>(dailyLogsBoxName);
  Box<AppNotification> get _notificationsBox => Hive.box<AppNotification>(notificationsBoxName);
  Box<SavedMeal> get savedMealsBox => Hive.box<SavedMeal>(savedMealsBoxName);

  Future<void> addMeal(Meal meal) async {
    await _box.put(meal.id, meal);
  }

  List<Meal> getMeals() {
    final meals = _box.values.toList();
    meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return meals;
  }
  
  List<Meal> getMealsForDate(DateTime date) {
    return _box.values.where((meal) {
      return meal.timestamp.year == date.year &&
             meal.timestamp.month == date.month &&
             meal.timestamp.day == date.day;
    }).toList();
  }

  Future<void> updateMeal(Meal meal) async {
    // Since Meal is a HiveObject, save() updates it in the box
    await meal.save();
  }

  Future<void> deleteMeal(Meal meal) async {
    await meal.delete();
  }

  DailyLog getDailyLog(DateTime date) {
    final key = "${date.year}-${date.month}-${date.day}";
    if (_dailyLogsBox.containsKey(key)) {
      return _dailyLogsBox.get(key)!;
    } else {
      final newLog = DailyLog(dateKey: key);
      _dailyLogsBox.put(key, newLog);
      return newLog;
    }
  }

  Future<void> saveDailyLog(DailyLog log) async {
    await log.save();
  }
}
