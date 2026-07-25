import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_layout.dart';
import 'providers/player_state_manager.dart';

void main() {
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
      home: const MainLayout(),
    );
  }
}
