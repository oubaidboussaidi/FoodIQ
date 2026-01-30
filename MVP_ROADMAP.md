# CalAI MVP Roadmap

## Phase 1: Core Foundation (Completed)
- [x] **Project Setup**: Initialize Flutter app and Python backend.
- [x] **Local Storage**: Setup Hive for storing meals offline.
- [x] **Backend Stub**: Create FastAPI endpoint for `/analyze-meal`.
- [x] **Navigation**: Implement Bottom Navigation (Home, Analytics, Settings).

## Phase 2: Core Features (Completed)
- [x] **Meal Capture**: Implement Camera/Gallery picker.
- [x] **AI Integration**: Connect Flutter to Python backend for calorie estimation.
- [x] **Manual Editing**: Allow users to adjust AI estimates before saving.
- [x] **Dashboard**: Show daily calorie/macro summary.
- [x] **Chart**: Display 7-day calorie history.

## Phase 3: Enhancements (Next Steps)
- [ ] **Real AI**: Replace mock backend with OpenAI GPT-4o or Gemini Vision API.
- [ ] **Data Persistence**: Implement `day_summary` optimization (though raw meal aggregation is fine for MVP).
- [ ] **User Settings**: Add Calorie/Macro goals configuration in Settings.
- [ ] **Better UI/UX**: Add animations, shimmer effects while loading.
- [ ] **Offline Queue**: If offline, save image locally and retry analysis when online.

## Phase 4: Future Scale
- [ ] **Cloud Sync**: Add user authentication (Firebase/Supabase) and sync data.
- [ ] **Barcode Scanner**: Add `flutter_barcode_scanner`.
- [ ] **Social**: Share meals/progress.
