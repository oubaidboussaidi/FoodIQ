import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF1F5F9), // cool grey-blue
            Color(0xFFFDF2F8), // warm soft pink
            Color(0xFFFFFFFF), // white bottom
          ],
        ),
      ),
      child: child,
    );
  }
}

class Header extends StatelessWidget {
  final bool isToday;
  final Function(bool) onDayChanged;
  
  const Header({
    super.key,
    required this.isToday,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.apple,
                    size: 32,
                    color: Colors.black,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Cal AI",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
              Icon(Icons.notifications_outlined,
                  size: 28, color: Colors.black),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              GestureDetector(
                onTap: () => onDayChanged(true),
                child: Text(
                  "Today",
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 16,
                    color: isToday ? const Color(0xFF111827) : const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: () => onDayChanged(false),
                child: Text(
                  "Yesterday",
                  style: TextStyle(
                    fontWeight: !isToday ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 16,
                    color: !isToday ? const Color(0xFF111827) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class CaloriesCard extends StatelessWidget {
  final int caloriesLeft;
  final int totalCalories;
  final double progress;

  const CaloriesCard({
    super.key, 
    required this.caloriesLeft,
    required this.totalCalories,
    required this.progress
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$caloriesLeft",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Calories left",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    color: Colors.black,
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
                const Icon(
                  Icons.local_fire_department,
                  color: Colors.black,
                  size: 32,
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class MacroRow extends StatelessWidget {
  final int protein;
  final int carbs;
  final int fat;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;

  const MacroRow({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.proteinGoal = 150,
    this.carbsGoal = 200,
    this.fatGoal = 65,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MacroCard(
            value: "${protein}g",
            label: "Protein",
            color: const Color(0xFFEF4444),
            icon: Icons.restaurant,
            progress: (protein / proteinGoal).clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MacroCard(
            value: "${carbs}g",
            label: "Carbs",
            color: const Color(0xFFF59E0B),
            icon: Icons.spa,
            progress: (carbs / carbsGoal).clamp(0.0, 1.0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MacroCard(
            value: "${fat}g",
            label: "Fats",
            color: const Color(0xFF3B82F6),
            icon: Icons.emoji_food_beverage,
            progress: (fat / fatGoal).clamp(0.0, 1.0),
          ),
        ),
      ],
    );
  }
}

class MacroCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final double progress;

  const MacroCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                height: 1.0,
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
            const SizedBox(height: 12),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 5,
                      color: color,
                      backgroundColor: const Color(0xFFE5E7EB),
                    ),
                  ),
                  Icon(icon, size: 20, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Re-export FoodTile (unchanged or same as before)
class FoodTile extends StatelessWidget {
  final String name;
  final String calories;
  final String time;
  final String? imagePath;

  const FoodTile({
    super.key,
    required this.name,
    required this.calories,
    required this.time,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(12),
                image: imagePath != null && imagePath!.isNotEmpty 
                  ? DecorationImage(image:  AssetImage(imagePath!) as ImageProvider, fit: BoxFit.cover) 
                  : null, 
              ),
              child: imagePath == null || imagePath!.isEmpty 
                ? const Icon(Icons.fastfood, color: Colors.grey) 
                : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$calories • $time",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
