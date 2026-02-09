# Architecture & Screen Breakdown

## Technology Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Python (FastAPI) - Stateless, AI Inference only.
- **Local Database**: Hive (NoSQL, fast, offline-first).
- **State Management**: Provider + ValueListenableBuilder (Reactive UI).

## Directory Structure
```
lib/
├── models/
│   └── meal.dart       # Hive Object (Name, Cals, Macros, ImagePath)
├── screens/
│   ├── main_screen.dart      # Bottom Navigation Logic
│   ├── home_screen.dart      # Daily Summary & List
│   ├── analytics_screen.dart # 7-Day Bar Chart
│   ├── settings_screen.dart  # Data Management
│   └── camera_screen.dart    # Image Capture & Edit Form
├── services/
│   ├── api_service.dart      # HTTP calls to Python Backend
│   └── storage_service.dart  # Hive Box Wrappers
└── main.dart                 # App Entry & Theme
```

## Data Schema (Hive)
**Box Name:** `meals_box`
**Model:** `Meal`
- `id` (String): Unique ID (Timestamp based)
- `name` (String): Meal name
- `calories` (int)
- `protein` (int)
- `carbs` (int)
- `fat` (int)
- `imagePath` (String): Local path to image file
- `timestamp` (DateTime): Date of meal

## Backend API Contract
**Endpoint:** `POST /analyze-meal`
**Request:** `multipart/form-data` with key `file` (image).
**Response (JSON):**
```json
{
  "name": "Grilled Chicken",
  "calories": 450,
  "protein": 40,
  "carbs": 10,
  "fat": 20
}
```
