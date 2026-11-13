import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/database/local_db_service.dart';
import 'core/network/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/profile_setup_screen.dart';
import 'features/auth/presentation/signup_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/navigation/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Android system UI styling for deep obsidian theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize offline SQLite database
  try {
    await LocalDbService.instance.database;
  } catch (_) {}

  // Initialize notifications
  try {
    await NotificationService.instance.initialize();
  } catch (_) {}

  // Initialize Supabase (with offline fallback if unconfigured)
  try {
    await SupabaseConfig.initialize();
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: GrowthOsApp(),
    ),
  );
}

class GrowthOsApp extends StatelessWidget {
  const GrowthOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GROWTH OS',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const MainScaffold(),
      },
    );
  }
}

