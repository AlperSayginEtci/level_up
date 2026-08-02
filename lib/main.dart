import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/main_layout.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/wear_sync_screen.dart';
import 'screens/wear_os/wear_home_screen.dart';
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

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    try {
      final quests = DatabaseService.getAllQuests().map((q) => q.toMap()).toList();
      final stats = DatabaseService.getPlayerStats().toMap();
      final achievements = DatabaseService.getAllAchievements().map((a) => a.toMap()).toList();
      final prefs = await SharedPreferences.getInstance();
      final profileData = {
        'player_name': prefs.getString('player_name'),
        'profile_image_base64': prefs.getString('profile_image_base64'),
        'player_age': prefs.getInt('player_age'),
        'player_weight': prefs.getDouble('player_weight'),
        'player_height': prefs.getDouble('player_height'),
        'gemini_api_key': prefs.getString('gemini_api_key'),
        'total_completed_quests': prefs.getInt('total_completed_quests'),
      };
      final backup = {
        'quests': quests,
        'stats': stats,
        'achievements': achievements,
        'profile': profileData,
      };
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/level_up_rescue.json');
      await file.writeAsString(jsonEncode(backup));
      debugPrint('RESCUE BACKUP SAVED TO: ${file.path}');
    } catch (e) {
      debugPrint('Rescue backup failed: $e');
    }
  }

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
      home: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 300) {
            // WEAR OS DEVICE ROUTING
            return Consumer<PlayerProgressAndStatsController>(
              builder: (context, controller, child) {
                // Eğer saatte hiç veri yoksa (Level 1, Quest yok), telefonla eşitleme ekranını göster.
                // Not: Saat uygulamasının yerel Hive veritabanı boşsa demek bu.
                if (controller.currentPlayerStats.level == 1 && controller.availableQuests.isEmpty) {
                  return const WearSyncScreen();
                }
                return const WearHomeScreen();
              },
            );
          }
          
          // PHONE / PC ROUTING
          return StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoginScreen();
              }
              
              return Consumer<PlayerProgressAndStatsController>(
                builder: (context, controller, child) {
                  if (controller.isNewPlayer) {
                    return const OnboardingScreen();
                  }
                  return const MainLayout();
                },
              );
            },
          );
        },
      ),
    );
  }
}
