import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_layout.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/wear_sync_screen.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/player_state_manager.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await DatabaseService.init();
  await SyncService.init();

  runApp(
    ChangeNotifierProvider(
      create: (context) => PlayerProgressAndStatsController(),
      child: const LevelUpApp(),
    ),
  );
}

class LevelUpApp extends StatelessWidget {
  const LevelUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LevelUp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness:
              Brightness.dark, // A dark theme fits the Solo Leveling aesthetic
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          // If the user is not logged in, show LoginScreen
          if (!snapshot.hasData) {
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 300) {
                  // Wear OS device: show sync screen instead of login
                  return const WearSyncScreen();
                }
                return const LoginScreen();
              },
            );
          }
          
          // User is logged in, check if they are a new player (needs onboarding)
          return Consumer<PlayerProgressAndStatsController>(
            builder: (context, controller, child) {
              if (controller.isNewPlayer) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 300) {
                      return const WearSyncScreen();
                    }
                    return const OnboardingScreen();
                  },
                );
              }
              return const MainLayout();
            },
          );
        },
      ),
    );
  }
}
