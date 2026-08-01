import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'planner_screen.dart';
import 'manage_quests_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../widgets/level_up_dialog.dart';

import 'wear_os/wear_home_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/system_background.dart';
import '../services/update_service.dart';
import '../widgets/system_update_dialog.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkSystemUpdate();
  }

  Future<void> _checkSystemUpdate() async {
    // Biraz bekle ki ana ekran tam yüklensin
    await Future.delayed(const Duration(seconds: 2));
    final updateInfo = await UpdateService.checkForUpdates();
    if (updateInfo != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SystemUpdateDialog(updateInfo: updateInfo),
      );
    }
  }


  final List<Widget> _pages = [
    const HomeScreen(),
    const PlannerScreen(),
    const ProfileScreen(),
    const ManageQuestsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Wear OS Control
    final size = MediaQuery.of(context).size;
    if (size.width < 300 && size.height < 300) {
      return const WearHomeScreen();
    }

    // Listen for level up
    final playerController = context.watch<PlayerProgressAndStatsController>();
    if (playerController.hasLeveledUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        // Göster ve bayrağı temizle ki tekrar tekrar açılmasın
        playerController.clearLevelUpFlag();
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => LevelUpDialog(stats: playerController.currentPlayerStats),
        );
      });
    }

    final isShadowMonarch = playerController.isShadowMonarchThemeActive;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SystemBackground(
        isShadowMonarch: isShadowMonarch,
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          border: Border(
            top: BorderSide(
              color: AppTheme.getPrimaryColor(playerController.isShadowMonarchThemeActive).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.getPrimaryColor(playerController.isShadowMonarchThemeActive).withValues(alpha: 0.15),
              blurRadius: 15,
              offset: const Offset(0, -3),
            )
          ]
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.getPrimaryColor(playerController.isShadowMonarchThemeActive),
          unselectedItemColor: Colors.grey[600],
          selectedIconTheme: IconThemeData(
            shadows: [
              Shadow(
                color: AppTheme.getPrimaryColor(playerController.isShadowMonarchThemeActive),
                blurRadius: 12,
              )
            ]
          ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Quests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.military_tech),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Manage',
          ),
        ],
      ),
    ),
    );
  }
}
