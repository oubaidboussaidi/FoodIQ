import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/saved_meal.dart';
import '../services/storage_service.dart';
import 'meal_entry_screen.dart';

class SavedMealsScreen extends StatelessWidget {
  const SavedMealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Meals",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<SavedMeal>(StorageService.savedMealsBoxName).listenable(),
        builder: (context, Box<SavedMeal> box, _) {
          final savedMeals = box.values.toList().reversed.toList();

          if (savedMeals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   Text("No saved meals yet", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                   const SizedBox(height: 8),
                   const Text("Save meals to reuse them later!", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: savedMeals.length,
            itemBuilder: (context, index) {
              final meal = savedMeals[index];
              return _buildSavedMealTile(context, meal);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MealEntryScreen(isTemplate: true))),
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSavedMealTile(BuildContext context, SavedMeal meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            image: meal.imagePath.isNotEmpty
                ? DecorationImage(image: FileImage(File(meal.imagePath)), fit: BoxFit.cover)
                : null,
          ),
          child: meal.imagePath.isEmpty
              ? const Icon(Icons.restaurant, color: Color(0xFF9CA3AF))
              : null,
        ),
        title: Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${meal.calories} kcal • P: ${meal.protein}g • C: ${meal.carbs}g • F: ${meal.fat}g"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MealEntryScreen(templateMeal: meal, isTemplate: true))),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: () {
                // Log this meal today
                Navigator.push(context, MaterialPageRoute(builder: (c) => MealEntryScreen(templateMeal: meal)));
              },
            ),
          ],
        ),
        onTap: () {
          // Log this meal today
          Navigator.push(context, MaterialPageRoute(builder: (c) => MealEntryScreen(templateMeal: meal)));
        },
      ),
    );
  }
}
