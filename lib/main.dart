import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/tracking_provider.dart';
import 'screens/login_screen.dart';
import 'screens/tracking_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient: apiClient)),
        ChangeNotifierProvider(create: (_) => TrackingProvider(apiClient: apiClient)),
      ],
      child: const GpsTrackerApp(),
    ),
  );
}

class GpsTrackerApp extends StatelessWidget {
  const GpsTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TransitTrack - GPS Vehicle Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Times New Roman',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Times New Roman',
        ),
        primaryTextTheme: ThemeData.light().primaryTextTheme.apply(
          fontFamily: 'Times New Roman',
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo.shade700,
          secondary: Colors.teal.shade600,
        ),
        scaffoldBackgroundColor: Colors.grey.shade100,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const TrackingScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
