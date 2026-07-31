import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/system_background.dart';

class QuestHistoryScreen extends StatelessWidget {
  const QuestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final historyQuests = playerController.availableQuests.where((q) => q.completionCount > 0).toList();
    final isShadowMonarch = playerController.isShadowMonarchThemeActive;

    return SystemBackground(
      isShadowMonarch: isShadowMonarch,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        title: Text('Quest Records', style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 20, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: historyQuests.isEmpty
          ? const Center(
              child: Text(
                'No quest records yet. Complete some quests!',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: historyQuests.length,
              itemBuilder: (context, index) {
                final quest = historyQuests[index];

                return Container(
                  decoration: AppTheme.systemCardDecoration(isShadowMonarch),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(
                      quest.isSystemQuest ? Icons.settings_system_daydream : Icons.task_alt,
                      color: AppTheme.getPrimaryColor(isShadowMonarch),
                      size: 32,
                    ),
                    title: Text(quest.title, style: AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(quest.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${quest.completionCount}',
                          style: TextStyle(
                            color: AppTheme.getPrimaryColor(isShadowMonarch),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            shadows: [Shadow(color: AppTheme.getPrimaryColor(isShadowMonarch), blurRadius: 4)]
                          ),
                        ),
                        Text(
                          'Times',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
