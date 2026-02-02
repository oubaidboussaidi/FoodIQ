import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/meal.dart';
import '../models/saved_meal.dart';
import '../models/user_settings.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/food.dart';
import '../services/food_database.dart';

class MealEntryScreen extends StatefulWidget {
  final Meal? existingMeal;
  final SavedMeal? templateMeal;
  final bool isTemplate;

  const MealEntryScreen({
    super.key,
    this.existingMeal,
    this.templateMeal,
    this.isTemplate = false,
  });

  @override
  State<MealEntryScreen> createState() => _MealEntryScreenState();
}

class _MealEntryScreenState extends State<MealEntryScreen> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _sugarController;
  late TextEditingController _sodiumController;
  String? _selectedImagePath;
  bool _isSavingToMyMeals = false;
  
  // New "Build from Foods" state
  bool _isBuildMode = false;
  final List<MealComponent> _mealComponents = [];
  final TextEditingController _searchController = TextEditingController();
  List<Food> _suggestions = [];

  @override
  void initState() {
    super.initState();
    final mealName = widget.existingMeal?.name ?? widget.templateMeal?.name ?? '';
    final calories = widget.existingMeal?.calories ?? widget.templateMeal?.calories ?? 0;
    final protein = widget.existingMeal?.protein ?? widget.templateMeal?.protein ?? 0;
    final carbs = widget.existingMeal?.carbs ?? widget.templateMeal?.carbs ?? 0;
    final fat = widget.existingMeal?.fat ?? widget.templateMeal?.fat ?? 0;
    final fiber = widget.existingMeal?.fiber ?? widget.templateMeal?.fiber ?? 0;
    final sugar = widget.existingMeal?.sugar ?? widget.templateMeal?.sugar ?? 0;
    final sodium = widget.existingMeal?.sodium ?? widget.templateMeal?.sodium ?? 0;
    _selectedImagePath = widget.existingMeal?.imagePath ?? widget.templateMeal?.imagePath ?? '';

    _nameController = TextEditingController(text: mealName);
    _caloriesController = TextEditingController(text: calories > 0 ? calories.toString() : '');
    _proteinController = TextEditingController(text: protein > 0 ? protein.toString() : '');
    _carbsController = TextEditingController(text: carbs > 0 ? carbs.toString() : '');
    _fatController = TextEditingController(text: fat > 0 ? fat.toString() : '');
    _fiberController = TextEditingController(text: fiber > 0 ? fiber.toString() : '');
    _sugarController = TextEditingController(text: sugar > 0 ? sugar.toString() : '');
    _sodiumController = TextEditingController(text: sodium > 0 ? sodium.toString() : '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _updateTotalsFromComponents() {
    double totalCals = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var component in _mealComponents) {
      totalCals += component.calories;
      totalProtein += component.protein;
      totalCarbs += component.carbs;
      totalFat += component.fat;
    }

    setState(() {
      _caloriesController.text = totalCals.round().toString();
      _proteinController.text = totalProtein.round().toString();
      _carbsController.text = totalCarbs.round().toString();
      _fatController.text = totalFat.round().toString();
    });
  }

  void _addFood(Food food) {
    setState(() {
      _mealComponents.add(MealComponent(
        food: food,
        quantity: food.defaultUnit == FoodUnit.ml ? 100 : (food.defaultUnit == FoodUnit.piece ? 1 : 100),
        unit: food.defaultUnit,
      ));
      _searchController.clear();
      _suggestions = [];
    });
    _updateTotalsFromComponents();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty ||
        _caloriesController.text.isEmpty ||
        _proteinController.text.isEmpty ||
        _carbsController.text.isEmpty ||
        _fatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all main fields')),
      );
      return;
    }

    final name = _nameController.text;
    final cals = int.parse(_caloriesController.text);
    final protein = int.parse(_proteinController.text);
    final carbs = int.parse(_carbsController.text);
    final fat = int.parse(_fatController.text);
    final fiber = int.tryParse(_fiberController.text) ?? 0;
    final sugar = int.tryParse(_sugarController.text) ?? 0;
    final sodium = int.tryParse(_sodiumController.text) ?? 0;

    if (widget.isTemplate) {
      // Saving/Updating a Template
      final savedMealsBox = Hive.box<SavedMeal>(StorageService.savedMealsBoxName);
      final id = widget.templateMeal?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final savedMeal = SavedMeal(
        id: id,
        name: name,
        calories: cals,
        protein: protein,
        carbs: carbs,
        fat: fat,
        imagePath: _selectedImagePath ?? '',
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
      );
      await savedMealsBox.put(id, savedMeal);
    } else {
      // Saving/Updating an Instance (Meal)
      final mealsBox = Hive.box<Meal>(StorageService.boxName);
      final id = widget.existingMeal?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final timestamp = widget.existingMeal?.timestamp ?? DateTime.now();
      
      final meal = Meal(
        id: id,
        name: name,
        calories: cals,
        protein: protein,
        carbs: carbs,
        fat: fat,
        imagePath: _selectedImagePath ?? '',
        timestamp: timestamp,
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
      );
      
      await mealsBox.put(id, meal);

      // If "Save to My Meals" is checked, also save as template
      if (_isSavingToMyMeals) {
        final savedMealsBox = Hive.box<SavedMeal>(StorageService.savedMealsBoxName);
        final savedId = DateTime.now().millisecondsSinceEpoch.toString();
        final savedMeal = SavedMeal(
          id: savedId,
          name: name,
          calories: cals,
          protein: protein,
          carbs: carbs,
          fat: fat,
          imagePath: _selectedImagePath ?? '',
          fiber: fiber,
          sugar: sugar,
          sodium: sodium,
        );
        await savedMealsBox.put(savedId, savedMeal);
      }

      // Trigger Notification Check
      final settingsBox = Hive.box<UserSettings>(StorageService.settingsBoxName);
      final settings = settingsBox.get('user', defaultValue: UserSettings())!;
      final now = DateTime.now();
      
      final todayMeals = mealsBox.values.where((m) => 
        m.timestamp.year == now.year &&
        m.timestamp.month == now.month &&
        m.timestamp.day == now.day
      ).toList();
      
      int totalCals = todayMeals.fold(0, (sum, item) => sum + item.calories);
      int totalProtein = todayMeals.fold(0, (sum, item) => sum + item.protein);
      
      NotificationService().checkCalorieStatus(
        settings.getCalorieGoal() - totalCals,
        settings.getCalorieGoal(),
        settings.getProteinGoal() - totalProtein,
        settings.getProteinGoal(),
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.existingMeal != null ? 'Meal updated!' : 'Meal added!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingMeal != null || widget.templateMeal != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isTemplate 
            ? (isEditing ? 'Edit Template' : 'New Template')
            : (isEditing ? 'Edit Meal' : 'Add Meal'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Image Picker Card
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: _selectedImagePath != null && _selectedImagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Add a photo', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Name Input
            _buildInputCard(
              child: TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: 'Meal Name',
                  border: InputBorder.none,
                  floatingLabelStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mode Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBuildMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isBuildMode ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Manual Macros',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isBuildMode ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isBuildMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isBuildMode ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Build Meal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isBuildMode ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (_isBuildMode) ...[
              // Build Mode UI
              _buildInputCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _suggestions = FoodDatabase.search(val);
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search for a food (e.g. Rice, Egg)',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                    if (_suggestions.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
                        ),
                        child: Column(
                          children: _suggestions.map((food) => ListOperationSuggestion(
                            food: food,
                            onTap: () => _addFood(food),
                          )).toList(),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_mealComponents.isNotEmpty) ...[
                Column(
                  children: _mealComponents.asMap().entries.map((entry) {
                    final index = entry.key;
                    final component = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(component.food.emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(component.food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${component.calories.round()} kcal | P: ${component.protein.round()}g',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quantity Input
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              key: ValueKey('${component.food.name}_${component.quantity}'),
                              initialValue: component.quantity.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              onChanged: (val) {
                                final newVal = double.tryParse(val);
                                if (newVal != null) {
                                  component.quantity = newVal;
                                  _updateTotalsFromComponents();
                                }
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(borderSide: BorderSide.none),
                                filled: true,
                                fillColor: Color(0xFFF3F4F6),
                              ),
                            ),
                          ),
                          
                          // NEW: Serving Sizes Dropdown
                          if (component.food.servingSizes != null) ...[
                            const SizedBox(width: 8),
                            PopupMenuButton<double>(
                              icon: const Icon(Icons.straighten, size: 20, color: Colors.blue),
                              tooltip: 'Common Sizes',
                              onSelected: (val) {
                                setState(() {
                                  component.quantity = val;
                                  // Refresh key to update TextFormField value
                                  _updateTotalsFromComponents();
                                });
                              },
                              itemBuilder: (context) => component.food.servingSizes!.entries.map((e) {
                                return PopupMenuItem(
                                  value: e.value,
                                  child: Text(e.key),
                                );
                              }).toList(),
                            ),
                          ],
                          const SizedBox(width: 8),
                          // Unit Picker
                          DropdownButton<FoodUnit>(
                            value: component.unit,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                            items: component.food.allowedUnits.map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit.label, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => component.unit = val);
                                _updateTotalsFromComponents();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 20),
                            onPressed: () {
                              setState(() => _mealComponents.removeAt(index));
                              _updateTotalsFromComponents();
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ],

            if (!_isBuildMode) ...[
              // Macros Grid (Original)
              Row(
                children: [
                  Expanded(
                    child: _buildInputCard(
                      child: TextField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Calories', border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputCard(
                      child: TextField(
                        controller: _proteinController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Protein (g)', border: InputBorder.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInputCard(
                      child: TextField(
                        controller: _carbsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Carbs (g)', border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputCard(
                      child: TextField(
                        controller: _fatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Fat (g)', border: InputBorder.none),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Summary in Build Mode (Read-only view)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Calories', _caloriesController.text, 'kcal'),
                    _buildSummaryItem('Protein', _proteinController.text, 'g'),
                    _buildSummaryItem('Carbs', _carbsController.text, 'g'),
                    _buildSummaryItem('Fat', _fatController.text, 'g'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Micros Accordion
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: ExpansionTile(
                  title: const Text("Additional Nutrients", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _fiberController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Fiber (g)'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _sugarController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Sugar (g)'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _sodiumController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Sodium (mg)'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save to My Meals Toggle (only if not already a template)
            if (!widget.isTemplate && widget.templateMeal == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bookmark_border, size: 20),
                        SizedBox(width: 12),
                        Text("Save to My Meals", style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    Switch(
                      value: _isSavingToMyMeals,
                      onChanged: (v) => setState(() => _isSavingToMyMeals = v),
                      activeColor: Colors.black,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  isEditing ? 'Update' : 'Add Meal',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '0' : value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        Text(unit, style: TextStyle(color: Colors.grey[400], fontSize: 9)),
      ],
    );
  }
}

class ListOperationSuggestion extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;

  const ListOperationSuggestion({super.key, required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(food.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.add_circle_outline, size: 20),
      onTap: onTap,
    );
  }
}
