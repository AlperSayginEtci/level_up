import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final achievements = playerController.achievements;
    final stats = playerController.currentPlayerStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hunter Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievements / Ranks Section
              Text(
                'Hunter Ranks & Titles',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final isUnlocked = achievement.isUnlocked;
                  
                  return Card(
                    color: isUnlocked ? Colors.grey[850] : Colors.grey[900]?.withOpacity(0.5),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isUnlocked ? Colors.amber.withOpacity(0.5) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        isUnlocked ? Icons.workspace_premium : Icons.lock,
                        color: isUnlocked ? Colors.amber : Colors.grey[700],
                        size: 32,
                      ),
                      title: Text(
                        achievement.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.white : Colors.grey[600],
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Text(
                        isUnlocked ? achievement.description : 'Unlocks at Level \${achievement.requiredLevel}',
                        style: TextStyle(
                          color: isUnlocked ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
