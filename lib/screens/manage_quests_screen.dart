import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../models/quest.dart';
import 'create_quest_screen.dart';
import '../theme/app_theme.dart';

class ManageQuestsScreen extends StatelessWidget {
  const ManageQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final quests = playerController.availableQuests;

    // Ayırmak için iki liste yapalım
    final systemQuests = quests.where((q) => q.isSystemQuest).toList();
    final customQuests = quests.where((q) => !q.isSystemQuest).toList();
    final isShadowMonarch = playerController.isShadowMonarchThemeActive;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Manage Quests', style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'System Quests (Non-deletable)', isShadowMonarch),
          ...systemQuests.map((q) => _buildQuestListTile(context, q, playerController, isShadowMonarch)),
          
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Custom Quests', isShadowMonarch),
          if (customQuests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No custom quests yet.\nTap the + button to create one!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ...customQuests.map((q) => _buildQuestListTile(context, q, playerController, isShadowMonarch)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateQuestScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Quest', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.getPrimaryColor(isShadowMonarch),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isShadowMonarch) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 18, fontWeight: FontWeight.bold).copyWith(
              color: AppTheme.getPrimaryColor(isShadowMonarch),
            ),
      ),
    );
  }

  Widget _buildQuestListTile(BuildContext context, Quest quest, PlayerProgressAndStatsController controller, bool isShadowMonarch) {
    return Container(
      decoration: AppTheme.systemCardDecoration(isShadowMonarch),
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
    final isShadowMonarch = controller.isShadowMonarchThemeActive;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.getDarkColor(isShadowMonarch),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.getPrimaryColor(isShadowMonarch)),
        ),
        title: Text('Delete Quest', style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${quest.title}"?', style: const TextStyle(color: Colors.white)),
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
