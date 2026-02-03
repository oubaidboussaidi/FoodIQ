import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/user_settings.dart';
import '../widgets/home_components.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<UserSettings> _settingsBox;
  late UserSettings _settings;
  String? _currentSubPage;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box<UserSettings>('settings_box');
    _settings = _settingsBox.get('user', defaultValue: UserSettings())!;
  }

  void _save() {
    _settingsBox.put('user', _settings);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSubPage == 'personal') return _buildPersonalDetails();
    if (_currentSubPage == 'macros') return _buildAdjustMacros();
    if (_currentSubPage == 'history') return _buildWeightHistory();
    if (_currentSubPage == 'goal') return _buildGoalWeightPage();
    if (_currentSubPage == 'notifications') return _buildNotificationSettings();

    return GradientBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Settings',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 32),
              _buildNavList(),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Text(
                      'v1.0.0',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Container(
                      height: 1,
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.withOpacity(0.0), Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.0)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'FOODIQ INTELLIGENCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Designed & Engineered by Oubaid Boussaidi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          _buildNavItem(Icons.badge_outlined, 'Personal details', () => setState(() => _currentSubPage = 'personal')),
          _buildDivider(),
          _buildNavItem(Icons.donut_large, 'Adjust macronutrients', () => setState(() => _currentSubPage = 'macros')),
          _buildDivider(),
          _buildNavItem(Icons.flag_outlined, 'Goal & current weight', () => setState(() => _currentSubPage = 'goal')),
          _buildDivider(),
          _buildNavItem(Icons.history, 'Weight history', () => setState(() => _currentSubPage = 'history')),
          _buildDivider(),
          _buildNavItem(Icons.notifications_none_outlined, 'Smart notifications', () => setState(() => _currentSubPage = 'notifications')),
        ],
      ),
    );
  }

  // ... (Other helper methods)

  Widget _buildNotificationSettings() {
    return _SubPageWrapper(
      title: 'Smart notifications',
      onBack: () => setState(() => _currentSubPage = null),
      child: Column(
        children: [
          _buildNotificationGroup(),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildActionButton('Enable All', const Color(0xFF111827), Colors.white, () {
                  setState(() {
                    _settings.notifyWater = true;
                    _settings.notifyProtein = true;
                    _settings.notifyCalories = true;
                    _settings.notifyWorkouts = true;
                    _settings.notifyMotivation = true;
                  });
                  _save();
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton('Disable All', Colors.white, const Color(0xFF111827), () {
                  setState(() {
                    _settings.notifyWater = false;
                    _settings.notifyProtein = false;
                    _settings.notifyCalories = false;
                    _settings.notifyWorkouts = false;
                    _settings.notifyMotivation = false;
                  });
                  _save();
                }, border: true),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color bg, Color text, VoidCallback onTap, {bool border = false}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: text,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: border ? const BorderSide(color: Color(0xFFE5E7EB)) : BorderSide.none,
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildNotificationGroup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          _buildToggleTile('Water & Hydration', 'Daily water intake reminders', _settings.notifyWater, (v) => setState(() => _settings.notifyWater = v)),
          _buildDivider(),
          _buildToggleTile('Protein Monitoring', 'Deep syncing with macro goals', _settings.notifyProtein, (v) => setState(() => _settings.notifyProtein = v)),
          _buildDivider(),
          _buildToggleTile('Calorie Pacing', 'Smart alerts based on bulk/cut', _settings.notifyCalories, (v) => setState(() => _settings.notifyCalories = v)),
          _buildDivider(),
          _buildToggleTile('Training Guidance', 'Surplus/Deficit session logic', _settings.notifyWorkouts, (v) => setState(() => _settings.notifyWorkouts = v)),
          _buildDivider(),
          _buildToggleTile('Morning Motivation', 'Daily metabolic rising guide', _settings.notifyMotivation, (v) => setState(() => _settings.notifyMotivation = v)),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, String sub, bool value, Function(bool) onChanged) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      subtitle: Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      value: value,
      activeColor: const Color(0xFF3B82F6),
      onChanged: (v) {
        onChanged(v);
        _save();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildNavItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF111827), size: 22),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey[100], indent: 20, endIndent: 20);

  // --- Sub Pages ---

  Widget _buildPersonalDetails() {
    return _SubPageWrapper(
      title: 'Personal details',
      onBack: () => setState(() => _currentSubPage = null),
      child: Column(
        children: [
          _buildGoalWeightCard(),
          const SizedBox(height: 20),
          _buildPersonalDetailsList(),
        ],
      ),
    );
  }

  Widget _buildGoalWeightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Goal Weight', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const SizedBox(height: 4),
              Text('${_settings.goalWeight?.toStringAsFixed(1) ?? _settings.weight} kg', 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            ],
          ),
          ElevatedButton(
            onPressed: () => setState(() => _currentSubPage = 'goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text('Change Goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsList() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          _buildDetailTile('Current Weight', '${_settings.weight} kg', () => _showEditDialog('Weight', _settings.weight, (v) => _settings.updateWeight(v))),
          _buildDivider(),
          _buildDetailTile('Height', '${_settings.height} cm', () => _showEditDialog('Height', _settings.height.toDouble(), (v) => _settings.height = v.toInt())),
          _buildDivider(),
          _buildDetailTile('Age', '${_settings.age} years', () => _showEditDialog('Age', _settings.age.toDouble(), (v) => _settings.age = v.toInt())),
          _buildDivider(),
          _buildDetailTile('Gender', _settings.gender, () => _showGenderPicker()),
          _buildDivider(),
          _buildDetailTile('Daily Step Goal', '${_settings.stepGoal} steps', () => _showEditDialog('Step Goal', _settings.stepGoal.toDouble(), (v) => _settings.stepGoal = v.toInt())),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, VoidCallback onTap) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF111827))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildCalorieTargetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daily calorie target', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('${_settings.getCalorieGoal()} kcal', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showEditDialog('Calories', _settings.getCalorieGoal().toDouble(), (v) {
              _settings.autoGenerateGoal = false;
              _settings.manualCalorieGoal = v.toInt();
            }),
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
          )
        ],
      ),
    );
  }

  Widget _buildAdjustMacros() {
    return _SubPageWrapper(
      title: 'Adjust macronutrients',
      onBack: () => setState(() => _currentSubPage = null),
      child: Column(
        children: [
          _buildCalorieTargetCard(),
          const SizedBox(height: 20),
          _buildMacrosCard(),
          const SizedBox(height: 24),
          _buildMicrosAccordion(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
               onPressed: () {
                 setState(() => _settings.autoGenerateGoal = true);
                 _save();
               },
               style: OutlinedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16),
                 side: const BorderSide(color: Color(0xFFE5E7EB)),
                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
               ),
               child: const Text('Auto Generate Goals', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMacrosCard() {
    return Column(
      children: [
        _buildMacroGoalTile('Protein goal', _settings.getProteinGoal(), const Color(0xFFEF4444), Icons.restaurant_menu),
        const SizedBox(height: 12),
        _buildMacroGoalTile('Carb goal', _settings.getCarbsGoal(), const Color(0xFFFBBF24), Icons.eco),
        const SizedBox(height: 12),
        _buildMacroGoalTile('Fat goal', _settings.getFatGoal(), const Color(0xFF3B82F6), Icons.opacity),
      ],
    );
  }

  Widget _buildMacroGoalTile(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[50]!)),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 28,
            lineWidth: 4,
            percent: 1.0,
            progressColor: color,
            backgroundColor: color.withOpacity(0.1),
            center: Icon(icon, size: 18, color: color),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(onPressed: () => _showEditDialog(label, value.toDouble(), (v) {
             _settings.autoGenerateGoal = false;
             if (label.contains('Protein')) _settings.manualProteinGoal = v.toInt();
             if (label.contains('Carb')) _settings.manualCarbsGoal = v.toInt();
             if (label.contains('Fat')) _settings.manualFatGoal = v.toInt();
          }), icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey)),
        ],
      ),
    );
  }

  bool _microsExpanded = false;
  Widget _buildMicrosAccordion() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _microsExpanded = !_microsExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('View micronutrients', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
              Icon(_microsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[600]),
            ],
          ),
        ),
        if (_microsExpanded) ...[
          const SizedBox(height: 16),
          _buildMicroTile('Fiber goal', 38, Colors.purple),
          const SizedBox(height: 12),
          _buildMicroTile('Sugar goal', 50, Colors.pink),
          const SizedBox(height: 12),
          _buildMicroTile('Sodium goal', 2300, Colors.amber),
        ]
      ],
    );
  }

  Widget _buildMicroTile(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 24,
            lineWidth: 3,
            percent: 1.0,
            progressColor: color.withOpacity(0.5),
            backgroundColor: color.withOpacity(0.05),
            center: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightHistory() {
    final history = _settings.weightHistory ?? [];
    final reversedHistory = history.reversed.toList();

    return _SubPageWrapper(
      title: 'Weight history',
      onBack: () => setState(() => _currentSubPage = null),
      child: history.isEmpty 
        ? const Center(child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No weight history recorded.', style: TextStyle(color: Colors.grey)),
          )) 
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reversedHistory.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final actualIndex = history.length - 1 - index;
              final parts = reversedHistory[index].split('|');
              final date = DateTime.parse(parts[0]);
              final weight = parts[1];
              final isLatest = index == 0;

              return Dismissible(
                key: Key('weight_settings_$actualIndex'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Delete Entry?'),
                      content: Text(isLatest 
                        ? 'This is your most recent weight entry. Deleting it will restore your previous weight.'
                        : 'Are you sure you want to delete this weight record?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  setState(() {
                    _settings.deleteWeightEntry(actualIndex);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Weight entry deleted'), 
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(16),
                    )
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24), 
                    border: Border.all(color: isLatest ? const Color(0xFF3B82F6).withOpacity(0.3) : Colors.grey[50]!),
                    boxShadow: isLatest ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('$weight kg', style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: isLatest ? const Color(0xFF3B82F6) : const Color(0xFF111827),
                          )),
                          if (isLatest) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Current', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ]
                        ],
                      ),
                      Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildGoalWeightPage() {
    return _SubPageWrapper(
      title: 'Goal & current weight',
      onBack: () => setState(() => _currentSubPage = null),
      child: Column(
        children: [
           _buildDetailedGoalCard(),
           const SizedBox(height: 24),
           // Intensity slider
           _buildGoalIntensityCard(),
           const SizedBox(height: 24),
           _buildGoalInsight(),
        ],
      ),
    );
  }

  Widget _buildGoalInsight() {
    String text = "";
    Color color = Colors.grey[700]!;
    IconData icon = Icons.info_outline;

    final double intensity = _settings.goalIntensity;
    final bool isBulking = (_settings.goalWeight ?? _settings.weight) > _settings.weight;
    final bool atGoal = (_settings.goalWeight ?? _settings.weight - _settings.weight).abs() < 0.1;

    if (atGoal) {
      text = "Maintaining weight. Focus on performance and recovery.";
      color = Colors.blue[800]!;
    } else if (isBulking) {
      if (intensity < 0.3) {
        text = "Lean Bulk: Ideal for steady muscle growth with minimal fat gain.";
        color = Colors.green[800]!;
      } else if (intensity < 0.7) {
        text = "Standard Bulk: Faster progress while maintaining good body quality.";
        color = Colors.orange[800]!;
      } else {
        text = "Heavy Bulk: Maximum weight gain. Use caution as fat gain will be significant.";
        color = Colors.red[800]!;
        icon = Icons.warning_amber_rounded;
      }
    } else {
      if (intensity < 0.3) {
        text = "Slow Cut: Most sustainable for muscle preservation and strength.";
        color = Colors.green[800]!;
      } else if (intensity < 0.7) {
        text = "Standard Cut: Effective fat loss with moderate effort.";
        color = Colors.orange[800]!;
      } else {
        text = "Express Cut: Very low calories. Hard to maintain and risks muscle loss.";
        color = Colors.red[800]!;
        icon = Icons.warning_amber_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.1))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, height: 1.4, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDetailedGoalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          _buildDetailTile('Current Weight', '${_settings.weight} kg', () => _showEditDialog('Weight', _settings.weight, (v) => _settings.updateWeight(v))),
          _buildDivider(),
          _buildDetailTile('Goal Weight', '${_settings.goalWeight ?? _settings.weight} kg', () => _showEditDialog('Goal Weight', _settings.goalWeight ?? _settings.weight, (v) => _settings.goalWeight = v)),
        ],
      ),
    );
  }

  Widget _buildGoalIntensityCard() {
     final double currentWeight = _settings.weight;
    final double goalWeight = _settings.goalWeight ?? currentWeight;
    String recommendation = "";
    bool atGoal = (goalWeight - currentWeight).abs() < 0.1;
    if (goalWeight > currentWeight) recommendation = "Bulking Mode (${(_settings.goalIntensity * 100).toInt()}% Intensity)";
    else if (goalWeight < currentWeight) recommendation = "Cutting Mode (${(_settings.goalIntensity * 100).toInt()}% Intensity)";
    else recommendation = "At Goal Weight";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Intensity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(recommendation, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 24),
          if (!atGoal) _buildDirectSlider() else const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Change Goal Weight to adjust intensity", style: TextStyle(color: Colors.grey, fontSize: 13)))),
        ],
      ),
    );
  }

  Widget _buildDirectSlider() {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 8, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12), activeTrackColor: Colors.black, thumbColor: Colors.black),
          child: Slider(
            value: _settings.goalIntensity,
            divisions: 100,
            onChanged: (v) {
              setState(() => _settings.goalIntensity = v);
              _save();
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("Lean", style: TextStyle(fontSize: 10, color: Colors.grey)),
               Text("Balanced", style: TextStyle(fontSize: 10, color: Colors.grey)),
               Text("Aggressive", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        )
      ],
    );
  }

  // --- Helpers ---

  void _showEditDialog(String title, double initial, Function(double) onSave) {
    final controller = TextEditingController(text: initial.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(suffixText: title.contains('Weight') ? 'kg' : (title.contains('Height') ? 'cm' : ''))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            final val = double.tryParse(controller.text);
            if (val != null) {
               setState(() => onSave(val));
               _save();
            }
            Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _showGenderPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('Male'), onTap: () { setState(() => _settings.gender = 'Male'); _save(); Navigator.pop(context); }),
          ListTile(title: const Text('Female'), onTap: () { setState(() => _settings.gender = 'Female'); _save(); Navigator.pop(context); }),
        ],
      ),
    );
  }
}

class _SubPageWrapper extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const _SubPageWrapper({required this.title, required this.onBack, required this.child});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  child,
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
