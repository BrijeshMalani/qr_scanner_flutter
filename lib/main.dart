import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/home_screen.dart';
import 'services/history_service.dart';
import 'services/service_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final historyService = HistoryService(prefs);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<HistoryService>.value(value: historyService),
      ],
      child: const QRScannerApp(),
    ),
  );
}

class QRScannerApp extends StatelessWidget {
  const QRScannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ServiceProvider(
      historyService: context.read<HistoryService>(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'QR & Barcode Scanner',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          initialRoute: '/',
          routes: {
            '/': (context) => SplashScreen(),
            '/onboarding': (context) => OnboardingScreen(),
            '/home': (context) => MainScreen(),
            '/scanner': (context) => ScannerScreen(),
            '/home_screen': (context) => HomeScreen(),
          },
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(child: Text('Main QR Scanner Screen Placeholder')),
    );
  }
}
