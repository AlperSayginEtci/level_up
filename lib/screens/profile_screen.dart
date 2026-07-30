import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final achievements = playerController.achievements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Account'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(context, playerController),
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
                    color: isUnlocked ? Colors.grey[850] : Colors.black45,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isUnlocked ? Colors.amber.withValues(alpha: 0.5) : Colors.transparent,
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
                        isUnlocked ? achievement.description : 'Unlocks at Level ${achievement.requiredLevel}',
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

  Widget _buildProfileHeader(BuildContext context, PlayerProgressAndStatsController controller) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.black45,
          child: Icon(Icons.person, size: 60, color: Colors.blueAccent),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              controller.playerName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [const Shadow(color: Colors.blueAccent, blurRadius: 10)],
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
              onPressed: () {
                _showEditNameDialog(context, controller);
              },
            ),
          ],
        ),
        Text(
          'Total Quests Completed: ${controller.availableQuests.where((q) => q.isCompleted).length}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showEditNameDialog(BuildContext context, PlayerProgressAndStatsController controller) {
    final TextEditingController nameController = TextEditingController(text: controller.playerName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.blueAccent, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Edit Hunter Name', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent, width: 2)),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  controller.updatePlayerProfile(newName);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
