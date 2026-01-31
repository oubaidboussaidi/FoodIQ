import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/meal.dart';
import '../services/storage_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _calController = TextEditingController();
  final TextEditingController _pController = TextEditingController();
  final TextEditingController _cController = TextEditingController();
  final TextEditingController _fController = TextEditingController();

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo != null) {
        setState(() {
          _image = File(photo.path);
          _isLoading = true;
        });
        await _analyzeImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _analyzeImage() async {
    try {
      final api = ApiService();
      // Simulate network delay for effect
      await Future.delayed(const Duration(seconds: 2));
      
      final result = await api.analyzeMeal(_image!);
      
      setState(() {
        _isLoading = false;
        
        // Populate controllers
        _nameController.text = result['name'] ?? 'Unknown Meal';
        _calController.text = (result['calories'] ?? 0).toString();
        _pController.text = (result['protein'] ?? 0).toString();
        _cController.text = (result['carbs'] ?? 0).toString();
        _fController.text = (result['fat'] ?? 0).toString();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error analyzing: $e')));
      }
    }
  }

  Future<void> _saveMeal() async {
      if (_formKey.currentState!.validate()) {
          final meal = Meal(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameController.text,
              calories: int.tryParse(_calController.text) ?? 0,
              protein: int.tryParse(_pController.text) ?? 0,
              carbs: int.tryParse(_cController.text) ?? 0,
              fat: int.tryParse(_fController.text) ?? 0,
              imagePath: _image!.path,
              timestamp: DateTime.now(),
          );
          
          final storage = Provider.of<StorageService>(context, listen: false);
          await storage.addMeal(meal);
          
          if (mounted) {
              Navigator.pop(context);
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
        return Scaffold(
            appBar: AppBar(
              title: const Text('Add Meal'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                         Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                         ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 250,
                          height: 50,
                          child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                              onPressed: () => _captureImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 250,
                          height: 50,
                          child: OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choose from Gallery'),
                              onPressed: () => _captureImage(ImageSource.gallery),
                          ),
                        ),
                    ],
                ),
            ),
        );
    }
    
    return Scaffold(
        appBar: AppBar(title: const Text('Meal Details')),
        body: _isLoading 
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Analyzing meal with AI...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                    key: _formKey,
                    child: Column(
                        children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_image!, height: 250, width: double.infinity, fit: BoxFit.cover),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Meal Name', 
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.restaurant),
                                ),
                                validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 15),
                            Row(
                                children: [
                                    Expanded(child: _buildNumField(_calController, 'Calories', Icons.local_fire_department, Colors.orange)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildNumField(_pController, 'Protein (g)', Icons.fitness_center, Colors.blue)),
                                ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                                children: [
                                    Expanded(child: _buildNumField(_cController, 'Carbs (g)', Icons.bakery_dining, Colors.brown)),
                                    const SizedBox(width: 10),
                                    Expanded(child: _buildNumField(_fController, 'Fat (g)', Icons.opacity, Colors.yellow)),
                                ],
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                    onPressed: _saveMeal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor, 
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Save Meal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
    );
  }
  
  Widget _buildNumField(TextEditingController controller, String label, IconData icon, Color color) {
      return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label, 
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon, color: color),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
      );
  }
}
