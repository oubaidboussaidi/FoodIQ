import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/meal.dart';
import '../models/daily_log.dart';
import '../models/user_settings.dart';
import 'home_screen.dart'; // Added import for HomeScreen navigation
import '../services/storage_service.dart';
import 'package:intl/intl.dart';
import '../widgets/home_components.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  int _goalPeriodIndex = 0; // 0: 90 Days, 1: 6 Months, 2: 1 Year, 3: All time
  int _nutritionPeriodIndex = 0; // 0: 1 Week, 1: 2 Week, 2: 3 Week, 3: 1 Month
  bool _hasShownCongrats = false; // Track if we've shown the congratulations popup
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    // Check goal achievement after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGoalAchievement();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _checkGoalAchievement() {
    if (_hasShownCongrats) {
      print('🎯 Congrats already shown this session');
      return;
    }
    
    final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
    final settings = settingsBox.get('user', defaultValue: UserSettings())!;
    
    double currentWeight = settings.weight;
    if (settings.weightHistory != null && settings.weightHistory!.isNotEmpty) {
      final latestEntry = settings.weightHistory!.last;
      currentWeight = double.tryParse(latestEntry.split('|')[1]) ?? currentWeight;
    }
    
    double goalWeight = settings.goalWeight ?? settings.weight;
    double startWeight = settings.weight;
    if (settings.weightHistory != null && settings.weightHistory!.isNotEmpty) {
      final firstEntry = settings.weightHistory!.first;
      startWeight = double.tryParse(firstEntry.split('|')[1]) ?? settings.weight;
    }
    
    // Debug logging
    print('🎯 Goal Achievement Check:');
    print('   Start Weight: ${startWeight.toStringAsFixed(2)} kg');
    print('   Current Weight: ${currentWeight.toStringAsFixed(2)} kg');
    print('   Goal Weight: ${goalWeight.toStringAsFixed(2)} kg');
    
    // Calculate progress
    double weightProgress = 0.0;
    if ((startWeight - goalWeight).abs() > 0.1) {
      if (startWeight > goalWeight) {
        // Losing weight
        weightProgress = (startWeight - currentWeight) / (startWeight - goalWeight);
      } else {
        // Gaining weight
        weightProgress = (currentWeight - startWeight) / (goalWeight - startWeight);
      }
    } else {
      // Start and goal are the same
      weightProgress = 1.0;
    }
    weightProgress = weightProgress.clamp(0.0, 1.0);
    
    print('   Progress: ${(weightProgress * 100).toStringAsFixed(1)}%');
    print('   Distance to goal: ${(currentWeight - goalWeight).abs().toStringAsFixed(2)} kg');
    
    // Show congratulations if goal is achieved
    // More lenient condition: 98% progress OR within 1kg of goal
    bool goalAchieved = weightProgress >= 0.98 || (currentWeight - goalWeight).abs() <= 1.0;
    
    print('   Goal Achieved: $goalAchieved');
    
    if (goalAchieved && goalWeight != startWeight) {
      print('   ✅ SHOWING CONGRATULATIONS POPUP!');
      setState(() {
        _hasShownCongrats = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showCongratulationsDialog();
        }
      });
    } else {
      print('   ❌ Goal not yet achieved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ValueListenableBuilder(
            valueListenable: Hive.box<DailyLog>(StorageService.dailyLogsBoxName).listenable(),
            builder: (context, Box<DailyLog> dailyLogsBox, _) {
              return ValueListenableBuilder(
                valueListenable: Hive.box<Meal>(StorageService.boxName).listenable(),
                builder: (context, Box<Meal> mealsBox, _) {
                  return ListView(
                    children: [
                      const SizedBox(height: 16),
                      // Top Cards: Weight & Streak
                      _buildWeightAndStreakSection(dailyLogsBox, mealsBox),
                      const SizedBox(height: 24),
                      // Goal Progress Section
                      _buildGoalProgressSection(),
                      const SizedBox(height: 24),
                      // Nutritions Section
                      _buildNutritionsSection(),
                      const SizedBox(height: 80), // Space for bottom nav
                    ],
                  );
                }
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildWeightAndStreakSection(Box<DailyLog> dailyLogsBox, Box<Meal> mealsBox) {
    final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
    final settings = settingsBox.get('user', defaultValue: UserSettings())!;

    // --- Alignment of Streak Logic with HomeScreen ---
    // Using simple calculation logic for summary view
    int streak = _calculateStreak(mealsBox, settings);

    // --- Last 7 Days Status ---
    List<Map<String, dynamic>> last7DaysData = [];
    DateTime weekDay = DateTime.now();
    for (int i = 0; i < 7; i++) {
        final date = weekDay;
        // Check Meal Status
        final dayMeals = mealsBox.values.where((m) => 
            m.timestamp.year == date.year &&
            m.timestamp.month == date.month &&
            m.timestamp.day == date.day
        ).toList();
        
        String status = 'grey';
        // Replicating _calculateStatusFromMeals logic roughly or importing it
        // Simpler: if any meals, assume active for this view, or check goals
        if (dayMeals.isNotEmpty) {
           int totalCals = dayMeals.fold(0, (sum, item) => sum + item.calories);
           int goalCals = settings.getCalorieGoal();
           if (totalCals >= goalCals * 0.95) {
             status = 'green';
           } else if (totalCals >= goalCals * 0.80) status = 'orange'; // Close
           else status = 'red'; // Missed
        } else {
           status = 'grey'; // No data
        }
        
        last7DaysData.add({'date': date, 'status': status});
        weekDay = weekDay.subtract(const Duration(days: 1));
    }
    
    // --- Weight Data ---
    double goalWeight = settings.goalWeight ?? settings.weight;
    double currentWeight = settings.weight;
    
    // Get latest weight from history if available
    if (settings.weightHistory != null && settings.weightHistory!.isNotEmpty) {
       final latestEntry = settings.weightHistory!.last;
       currentWeight = double.tryParse(latestEntry.split('|')[1]) ?? currentWeight;
    }

    // Calculate progress for bar
    double startWeight = settings.weight; 
    if (settings.weightHistory != null && settings.weightHistory!.isNotEmpty) {
        // Correct Baseline: Use the literal FIRST weight entry in history as the 0% mark
        final firstEntry = settings.weightHistory!.first;
        startWeight = double.tryParse(firstEntry.split('|')[1]) ?? settings.weight;
    }
    
    double weightProgress = 0.0;
    if ((startWeight - goalWeight).abs() > 0.1) {
         if (startWeight > goalWeight) {
             // Losing
             weightProgress = (startWeight - currentWeight) / (startWeight - goalWeight);
         } else {
             // Gaining
             weightProgress = (currentWeight - startWeight) / (goalWeight - startWeight);
         }
    }
    weightProgress = weightProgress.clamp(0.0, 1.0);


    return Row(
      children: [
        // Weight Card (Interactive)
        Expanded(
          child: GestureDetector(
            onTap: () => _showUpdateWeightDialog(context, settingsBox, settings),
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("My Weight", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text("${currentWeight.toStringAsFixed(1)} kg", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  
                  // Progress Bar
                  Column(
                    children: [
                       ClipRRect(
                         borderRadius: BorderRadius.circular(10),
                         child: LinearProgressIndicator(
                           value: weightProgress,
                           minHeight: 8,
                           backgroundColor: Colors.grey[200],
                           color: const Color(0xFF3B82F6), // Blue
                         ),
                       ),
                       const SizedBox(height: 8),
                       Text("Goal ${goalWeight.toStringAsFixed(1)} kg", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: const Text("Tap to update", style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Streak Card
        Expanded(
          child: Container(
             height: 180,
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
             child: Column(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   children: [
                     const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
                     const SizedBox(height: 4),
                     Text("$streak", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                   ],
                 ),
                 const Text("Day streak", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
                 
                   Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: List.generate(7, (index) {
                      // index 0 is today (rightmost in list? No, usually S M T W...)
                      // Let's map 6-index to get chronological order (6 days ago -> Today)
                      // wait, the loop above filled last7DaysStatus from 0=Today to 6=6daysAgo.
                      // So index 0 in UI (Leftmost) should be 6daysAgo (index 6 in List).
                      
                      final data = last7DaysData[6 - index];
                      final date = data['date'] as DateTime;
                      final status = data['status'] as String;
                      String dayLetter = DateFormat('E').format(date)[0];
                      
                      Color color;
                      if (status == 'green') {
                        color = const Color(0xFF10B981);
                      } else if (status == 'orange') color = Colors.orange;
                      else if (status == 'red') color = Colors.red;
                      else color = Colors.grey[300]!;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                backgroundColor: const Color(0xFFF3F4F6), 
                                body: HomeScreen(initialDate: date),
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Text(dayLetter, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      );
                   }),
                 )
               ],
             ),
          ),
        ),
      ],
    );
  }

  // Duplicate of logic in HomeScreen for consistency
  int _calculateStreak(Box<Meal> box, UserSettings settings) {
    int streak = 0;
    String getDateKey(DateTime d) => "${d.year}-${d.month}-${d.day}";
    
    final Map<String, List<Meal>> mealsByDate = {};
    for (var meal in box.values) {
        final key = getDateKey(meal.timestamp);
        mealsByDate.putIfAbsent(key, () => []).add(meal);
    }
    
    // Check from yesterday backwards
    DateTime checkDate = DateTime.now().subtract(const Duration(days: 1));
    for (int i = 0; i < 365; i++) { 
        final key = getDateKey(checkDate);
        final dayMeals = mealsByDate[key] ?? [];
        
        int totalCals = dayMeals.fold(0, (sum, item) => sum + item.calories);
        int totalProtein = dayMeals.fold(0, (sum, item) => sum + item.protein);
        final int goalCals = settings.getCalorieGoal();
        final int goalProtein = settings.getProteinGoal();
        
        // Status logic
        bool achieved = false;
        if (totalCals >= (goalCals * 0.95)) achieved = true;
        if (totalProtein >= (goalProtein * 0.95)) achieved = true;
        
        if (achieved) {
            streak++;
        } else {
            // If it's a "red" day (missed), streak breaks.
            // But we need to distinguish between "missed" and "just started".
            // For now, simple break.
            break;
        }
        checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _showUpdateWeightDialog(BuildContext context, Box<UserSettings> box, UserSettings settings) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Weight"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               const Text("Enter your current weight:"),
               TextField(
                 controller: controller,
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 decoration: const InputDecoration(hintText: "e.g. 70.5", suffixText: "kg"),
                 autofocus: true,
               ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                 final newWeight = double.tryParse(controller.text);
                 if (newWeight != null) {
                    // Show Confirmation
                    Navigator.pop(context);
                    _showConfirmWeightDialog(context, box, settings, newWeight);
                 }
              },
              child: const Text("Next"),
            )
          ],
        );
      }
    );
  }

  void _showConfirmWeightDialog(BuildContext context, Box<UserSettings> box, UserSettings settings, double newWeight) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text("Confirm Weight"),
         content: Text("Are you sure you want to log $newWeight kg for today?"),
         actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                 // Update Settings
                 settings.updateWeight(newWeight);
                 // Save creates history entry automatically in UserSettings model
                 
                 Navigator.pop(context);
                 setState(() {}); // Refresh UI
              },
              child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
         ],
       ),
     );
  }

  Widget _buildGoalProgressSection() {
    // Get user settings
    final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
    final settings = settingsBox.get('user', defaultValue: UserSettings())!;
    
    // Calculate progress based on the gap between Start and Goal
    double weightProgress = 0;
    
    double startWeight = settings.weight; 
    final history = settings.weightHistory ?? [];
    if (history.isNotEmpty) {
       final firstEntry = history.first.split('|');
       startWeight = double.tryParse(firstEntry.last) ?? settings.weight;
    }
    
    final currentWeight = settings.weight;
    // For currentWeight, also try to get the very latest entry string to be reactive
    final displayWeight = (history.isNotEmpty) ? (double.tryParse(history.last.split('|').last) ?? currentWeight) : currentWeight;
    final double goalWeight = settings.goalWeight ?? displayWeight;
    
    if ((startWeight - goalWeight).abs() > 0.01) {
      if (startWeight > goalWeight) {
        // Goal: Lose Weight (e.g. 100 -> 80)
        // Progress = (Start - Current) / (Start - Goal)
        weightProgress = (startWeight - displayWeight) / (startWeight - goalWeight);
      } else {
        // Goal: Gain Weight (e.g. 60 -> 80)
        // Progress = (Current - Start) / (Goal - Start)
        weightProgress = (displayWeight - startWeight) / (goalWeight - startWeight);
      }
    } else {
       // Start == Goal, so we are at 100% if we are there
       weightProgress = 1.0;
    }
    
    // Clamp between 0 and 1 (0% to 100%)
    weightProgress = weightProgress.clamp(0.0, 1.0);
    final progressPerc = (weightProgress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Goal Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            Row(
              children: [
                // Manage History Button
                GestureDetector(
                  onTap: () => _showWeightHistoryDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.history, size: 16, color: Color(0xFF6B7280)),
                        SizedBox(width: 4),
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$progressPerc% ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const TextSpan(
                        text: 'Goal achieved',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Time period tabs
        _buildPeriodTabs(
          selectedIndex: _goalPeriodIndex,
          options: ['30 Days', '90 Days', '6 Months', '1 Year', 'All time'],
          onTap: (index) => setState(() => _goalPeriodIndex = index),
        ),
        const SizedBox(height: 16),
        // Weight chart
        _buildWeightChart(settings),
      ],
    );
  }

  Widget _buildNutritionsSection() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Meal>(StorageService.boxName).listenable(),
      builder: (context, Box<Meal> box, _) {
        // Calculate weekly data
        final weekData = _getWeeklyNutritionData(box, _nutritionPeriodIndex);
        
        // Calculate comparison with previous period
        final currentPeriodCals = _calculateTotalCalories(box, _nutritionPeriodIndex);
        final previousPeriodCals = _calculateTotalCalories(box, _nutritionPeriodIndex, offset: 1);
        
        int percentChange = 0;
        bool isIncrease = true;
        
        if (previousPeriodCals > 0) {
           final diff = currentPeriodCals - previousPeriodCals;
           isIncrease = diff >= 0;
           percentChange = ((diff.abs() / previousPeriodCals) * 100).toInt();
        } else if (currentPeriodCals > 0) {
           percentChange = 100; // 100% increase if prev was 0
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nutritions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$percentChange% ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isIncrease ? const Color(0xFF10B981) : Colors.red,
                        ),
                      ),
                      TextSpan(
                        text: isIncrease ? '↑ ' : '↓ ',
                        style: TextStyle(
                          fontSize: 16,
                          color: isIncrease ? const Color(0xFF10B981) : Colors.red,
                        ),
                      ),
                      const TextSpan(
                        text: 'vs last period',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Time period tabs
            _buildPeriodTabs(
              selectedIndex: _nutritionPeriodIndex,
              options: ['1 Week', '2 Week', '3 Week', '1 Month'],
              onTap: (index) => setState(() => _nutritionPeriodIndex = index),
            ),
            const SizedBox(height: 16),
            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(currentPeriodCals.toString(), 'Total calories'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard((currentPeriodCals / 7).toInt().toString(), 'Daily avg.'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Nutrition chart
            _buildNutritionChart(weekData),
          ],
        );
      },
    );
  }

  Widget _buildPeriodTabs({
    required int selectedIndex,
    required List<String> options,
    required Function(int) onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF3F4F6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  options[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF111827) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(UserSettings settings) {
    List<FlSpot> spots = [];
    final history = settings.weightHistory ?? [];
    
    // Period mapping: 0=30, 1=90, 2=180, 3=365, 4=3650
    int daysLookback = 30; 
    if (_goalPeriodIndex == 1) daysLookback = 90;
    if (_goalPeriodIndex == 2) daysLookback = 180;
    if (_goalPeriodIndex == 3) daysLookback = 365;
    if (_goalPeriodIndex == 4) daysLookback = 3650;

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: daysLookback));

    if (history.isNotEmpty) {
      var entries = history.map((e) {
         final parts = e.split('|');
         return MapEntry(DateTime.parse(parts.first), double.parse(parts.last));
      }).where((e) => e.key.isAfter(cutoff)).toList();
      
      entries.sort((a, b) => a.key.compareTo(b.key));
      
      if (entries.isEmpty) {
        entries.add(MapEntry(now, settings.weight));
      } else {
        if (entries.last.value != settings.weight) {
           entries.add(MapEntry(now, settings.weight));
        }
      }

      spots = entries.map((e) {
        final double dayDiff = e.key.difference(cutoff).inDays.toDouble();
        return FlSpot(dayDiff, e.value);
      }).toList();
    } else {
      spots = [FlSpot(daysLookback.toDouble(), settings.weight)]; 
    }
    
    // Determine Y range with dynamic padding and intervals
    double weightMin = spots.isNotEmpty ? spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) : settings.weight;
    double weightMax = spots.isNotEmpty ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) : settings.weight;
    
    // Ensure range isn't zero
    if (weightMax == weightMin) {
      weightMin -= 2;
      weightMax += 2;
    }

    double yRange = weightMax - weightMin;
    double yInterval = 2.0;
    if (yRange < 5) yInterval = 1.0;
    else if (yRange < 15) yInterval = 2.0;
    else if (yRange < 40) yInterval = 5.0;
    else yInterval = 10.0;

    double minY = (weightMin / yInterval).floor() * yInterval;
    double maxY = (weightMax / yInterval).ceil() * yInterval;
    if (maxY - minY < yInterval * 2) maxY += yInterval; // Ensure at least 3 labels

    double minX = 0;
    double maxX = daysLookback.toDouble();

    return Container(
      height: 240,
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 12, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[100]!,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${value.toInt()} kg',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: daysLookback / 4,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value > daysLookback) return const Text('');
                  String label = '';
                  if (value == 0) label = 'Start';
                  else if (value.toInt() == daysLookback) label = 'Today';
                  else if (daysLookback > 30) {
                     // Show middle labels for longer periods
                     if (value.toInt() == (daysLookback / 2).toInt()) label = '${(daysLookback / 2).toInt()}d ago';
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFF111827),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 3,
                  strokeColor: const Color(0xFF111827),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF111827).withOpacity(0.15),
                    const Color(0xFF111827).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: const Color(0xFF111827),
              tooltipRoundedRadius: 12,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} kg\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    children: [
                       TextSpan(
                         text: 'Weight',
                         style: TextStyle(color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.normal, fontSize: 11),
                       ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  int _calculateTotalCalories(Box<Meal> box, int periodIndex, {int offset = 0}) {
    final now = DateTime.now();
    int startOffset = (periodIndex + offset) * 7;
    
    // Inclusive start date, exclusive end date logic?
    // Actually simpler: iterate 7 days starting from startOffset
    
    int totalCals = 0;
    
    for (int i = 0; i < 7; i++) {
        final daysAgo = startOffset + i;
        final date = now.subtract(Duration(days: daysAgo));
        
        final dayMeals = box.values.where((meal) =>
          meal.timestamp.year == date.year &&
          meal.timestamp.month == date.month &&
          meal.timestamp.day == date.day
        ).toList();
        
        totalCals += dayMeals.fold(0, (sum, meal) => sum + meal.calories);
    }
    
    return totalCals;
  }

  Map<String, Map<String, dynamic>> _getWeeklyNutritionData(Box<Meal> box, int periodIndex) {
    final now = DateTime.now();
    final weekData = <String, Map<String, dynamic>>{};
    
    // Calculate start day offset based on the selected period
    // 0: Current week (0 days offset)
    // 1: Last week (7 days offset)
    // 2: 2 weeks ago (14 days offset)
    // 3: 3 weeks ago (21 days offset)
    final int startOffset = periodIndex * 7;
    
    // Get 7 days for the selected period
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i + startOffset));
      final dayName = DateFormat('E').format(date); // Mon, Tue, Wed, Thu, Fri, Sat, Sun
      
      final dayMeals = box.values.where((meal) =>
        meal.timestamp.year == date.year &&
        meal.timestamp.month == date.month &&
        meal.timestamp.day == date.day
      ).toList();
      
      int protein = dayMeals.fold(0, (sum, meal) => sum + meal.protein);
      int carbs = dayMeals.fold(0, (sum, meal) => sum + meal.carbs);
      int fat = dayMeals.fold(0, (sum, meal) => sum + meal.fat);
      
      // Use full day name as key to avoid conflicts
      final key = '${date.day}_$dayName'; // e.g., "3_Mon", "4_Tue"
      
      weekData[key] = {
        'protein': protein * 4, // Convert to calories (rough estimate)
        'carbs': carbs * 4,
        'fat': fat * 9,
        'dayLabel': dayName.substring(0, 1), // M, T, W, T, F, S, S for display
      };
    }
    
    return weekData;
  }

  Widget _buildNutritionChart(Map<String, Map<String, dynamic>> weekData) {
    // Extract keys in order (they're already sorted by date)
    final sortedKeys = weekData.keys.toList();
    
    // Calculate dynamic maxY for nutrition chart
    double maxVal = 0;
    for (var key in sortedKeys) {
      final data = weekData[key]!;
      double total = (data['protein'] as int).toDouble() + (data['carbs'] as int).toDouble() + (data['fat'] as int).toDouble();
      if (total > maxVal) maxVal = total;
    }
    double dynamicMaxY = maxVal > 0 ? maxVal * 1.2 : 2500; // 20% padding

    return Container(
      height: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: dynamicMaxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text('0');
                  if (value == 500) return const Text('500');
                  if (value == 1000) return const Text('1k');
                  if (value == 2000) return const Text('2k');
                  return const Text('');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedKeys.length) {
                    final key = sortedKeys[value.toInt()];
                    final data = weekData[key]!;
                    final label = data['dayLabel'] as String? ?? 'M';
                    return Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: Color(0xFFE5E7EB),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(sortedKeys.length, (index) {
            final key = sortedKeys[index];
            final data = weekData[key] ?? {'protein': 0, 'carbs': 0, 'fat': 0};
            
            final proteinCals = (data['protein'] as int?) ?? 0;
            final carbsCals = (data['carbs'] as int?) ?? 0;
            final fatCals = (data['fat'] as int?) ?? 0;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (proteinCals + carbsCals + fatCals).toDouble(),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  rodStackItems: [
                    BarChartRodStackItem(0, fatCals.toDouble(), const Color(0xFF3B82F6)), // Blue for Fat (bottom)
                    BarChartRodStackItem(
                      fatCals.toDouble(),
                      (fatCals + carbsCals).toDouble(),
                      const Color(0xFFFBBF24), // Yellow for Carbs (middle)
                    ),
                    BarChartRodStackItem(
                      (fatCals + carbsCals).toDouble(),
                      (fatCals + carbsCals + proteinCals).toDouble(),
                      const Color(0xFFEF4444), // Red for Protein (top)
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showCongratulationsDialog() {
    final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
    final settings = settingsBox.get('user', defaultValue: UserSettings())!;
    
    _confettiController.forward();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AnimatedBuilder(
          animation: _confettiController,
          builder: (context, child) {
            return Stack(
              children: [
                // Animated background
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5 * _confettiController.value),
                  ),
                ),
                // Confetti particles
                ..._buildConfettiParticles(),
                // Dialog
                Center(
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _confettiController,
                      curve: Curves.elasticOut,
                    ),
                    child: Dialog(
                      backgroundColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Trophy icon with pulse animation
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.elasticOut,
                              builder: (context, double value, child) {
                                return Transform.scale(
                                  scale: 0.8 + (value * 0.2),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 20 * value,
                                          spreadRadius: 10 * value,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events,
                                      color: Color(0xFFFFD700),
                                      size: 64,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            // Congratulations text
                            const Text(
                              '🎉 Congratulations! 🎉',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'You\'ve reached your goal weight!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Current weight display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Current Weight',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${settings.weight.toStringAsFixed(1)} kg',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Call to action
                            const Text(
                              'Ready to set a new goal?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      _showSetNewGoalDialog();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFFFFA500),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Set New Goal',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white, width: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      'Maybe Later',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildConfettiParticles() {
    final List<Widget> particles = [];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < 30; i++) {
      final left = ((random + i * 37) % 100) / 100.0;
      final color = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.pink,
        Colors.orange,
      ][i % 7];
      
      particles.add(
        Positioned(
          left: MediaQuery.of(context).size.width * left,
          top: -50,
          child: TweenAnimationBuilder(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 1500 + (i * 50)),
            curve: Curves.easeInCubic,
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(
                  30 * (0.5 - left) * value,
                  MediaQuery.of(context).size.height * value,
                ),
                child: Transform.rotate(
                  angle: value * 12,
                  child: Opacity(
                    opacity: 1.0 - (value * 0.5),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return particles;
  }

  void _showSetNewGoalDialog() {
    final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
    final settings = settingsBox.get('user', defaultValue: UserSettings())!;
    final TextEditingController goalController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flag,
                        color: Color(0xFFFFA500),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Set New Goal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Weight',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${settings.weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'New Goal Weight (kg)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: goalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'e.g., ${(settings.weight - 5).toStringAsFixed(1)}',
                    suffixText: 'kg',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFA500),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newGoal = double.tryParse(goalController.text);
                          if (newGoal != null && newGoal > 0) {
                            settings.goalWeight = newGoal;
                            settings.save();
                            Navigator.of(dialogContext).pop();
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'New goal set: ${newGoal.toStringAsFixed(1)} kg',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                            
                            // Reset the congratulations flag
                            setState(() {
                              _hasShownCongrats = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA500),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Set Goal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWeightHistoryDialog() {
    final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
    final settings = settingsBox.get('user', defaultValue: UserSettings())!;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Weight History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (settings.weightHistory == null || settings.weightHistory!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.scale_outlined,
                          size: 64,
                          color: Color(0xFFE5E7EB),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No weight history yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start logging your weight to track progress',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: settingsBox.listenable(),
                      builder: (context, Box<UserSettings> box, _) {
                        final updatedSettings = box.get('user', defaultValue: UserSettings())!;
                        final history = updatedSettings.weightHistory ?? [];
                        
                        // Reverse to show newest first
                        final reversedHistory = history.reversed.toList();
                        
                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: reversedHistory.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final actualIndex = history.length - 1 - index; // Convert to original index
                            final entry = reversedHistory[index];
                            final parts = entry.split('|');
                            final date = DateTime.parse(parts[0]);
                            final weight = double.parse(parts[1]);
                            final isLatest = index == 0; // First in reversed list = latest entry
                            
                            return Dismissible(
                              key: Key('weight_$actualIndex'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext confirmContext) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: const Text('Delete Weight Entry?'),
                                      content: Text(
                                        isLatest
                                            ? 'This is your most recent weight entry. Deleting it will update your current weight to the previous entry.'
                                            : 'Are you sure you want to delete this weight entry? This will update your progress chart.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(confirmContext).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(confirmContext).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (direction) {
                                updatedSettings.deleteWeightEntry(actualIndex);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Weight entry deleted',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      textColor: Colors.white,
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isLatest
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isLatest
                                        ? const Color(0xFF3B82F6)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isLatest
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.scale,
                                        color: isLatest ? Colors.white : const Color(0xFF6B7280),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${weight.toStringAsFixed(1)} kg',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: isLatest
                                                      ? const Color(0xFF3B82F6)
                                                      : const Color(0xFF111827),
                                                ),
                                              ),
                                              if (isLatest) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF3B82F6),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Current',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM dd, yyyy • HH:mm').format(date),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_left,
                                      color: Color(0xFFE5E7EB),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                if (settings.weightHistory != null && settings.weightHistory!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFFFA500),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Swipe left to delete an entry',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFA500),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
