import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'planner_screen.dart';
import 'manage_quests_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../widgets/level_up_dialog.dart';

import 'wear_os/wear_home_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

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

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
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
    );
  }
}
