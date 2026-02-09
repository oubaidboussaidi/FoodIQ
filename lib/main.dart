import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/storage_service.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'widgets/intelligent_loader.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}


class _BootstrapAppState extends State<BootstrapApp> {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _storageService.init();
    await _notificationService.init();
    
    // Check for daily logic (Morning motivation)
    _notificationService.checkMorningMotivation();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: IntelligentLoader(),
          );
        }

        if (snapshot.hasError) {
          return Directionality(
             textDirection: TextDirection.ltr,
             child: ColoredBox(
               color: Colors.white,
               child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error initializing app:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 14, decoration: TextDecoration.none),
                  ),
                ),
              ),
             ),
          );
        }

        return Provider<StorageService>.value(
          value: _storageService,
          child: const MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodIQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light, 
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
        primaryColor: const Color(0xFF4F46E5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4F46E5),
          secondary: Color(0xFF03DAC6),
          surface: Colors.white,
          onSurface: Color(0xFF111827),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(bodyColor: const Color(0xFF111827), displayColor: const Color(0xFF111827)),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
