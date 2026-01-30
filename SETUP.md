# Setup Instructions

## Prerequisites
- Flutter SDK installed.
- Python 3.x installed.

## 1. Backend Setup
The backend handles the "AI" analysis (currently mocked).

1. Navigate to the `backend` folder:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the server:
   ```bash
   python main.py
   ```
   *The server will run at http://0.0.0.0:8000*

## 2. Flutter App Setup

1. Navigate to the root folder (where `pubspec.yaml` is).
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. **Important**: Generate Hive Adapters. This is required for local storage to work.
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Run the app:
   - **Android Emulator**: `flutter run` (Backend is pre-configured for `10.0.2.2`).
   - **iOS Simulator**: `flutter run` (Backend is pre-configured for `localhost`).
   - **Physical Device**: Update `lib/services/api_service.dart` with your PC's IP address.

## Troubleshooting
- If you see errors about `MealAdapter` or `part 'meal.g.dart'`, run step 3 again.
- If the image upload fails, ensure the backend is running and the IP address in `api_service.dart` is correct.
