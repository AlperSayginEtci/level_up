import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_layout.dart';
import 'screens/onboarding_screen.dart';
import 'providers/player_state_manager.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: Consumer<PlayerProgressAndStatsController>(
        builder: (context, controller, child) {
          if (controller.isNewPlayer) {
            return const OnboardingScreen();
          }
          return const MainLayout();
        },
      ),
    );
  }
}
