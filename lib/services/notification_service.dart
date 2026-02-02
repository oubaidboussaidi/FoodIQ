import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_notification.dart';
import '../models/user_settings.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'cal_ai_smart_channel', 'FoodIQ Intelligence',
      channelDescription: 'Smart nutritional and fitness guidance',
      importance: Importance.max, priority: Priority.high, showWhen: true
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(DateTime.now().millisecond, title, body, platformChannelSpecifics);
  }

  Future<void> triggerNotification(String title, String body, String type) async {
    await _showLocalNotification(title, body);
    final box = Hive.box<AppNotification>(StorageService.notificationsBoxName);
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, body: body, type: type, timestamp: DateTime.now(),
    );
    await box.add(notification);
  }

  // --- SMART INTELLIGENCE ENGINES ---

  void processSmartNotifications(UserSettings settings, int currentCals, int currentProtein, double currentWater) {
    if (settings.notifyMotivation) checkMotivation();
    if (settings.notifyWater) checkWater(currentWater);
    if (settings.notifyProtein) checkProtein(currentProtein, settings.getProteinGoal());
    if (settings.notifyCalories) checkCaloriePacing(settings, currentCals);
    if (settings.notifyWorkouts) checkTraining(settings, currentCals);
  }

  // Compatibility wrapper for older calls
  void checkCalorieStatus(int calsLeft, int goal, int proLeft, int proGoal) {
    // This is a legacy shim - we'll just try to pace based on what we know
    final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
    final settings = settingsBox.get('user', defaultValue: UserSettings())!;
    checkCaloriePacing(settings, goal - calsLeft);
    checkProtein(proGoal - proLeft, proGoal);
  }

  void checkMorningMotivation() => checkMotivation();

  void checkMotivation() {
    final now = DateTime.now();
    if (now.hour >= 7 && now.hour <= 10) { // Morning window
      _triggerOncePerDay("motivation_morning", "Rising & Grinding ☀️", "Your metabolism is ready. Fuel it with a high-protein breakfast!", "motivation");
    }
  }

  void checkWater(double currentWater) {
    final now = DateTime.now();
    if (now.hour >= 10 && now.hour <= 20) { // Active window
      if (currentWater < 1.0 && now.hour >= 14) {
        _triggerOncePerDay("water_low", "Hydration Alert 💧", "You've only had ${currentWater.toStringAsFixed(1)}L. Your brain needs more water for focus!", "water");
      }
    }
  }

  void checkProtein(int currentProtein, int goal) {
    if (goal <= 0) return;
    final now = DateTime.now();
    if (now.hour >= 15 && currentProtein < (goal * 0.4)) {
      _triggerOncePerDay("protein_sync", "Protein Sync Needed 🥩", "You're lagging on protein ($currentProtein/$goal g). Consider a high-protein snack.", "protein");
    } else if (currentProtein >= goal) {
      _triggerOncePerDay("protein_goal", "Protein Target Hit! 🏆", "Excellent work. Your muscles have the amino acids they need for repair.", "protein");
    }
  }

  void checkCaloriePacing(UserSettings settings, int currentCals) {
    final now = DateTime.now();
    final goal = settings.getCalorieGoal();
    final isCutting = (settings.goalWeight ?? settings.weight) < settings.weight;
    
    if (isCutting) {
      if (now.hour < 14 && currentCals > (goal * 0.6)) {
        _triggerOncePerDay("pacing_cut", "Pacing Warning ⚠️", "You've used 60% of your calories early. Save some room for dinner to stay on track!", "calorie");
      }
    } else if (!isCutting && goal > settings.weight * 30) { // Bulking check
      if (now.hour > 18 && currentCals < (goal * 0.5)) {
        _triggerOncePerDay("pacing_bulk", "Bulk Warning 🥘", "You still have half your calories left! It's time for a nutrient-dense feast.", "calorie");
      }
    }
  }

  void checkTraining(UserSettings settings, int currentCals) {
    final now = DateTime.now();
    final isBulking = (settings.goalWeight ?? settings.weight) > settings.weight;
    
    if (isBulking) {
      if (currentCals > settings.getCalorieGoal() * 0.7 && now.hour < 20) {
        _triggerOncePerDay("train_rec", "Energy Surplus Detected ⚡", "You've fueled up well. Perfect time for a heavy session to drive growth!", "fitness");
      }
    } else {
       if (currentCals < settings.getCalorieGoal() * 0.4 && now.hour > 17) {
         _triggerOncePerDay("rest_rec", "Low Energy Mode 🧘", "Calories are low today. Focus on active recovery or rest to manage stress.", "fitness");
       }
    }
  }

  void _triggerOncePerDay(String uniqueId, String title, String body, String type) {
    final box = Hive.box<AppNotification>(StorageService.notificationsBoxName);
    final now = DateTime.now();
    final alreadySent = box.values.any((n) => 
      n.type == type && 
      n.title == title && 
      n.timestamp.day == now.day && n.timestamp.month == now.month
    );
    if (!alreadySent) {
      triggerNotification(title, body, type);
    }
  }
}

