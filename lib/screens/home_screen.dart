import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/meal.dart';
import '../models/user_settings.dart';
import '../models/daily_log.dart'; // Added this import
import '../models/app_notification.dart';
import '../services/storage_service.dart';
import '../widgets/home_components.dart';
import 'notifications_screen.dart'; // Added import
import 'meal_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  final DateTime? initialDate;
  const HomeScreen({super.key, this.initialDate});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;
  bool _isStreakExpanded = false;
  int _statsPageIndex = 0;
  int _waterServingSize = 250;

  OverlayEntry? _notificationOverlay;
  final LayerLink _notifLayerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    // Normalize date to remove time component if passed
    final date = widget.initialDate ?? DateTime.now();
    _selectedDate = DateTime(date.year, date.month, date.day);
  }

  @override
  void dispose() {
    _hideNotificationPopup();
    super.dispose();
  }

  void _toggleNotificationPopup() {
    if (_notificationOverlay != null) {
      _hideNotificationPopup();
    } else {
      _showNotificationPopup();
    }
  }

  void _showNotificationPopup() {
    _notificationOverlay = _createNotificationOverlay();
    Overlay.of(context).insert(_notificationOverlay!);
  }

  void _hideNotificationPopup() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  OverlayEntry _createNotificationOverlay() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _hideNotificationPopup,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 300,
            child: CompositedTransformFollower(
              link: _notifLayerLink,
              showWhenUnlinked: false,
              offset: const Offset(-250, 50),
              child: Material(
                elevation: 20,
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                shadowColor: Colors.black.withOpacity(0.3),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Recent Alerts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            TextButton(
                              onPressed: () {
                                final box = Hive.box<AppNotification>(StorageService.notificationsBoxName);
                                for (var n in box.values) { n.isRead = true; n.save(); }
                              },
                              child: const Text("Mark read", style: TextStyle(fontSize: 12)),
                            )
                          ],
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: Hive.box<AppNotification>(StorageService.notificationsBoxName).listenable(),
                        builder: (context, Box<AppNotification> box, _) {
                          final notes = box.values.toList()
                            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                          final recent = notes.take(3).toList();

                          if (recent.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("No notifications", style: TextStyle(color: Colors.grey)),
                            );
                          }

                          return Column(
                            children: [
                              ...recent.map((n) => ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: _getNotifColor(n.type).withOpacity(0.1), shape: BoxShape.circle),
                                  child: Icon(_getNotifIcon(n.type), size: 16, color: _getNotifColor(n.type)),
                                ),
                                title: Text(n.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text(n.body, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                isThreeLine: true,
                              )),
                              const Divider(),
                              TextButton(
                                onPressed: () {
                                  _hideNotificationPopup();
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen()));
                                },
                                child: const Text("See all notifications", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotifIcon(String type) {
    if (type == 'motivation') return Icons.wb_sunny_rounded;
    if (type == 'alert') return Icons.warning_rounded;
    return Icons.notifications;
  }

  Color _getNotifColor(String type) {
    if (type == 'motivation') return Colors.orange;
    if (type == 'alert') return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder(
          valueListenable: Hive.box<Meal>(StorageService.boxName).listenable(),
          builder: (context, Box<Meal> mealsBox, _) { // Renamed box to mealsBox
            return ValueListenableBuilder(
              valueListenable: Hive.box<DailyLog>(StorageService.dailyLogsBoxName).listenable(),
              builder: (context, Box<DailyLog> dailyLogsBox, _) {
                // Get user settings for goals
                final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
                final settings = settingsBox.get('user', defaultValue: UserSettings())!;

                // Check if selected date is "Today" for UI logic
                final now = DateTime.now();
                final isToday = _selectedDate.year == now.year && 
                                _selectedDate.month == now.month && 
                                _selectedDate.day == now.day;
                
                final displayDate = _selectedDate;
                
                // Get Daily Log for selected date
                // Get Daily Log for selected date
                final dateKey = "${displayDate.year}-${displayDate.month}-${displayDate.day}";
                DailyLog dailyLog;
                if (dailyLogsBox.containsKey(dateKey)) {
                  dailyLog = dailyLogsBox.get(dateKey)!;
                } else {
                  // If no log exists, create a temporary one for display purposes
                  // It will be saved to Hive only when an update operation occurs.
                  dailyLog = DailyLog(dateKey: dateKey);
                }
                
                final int waterAmount = dailyLog.waterIntake;

                final selectedDayMeals = mealsBox.values.where((meal) => 
                  meal.timestamp.year == displayDate.year &&
                  meal.timestamp.month == displayDate.month &&
                  meal.timestamp.day == displayDate.day
                ).toList();

                // Calculate totals
                int totalCals = selectedDayMeals.fold(0, (sum, item) => sum + item.calories);
                int totalProtein = selectedDayMeals.fold(0, (sum, item) => sum + item.protein);
                int totalCarbs = selectedDayMeals.fold(0, (sum, item) => sum + item.carbs);
                int totalFat = selectedDayMeals.fold(0, (sum, item) => sum + item.fat);
                int totalFiber = selectedDayMeals.fold(0, (sum, item) => sum + (item.fiber));
                int totalSugar = selectedDayMeals.fold(0, (sum, item) => sum + (item.sugar));
                int totalSodium = selectedDayMeals.fold(0, (sum, item) => sum + (item.sodium));
                
                final int goalCals = settings.getCalorieGoal();
                int calsLeft = goalCals - totalCals;
                double progress = (totalCals / goalCals).clamp(0.0, 1.0);

                return ListView(
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(mealsBox, settings, isToday), // Passed isToday
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CaloriesCard(
                            caloriesLeft: calsLeft, 
                            totalCalories: goalCals,
                            progress: progress,
                          ),
                          const SizedBox(height: 16),
                          _buildIntelligenceSection(totalCals, totalProtein, settings),
                          const SizedBox(height: 16),
                          _buildStatsCarousel(totalCals, totalProtein, totalCarbs, totalFat, totalFiber, totalSugar, totalSodium, settings, waterAmount, dateKey, dailyLogsBox),
                          const SizedBox(height: 16),
                          
                          const SizedBox(height: 24),
                          const Text(
                            "Recently uploaded",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (selectedDayMeals.isEmpty)
                             Padding(
                               padding: const EdgeInsets.all(16.0),
                                 child: Text(
                                   isToday ? "No meals today. Tap + to add!" : "No meals for this day.",
                                   style: const TextStyle(color: Colors.grey),
                                 ),
                             )
                          else
                            ...selectedDayMeals.reversed.map((meal) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildFoodTile(meal),
                              );
                            }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80), 
                  ],
                );
              },
            );
          },
        ),
      );
    }

  Widget _buildFoodTile(Meal meal) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MealEntryScreen(existingMeal: meal))),
      child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Container(
                width: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  image: (meal.imagePath != null && meal.imagePath!.isNotEmpty)
                      ? DecorationImage(
                          image: FileImage(File(meal.imagePath!)), 
                          fit: BoxFit.cover
                        )
                      : null,
                ),
                child: (meal.imagePath == null || meal.imagePath!.isEmpty)
                    ? const Center(child: Icon(Icons.restaurant, color: Color(0xFF9CA3AF), size: 32))
                    : null,
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              meal.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF111827)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('h:mma').format(meal.timestamp).toLowerCase(),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 16, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            "${meal.calories} calories",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF111827)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMacroItem('🍗', '${meal.protein}g'),
                          const SizedBox(width: 16),
                          _buildMacroItem('🌾', '${meal.carbs}g'),
                          const SizedBox(width: 16),
                          _buildMacroItem('🥑', '${meal.fat}g'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
   );
  }

  Widget _buildHeader(Box<Meal> box, UserSettings settings, bool isToday) {
    final streak = _calculateStreak(box, settings);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Absolute Left Branding
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/main page header icon.svg',
                    width: 65,
                    height: 65,
                  ),
                  Transform.translate(
                    offset: const Offset(-32, 0),
                    child: const Text(
                      "FoodIQ",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                ],
              ),
              // Right-Anchored Utility
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isStreakExpanded = !_isStreakExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Text('$streak', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CompositedTransformTarget(
                      link: _notifLayerLink,
                      child: ValueListenableBuilder(
                        valueListenable: Hive.box<AppNotification>(StorageService.notificationsBoxName).listenable(),
                        builder: (context, Box<AppNotification> notifBox, _) {
                          final unreadCount = notifBox.values.where((n) => !n.isRead).length;
                          return GestureDetector(
                            onTap: _toggleNotificationPopup,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: const Icon(Icons.notifications_outlined, size: 24, color: Colors.black),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: Text(
                                        unreadCount > 9 ? '9+' : '$unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isStreakExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildStreakCalendar(box, settings),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildDayTogglesSection(isToday),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTogglesSection(bool isToday) {
    if (widget.initialDate != null && !_isSameDay(_selectedDate, DateTime.now())) {
      return Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            DateFormat('MMMM d, yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDayToggle("Today", isToday, () {
            if (!isToday) setState(() => _selectedDate = DateTime.now());
          }),
          const SizedBox(width: 24),
          _buildDayToggle("Yesterday", !isToday && _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1))), () {
            setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1)));
          }),
        ],
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDayToggle(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              color: isSelected ? const Color(0xFF111827) : const Color(0xFF6B7280),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildStreakCalendar(Box<Meal> box, UserSettings settings) {
    // Show last 7 days ending with today? Or centered? usually last 7 days.
    // Let's show Today at the end (right)
    final now = DateTime.now();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        // 0..6. 6 is today.
        final date = now.subtract(Duration(days: 6 - index));
        final isToday = index == 6;
        final status = _getDayStatus(box, settings, date);
        
        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isToday 
                  ? null // Handled by progress indicator
                  : Border.all(
                      color: _getStatusColor(status),
                      width: 2,
                    ),
                color: Colors.transparent,
              ),
              child: isToday 
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                         CircularProgressIndicator(
                           value: _getDayProgress(box, settings, date),
                           color: Colors.black,
                           backgroundColor: Colors.grey[200],
                           strokeWidth: 3,
                         ),
                         Text(
                           DateFormat('E').format(date)[0],
                           style: const TextStyle(
                             fontSize: 12, 
                             fontWeight: FontWeight.w600,
                             color: Colors.black
                           )
                         )
                      ],
                    )
                  : Center(
                      child: Text(
                        DateFormat('E').format(date)[0],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              date.day.toString(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'green': return const Color(0xFF10B981);
      case 'yellow': return const Color(0xFFFBBF24);
      case 'red': return const Color(0xFFEF4444);
      default: return const Color(0xFFE5E7EB);
    }
  }

  double _getDayProgress(Box<Meal> box, UserSettings settings, DateTime date) {
    final dayMeals = box.values.where((meal) => 
      meal.timestamp.year == date.year &&
      meal.timestamp.month == date.month &&
      meal.timestamp.day == date.day
    ).toList();
    
    int totalCals = dayMeals.fold(0, (sum, item) => sum + item.calories);
    return (totalCals / settings.getCalorieGoal()).clamp(0.0, 1.0);
  }

  String _calculateStatusFromMeals(List<Meal> dayMeals, UserSettings settings) {
    if (dayMeals.isEmpty) return 'red';

    int totalCals = dayMeals.fold(0, (sum, item) => sum + item.calories);
    int totalProtein = dayMeals.fold(0, (sum, item) => sum + item.protein);
    
    final int goalCals = settings.getCalorieGoal();
    final int goalProtein = settings.getProteinGoal();
    
    final bool calsReached = totalCals >= (goalCals * 0.95);
    final bool proteinReached = totalProtein >= (goalProtein * 0.95);
    
    if (calsReached || proteinReached) return 'green';
    
    final bool calsClose = totalCals >= (goalCals * 0.80);
    final bool proteinClose = totalProtein >= (goalProtein * 0.80);
    
    if (calsClose || proteinClose) return 'yellow';
    
    return 'red';
  }

  String _getDayStatus(Box<Meal> box, UserSettings settings, DateTime date) {
    if (date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day) {
      return 'current';
    }
  
    final dayMeals = box.values.where((meal) => 
      meal.timestamp.year == date.year &&
      meal.timestamp.month == date.month &&
      meal.timestamp.day == date.day
    ).toList();
    
    return _calculateStatusFromMeals(dayMeals, settings);
  }

  int _calculateStreak(Box<Meal> box, UserSettings settings) {
    int streak = 0;
    
    // Normalize date to ignore time for grouping
    String getDateKey(DateTime d) => "${d.year}-${d.month}-${d.day}";
    
    final Map<String, List<Meal>> mealsByDate = {};
    for (var meal in box.values) {
        final key = getDateKey(meal.timestamp);
        mealsByDate.putIfAbsent(key, () => []).add(meal);
    }
    
    DateTime checkDate = DateTime.now().subtract(const Duration(days: 1));
    
    for (int i = 0; i < 365; i++) { 
        final key = getDateKey(checkDate);
        final dayMeals = mealsByDate[key] ?? [];
        
        final status = _calculateStatusFromMeals(dayMeals, settings);
        
        if (status == 'red') {
           break;
        } else if (status == 'green') {
           streak++;
        }
        
        checkDate = checkDate.subtract(const Duration(days: 1));
    }
    
    return streak;
  }

  Widget _buildMacroItem(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
        ),
      ],
    );
  }

  Widget _buildStatsCarousel(int totalCals, int protein, int carbs, int fat, int fiber, int sugar, int sodium, UserSettings settings, int waterAmount, String dateKey, Box<DailyLog> dailyLogsBox) {
    final pGoal = settings.getProteinGoal();
    final cGoal = settings.getCarbsGoal();
    final fGoal = settings.getFatGoal();
    
    return Column(
      children: [
        SizedBox(
          height: 360, 
          child: PageView(
            onPageChanged: (index) => setState(() => _statsPageIndex = index),
            children: [
               // Page 1: Macros
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 4.0),
                 child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMacroRingCard(
                              title: "Protein",
                              goal: pGoal,
                              current: protein,
                              color: const Color(0xFFEF4444),
                              assetPath: "assets/icons/protein.svg",
                              height: 180,
                              radius: 36,
                              iconSize: 28,
                              valueFontSize: 26,
                              labelFontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMacroRingCard(
                              title: "Carbs",
                              goal: cGoal,
                              current: carbs,
                              color: const Color(0xFFFBBF24),
                              assetPath: "assets/icons/carbs.svg",
                              height: 180,
                              radius: 36,
                              iconSize: 28,
                              valueFontSize: 26,
                              labelFontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMacroRingCard(
                              title: "Fat",
                              goal: fGoal,
                              current: fat,
                              color: const Color(0xFF3B82F6),
                              assetPath: "assets/icons/fat.svg",
                              height: 180,
                              radius: 36,
                              iconSize: 28,
                              valueFontSize: 26,
                              labelFontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWaterTracker(waterAmount, dateKey, dailyLogsBox),
                    ],
                 ),
               ),
               // Page 2: Micros + Health Score
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 4.0),
                 child: Column(
                   children: [
                     Row(
                       children: [
                          Expanded(child: _buildMacroRingCard(title: 'Fiber', goal: 38, current: fiber, color: Colors.purple, assetPath: 'assets/icons/fiber.svg')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMacroRingCard(title: 'Sugar', goal: 50, current: sugar, color: Colors.pink, assetPath: 'assets/icons/sugar.svg')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMacroRingCard(title: 'Sodium', goal: 2300, current: sodium, color: Colors.amber, assetPath: 'assets/icons/sodium.svg')),
                       ],
                     ),
                     const SizedBox(height: 16),
                      _buildMetabolicFuelGradeCard(totalCals, protein, carbs, fat, fiber, sugar, sodium, settings),
                   ],
                 ),
               ),
               // Page 3: Activity + Water
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 4.0),
                 child: Column(
                   children: [
                     Row(
                       children: [
                         // Steps
                         Expanded(
                           child: Container(
                             height: 140,
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                       RichText(text: const TextSpan(children: [TextSpan(text: '0', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)), TextSpan(text: '/10000', style: TextStyle(color: Colors.grey, fontSize: 11))])),
                                       const SizedBox(height: 2),
                                       const Text('Steps Today', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                                    ]
                                  ),
                                  // Mock Google Health
                                  Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                     decoration: BoxDecoration(
                                       color: const Color(0xFFEFF6FF), 
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                     child: const Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                          Icon(Icons.favorite, color: Color(0xFF4285F4), size: 16),
                                          SizedBox(width: 6),
                                          Flexible(child: Text("Connect Google Health", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF374151)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                       ],
                                     ),
                                  )
                               ],
                             ),
                           ),
                         ),
                         const SizedBox(width: 8),
                         // Calories Burned
                         Expanded(
                           child: Container(
                             height: 140,
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                             child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.local_fire_department, size: 22, color: Colors.black),
                                  const SizedBox(height: 6),
                                  const Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                                  const Text('Calories burned', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
                                    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.directions_walk, size: 12), SizedBox(width: 3), Text("Steps +0", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold))]),
                                  )
                                ],
                             ),
                           ),
                         ),
                       ],

                     ),
                      const SizedBox(height: 16),
                      _buildWaterTracker(waterAmount, dateKey, dailyLogsBox),
                    ],
                 ),
               ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
             return AnimatedContainer(
               duration: const Duration(milliseconds: 300),
               margin: const EdgeInsets.symmetric(horizontal: 4),
               width: 8, height: 8,
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: _statsPageIndex == index ? Colors.black : Colors.grey[300],
               ),
             );
          }),
        ),
      ],
    );
  }

  Widget _buildMacroRingCard({
    required String title,
    required int goal,
    required int current,
    required Color color,
    required String assetPath,
    double height = 140,
    double radius = 28,
    double strokeWidth = 4,
    double iconSize = 20,
    double valueFontSize = 22,
    double labelFontSize = 12,
  }) {
    final diff = goal - current;
    final percent = (current / goal).clamp(0.0, 1.0);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                "${diff.abs()}g",
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$title left",
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          CircularPercentIndicator(
            radius: radius,
            lineWidth: strokeWidth,
            percent: percent,
            backgroundColor: const Color(0xFFE5E7EB),
            progressColor: color,
            circularStrokeCap: CircularStrokeCap.round,
            center: SvgPicture.asset(
              assetPath,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildMetabolicFuelGradeCard(int cals, int p, int c, int f, int fiber, int sugar, int sodium, UserSettings settings) {
    // 1. Logic for Grading
    final calGoal = settings.getCalorieGoal();
    final pGoal = settings.getProteinGoal();
    
    // Performance Index Calculation (0.0 to 1.0)
    double calPerformance = 1.0 - ((cals - calGoal).abs() / calGoal).clamp(0.0, 1.0);
    double proteinPerformance = (p / pGoal).clamp(0.0, 1.0);
    double cleanIndex = (1.0 - (sugar / 100).clamp(0.0, 1.0)) * 0.7 + (1.0 - (sodium / 4000).clamp(0.0, 1.0)) * 0.3;
    
    double totalPerformance = (calPerformance * 0.4 + proteinPerformance * 0.4 + cleanIndex * 0.2);
    
    String grade = "F";
    Color gradeColor = const Color(0xFFEF4444);
    String status = "Critical Imbalance";
    
    if (totalPerformance >= 0.9) {
      grade = "A";
      gradeColor = const Color(0xFF10B981);
      status = "Peak Metabolic State";
    } else if (totalPerformance >= 0.8) {
      grade = "B";
      gradeColor = const Color(0xFF3B82F6);
      status = "High Performance";
    } else if (totalPerformance >= 0.65) {
      grade = "C";
      gradeColor = const Color(0xFFFBBF24);
      status = "Standard Maintenance";
    } else if (totalPerformance >= 0.5) {
      grade = "D";
      gradeColor = Colors.orange;
      status = "Sub-Optimal Fueling";
    } else {
      grade = "F";
      gradeColor = const Color(0xFFEF4444);
      status = "Metabolic Reset Needed";
    }

    if (cals == 0) {
       grade = "-";
       gradeColor = Colors.grey;
       status = "Awaiting Data Sync...";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    "METABOLIC FUEL GRADE",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gradeColor.withOpacity(0.05),
                  border: Border.all(color: gradeColor.withOpacity(0.2), width: 2),
                ),
                child: Center(
                  child: Text(
                    grade,
                    style: TextStyle(
                      color: gradeColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Sub-metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFuelMetric("Stability", calPerformance, gradeColor),
              _buildFuelMetric("Synthesis", proteinPerformance, gradeColor),
              _buildFuelMetric("Cleanliness", cleanIndex, gradeColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuelMetric(String label, double percent, Color activeColor) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(activeColor.withOpacity(0.7)),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterTracker(int waterAmount, String dateKey, Box<DailyLog> dailyLogsBox) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                child: Center(
                 child: SvgPicture.asset(
                   'assets/icons/water.svg',
                   width: 20,
                   height: 20,
                   colorFilter: const ColorFilter.mode(Color(0xFF3B82F6), BlendMode.srcIn),
                 ),
               ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Water", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                  Text("$waterAmount ml", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          Row(
            children: [
               GestureDetector(
                 onTap: _showWaterSettings,
                 child: const Icon(Icons.settings, color: Color(0xFF9CA3AF), size: 18),
               ),
               const SizedBox(width: 12),
              _buildCircleBtn(Icons.remove, onTap: () async {
                 var currentLog = dailyLogsBox.get(dateKey);
                 if (currentLog == null) {
                   currentLog = DailyLog(dateKey: dateKey);
                   await dailyLogsBox.put(dateKey, currentLog);
                 }
                 
                 if (currentLog.waterIntake >= _waterServingSize) {
                   currentLog.waterIntake -= _waterServingSize;
                 } else {
                   currentLog.waterIntake = 0;
                 }
                 currentLog.save();
              }),
              const SizedBox(width: 8),
              _buildCircleBtn(Icons.add, filled: true, onTap: () async {
                 var currentLog = dailyLogsBox.get(dateKey);
                 if (currentLog == null) {
                   currentLog = DailyLog(dateKey: dateKey);
                   await dailyLogsBox.put(dateKey, currentLog);
                 }
                 
                 currentLog.waterIntake += _waterServingSize;
                 currentLog.save();
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, {bool filled = false, VoidCallback? onTap}) {
     return GestureDetector(
       onTap: onTap,
       child: Container(
         width: 36, height: 36,
         decoration: BoxDecoration(
            color: filled ? Colors.black : Colors.white,
            shape: BoxShape.circle,
            border: filled ? null : Border.all(color: const Color(0xFFE5E7EB)),
         ),
         child: Icon(icon, color: filled ? Colors.white : Colors.black, size: 20),
       ),
     );
  }

  void _showWaterSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Serving Size", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                const SizedBox(height: 8),
                const Text("Choose how much water to add with each tap.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [100, 250, 500, 750].map((size) {
                    final isSelected = _waterServingSize == size;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => _waterServingSize = size);
                        setState(() => _waterServingSize = size); // Update main UI instantly
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent),
                          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        ),
                        child: Text(
                          "${size}ml",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
      ),
    );
  }
  Widget _buildIntelligenceSection(int totalCals, int totalProtein, UserSettings settings) {
    String insight = "Analyzing your nutritional patterns...";
    Color insightColor = const Color(0xFF3B82F6);
    IconData insightIcon = Icons.auto_awesome;

    final int goalCals = settings.getCalorieGoal();
    final double calPerc = totalCals / goalCals;

    if (totalCals == 0) {
      insight = "Waiting for your first meal to generate smart insights.";
    } else if (calPerc < 0.3) {
      insight = "Slow start today. Aim for a high-protein snack to boost your metabolism.";
    } else if (calPerc > 0.9 && totalProtein < settings.getProteinGoal() * 0.7) {
      insight = "Calorie goal nearly reached, but protein is lagging. Focus on lean sources.";
      insightColor = Colors.orange;
      insightIcon = Icons.warning_amber_rounded;
    } else if (totalProtein >= settings.getProteinGoal() * 0.9) {
      insight = "Excellent protein intake! Your muscle synthesis is currently optimized.";
      insightColor = const Color(0xFF10B981);
      insightIcon = Icons.check_circle_outline;
    } else {
      insight = "Hydration and balanced macros detected. You're on the right track for FoodIQ.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "FoodIQ Intelligence",
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const _PulseDot(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(insightIcon, color: insightColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: calPerc.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(insightColor.withOpacity(0.4)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF10B981).withOpacity(1.0 - _controller.value),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.5 * (1.0 - _controller.value)),
                blurRadius: 10 * _controller.value,
                spreadRadius: 5 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
