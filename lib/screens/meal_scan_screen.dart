import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/meal_analysis_service.dart';
import '../models/scanned_food.dart';
import '../models/meal.dart';
import '../services/storage_service.dart';

class MealScanScreen extends StatefulWidget {
  const MealScanScreen({super.key});

  @override
  State<MealScanScreen> createState() => _MealScanScreenState();
}

class _MealScanScreenState extends State<MealScanScreen> {
  final MealAnalysisService _analysisService = MealAnalysisService();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  List<ScannedFood> _results = [];
  Map<String, double> _portions = {}; 
  File? _selectedImage;
  String? _errorMessage;

  Future<void> _analyzeDescription() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = [];
      _errorMessage = null; 
      FocusScope.of(context).unfocus(); 
    });

    try {
      final results = await _analysisService.analyzeText(text);
      if (mounted) {
        setState(() {
          _results = results;
          for (var food in results) {
            _portions[food.name] = food.defaultPortionG;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  Future<void> _saveMeal() async {
    // 1. Calculate Totals
    double totalCals = 0, totalPro = 0, totalCarbs = 0, totalFat = 0;
    double totalFib = 0, totalSug = 0, totalSod = 0;
    List<String> foodNames = [];

    for (var food in _results) {
      double multiplier = (_portions[food.name] ?? 0) / 100.0;
      totalCals += food.caloriesPer100g * multiplier;
      totalPro += food.proteinPer100g * multiplier;
      totalCarbs += food.carbsPer100g * multiplier;
      totalFat += food.fatPer100g * multiplier;
      totalFib += food.fiberPer100g * multiplier;
      totalSug += food.sugarPer100g * multiplier;
      totalSod += food.sodiumPer100g * multiplier;
      foodNames.add(food.name.split(' ').first); // Short name
    }

    // ... (Meal Name Logic omitted for brevity)
    String mealName = foodNames.take(2).join(" & ");
    if (foodNames.length > 2) mealName += " + more";
    if (mealName.isEmpty) mealName = "Quick Meal";

    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameCtrl = TextEditingController(text: mealName);
        return AlertDialog(
          title: const Text("Name this Meal"),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: "Meal Name"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                // SAVE LOGIC
                final meal = Meal(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  calories: totalCals.round(),
                  protein: totalPro.round(),
                  carbs: totalCarbs.round(),
                  fat: totalFat.round(),
                  fiber: totalFib.round(),
                  sugar: totalSug.round(),
                  sodium: totalSod.round(),
                  imagePath: _selectedImage?.path,
                  timestamp: DateTime.now(),
                );

                final storage = Provider.of<StorageService>(context, listen: false);
                await storage.addMeal(meal);

                if (context.mounted) {
                  Navigator.pop(context); // Close Dialog
                  Navigator.pop(context); // Close Screen
                }
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Describe Meal', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Text Input Area 
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "What did you eat?",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  "E.g., 200g chicken breast with 1 cup of rice",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Type description...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Add Photo Button
                if (_selectedImage != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, height: 100, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 8, top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => setState(() => _selectedImage = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt, color: Colors.black),
                    label: const Text("Add Photo (Optional)", style: TextStyle(color: Colors.black)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _analyzeDescription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Analyze Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const LinearProgressIndicator(color: Colors.black),

          // 2. Results List / Error Message
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : _errorMessage != null
                ? _buildBotMessage(_errorMessage!, isError: true)
                : _results.isEmpty
                    ? _buildBotMessage("I'm ready! Tell me what you ate and I'll crunch the numbers for you.")
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _results.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildFoodCard(_results[index]),
                      ),
          ),
          
          // 3. Save Summary
          if (_results.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Calories", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          "${_calculateTotalCalories().toStringAsFixed(0)} kcal",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _saveMeal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Save Meal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateTotalCalories() {
    double total = 0;
    for (var food in _results) {
      double portion = _portions[food.name] ?? 0;
      total += (food.caloriesPer100g * (portion / 100));
    }
    return total;
  }

  Widget _buildBotMessage(String message, {bool isError = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isError ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isError ? Icons.sentiment_very_dissatisfied : Icons.face,
                        size: 48,
                        color: isError ? Colors.red : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isError ? Colors.red[50] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isError ? Colors.red[900] : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoodCard(ScannedFood food) {
    // ... rest of the method remains same
    double portion = _portions[food.name] ?? 100;
    double multiplier = portion / 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name.split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '), 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          food.calculationSource?.contains("online") == true ? Icons.language : Icons.cloud_off,
                          size: 10,
                          color: food.calculationSource?.contains("online") == true ? Colors.blue : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          food.calculationSource ?? "Source unknown", 
                          style: TextStyle(
                            fontSize: 10, 
                            color: food.calculationSource?.contains("online") == true ? Colors.blue : Colors.orange,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                "${(food.caloriesPer100g * multiplier).toStringAsFixed(0)} kcal",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sliders and Macros (simplified code for brevity)
          Row(
            children: [
               Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.black,
                    inactiveTrackColor: Colors.grey[200],
                    thumbColor: Colors.black,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: portion, min: 0, max: 1000, divisions: 200,
                    onChanged: (val) { setState(() => _portions[food.name] = val); },
                  ),
                ),
              ),
              Text('${portion.round()}g', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
