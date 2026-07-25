import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../models/quest.dart';
import 'create_quest_screen.dart';

class ManageQuestsScreen extends StatelessWidget {
  const ManageQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final quests = playerController.availableQuests;

    // Ayırmak için iki liste yapalım
    final systemQuests = quests.where((q) => q.isSystemQuest).toList();
    final customQuests = quests.where((q) => !q.isSystemQuest).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quests'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'System Quests (Non-deletable)'),
          ...systemQuests.map((q) => _buildQuestListTile(context, q, playerController)),
          
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Custom Quests'),
          if (customQuests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No custom quests yet.\nTap the + button to create one!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ...customQuests.map((q) => _buildQuestListTile(context, q, playerController)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateQuestScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Quest'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent,
            ),
      ),
    );
  }

  Widget _buildQuestListTile(BuildContext context, Quest quest, PlayerProgressAndStatsController controller) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(quest.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          quest.isSystemQuest 
              ? 'System Quest • Target: ${quest.targetProgress}'
              : 'Rank ${quest.difficulty.name} • ${quest.rewardExp} EXP',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateQuestScreen(existingQuest: quest)),
                );
              },
            ),
            if (!quest.isSystemQuest)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  _showDeleteConfirmDialog(context, quest, controller);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Quest quest, PlayerProgressAndStatsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quest'),
        content: Text('Are you sure you want to delete "${quest.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteQuest(quest.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
