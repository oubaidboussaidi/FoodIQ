import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal.dart';
import '../services/storage_service.dart';
import '../widgets/home_components.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'camera_screen.dart';
import '../models/user_settings.dart';
import '../services/notification_service.dart';
import 'meal_scan_screen.dart';
import 'meal_entry_screen.dart';
import 'saved_meals_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomAppBar(
        elevation: 8,
        color: const Color(0xFFF5F5F5), // Slightly darker than page background
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_outlined,
                        color: _currentIndex == 0 ? const Color(0xFF111827) : const Color(0xFF6B7280),
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 10,
                          color: _currentIndex == 0 ? const Color(0xFF111827) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insert_chart_outlined,
                        color: _currentIndex == 1 ? const Color(0xFF111827) : const Color(0xFF6B7280),
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Analytics',
                        style: TextStyle(
                          fontSize: 10,
                          color: _currentIndex == 1 ? const Color(0xFF111827) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: _currentIndex == 2 ? const Color(0xFF111827) : const Color(0xFF6B7280),
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 10,
                          color: _currentIndex == 2 ? const Color(0xFF111827) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 80), // Space for bigger FAB
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Colors.white, size: 32),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Add Meal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAddOption(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: 'Describe Meal',
                      subtitle: 'Tell AI what you ate',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const MealScanScreen()),
                        );
                      },
                    ),
                    _buildAddOption(
                      context,
                      icon: Icons.edit_outlined,
                      title: 'Manual Entry',
                      subtitle: 'Enter nutrition info manually',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const MealEntryScreen()));
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildAddOption(
                      context,
                      icon: Icons.bookmark_border,
                      title: 'My Meals',
                      subtitle: 'Add from your saved meals',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (c) => const SavedMealsScreen()));
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildAddOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }


}
