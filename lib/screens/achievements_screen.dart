import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/player_state_manager.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';
import '../widgets/system_background.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final achievements = playerController.achievements;
    final isShadowMonarch = playerController.isShadowMonarchThemeActive;
    
    final unlocked = achievements.where((a) => a.isUnlocked).toList().reversed.toList();
    final locked = achievements.where((a) => !a.isUnlocked).toList();

    return SystemBackground(
      isShadowMonarch: isShadowMonarch,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        title: Text('Hunter Ranks', style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 20, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (unlocked.isNotEmpty) ...[
            Text(
              'Unlocked Ranks',
              style: AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            ...unlocked.map((a) => _buildAchievementCard(a, true, isShadowMonarch)),
            const SizedBox(height: 24),
          ],
          if (locked.isNotEmpty) ...[
            Text(
              'Locked Ranks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 12),
            ...locked.map((a) => _buildAchievementCard(a, false, isShadowMonarch)),
          ]
        ],
      ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked, bool isShadowMonarch) {
    return Container(
      decoration: isUnlocked 
          ? AppTheme.systemCardDecoration(isShadowMonarch)
          : BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isUnlocked ? Icons.stars : Icons.lock,
              color: isUnlocked ? AppTheme.getPrimaryColor(isShadowMonarch) : Colors.grey[700],
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: isUnlocked 
                        ? AppTheme.systemTextStyle(isShadowMonarch, fontWeight: FontWeight.bold, fontSize: 18)
                        : const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isUnlocked && achievement.unlockedDate != null)
                    Text(
                      'Unlocked: ${DateFormat('MMM dd, yyyy').format(achievement.unlockedDate!)}',
                      style: TextStyle(color: AppTheme.getPrimaryColor(isShadowMonarch).withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  else if (!isUnlocked)
                    Text(
                      'Required Level: ${achievement.requiredLevel}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
