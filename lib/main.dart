import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upgrader/upgrader.dart';
import 'controllers/purchase_controller.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Ensure Flutter engine is initialized before calling platform channels (like database path)
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation for scanner stability
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://arjnxoergteitvdlavdm.supabase.co',
    anonKey: 'sb_publishable_xbXUqlKqEfZQneBnSTA4Pg_Mpd1Z-e6',
  );

  // Create state controller instance
  final purchaseController = PurchaseController();

  runApp(MyApp(controller: purchaseController));
}

class MyApp extends StatelessWidget {
  final PurchaseController controller;

  const MyApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Organiza Compras',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Default to a gorgeous dark UI
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          secondary: Color(0xFF2ECC71), // Hex emerald green
          surface: Color(0xFF16161A),
          onSurface: Colors.white70,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0E17),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF16161A),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),
      home: UpgradeAlert(
        upgrader: Upgrader(
          messages: UpgraderMessages(code: 'pt'), // Forçar mensagens em português
        ),
        child: SplashScreen(controller: controller),
      ),
    );
  }
}
