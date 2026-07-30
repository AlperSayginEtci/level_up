import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_state_manager.dart';
import '../../models/quest.dart';

class WearHomeScreen extends StatefulWidget {
  const WearHomeScreen({Key? key}) : super(key: key);

  @override
  State<WearHomeScreen> createState() => _WearHomeScreenState();
}

class _WearHomeScreenState extends State<WearHomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Wear OS cihazlarda genellikle ekran kısıtlıdır. Siyah arka plan ve basit listeler tercih edilir.
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<PlayerProgressAndStatsController>(
        builder: (context, controller, child) {
          final stats = controller.currentPlayerStats;
          // Sadece günlük ve bitmemiş görevleri göster
          final quests = controller.availableQuests
              .where((q) => !q.isCompleted && (q.isRecurring || q.isSystemQuest))
              .toList();

          return Center(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _buildWearHeader(stats.level, controller.currentRank.title),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "DAILY QUESTS",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (quests.isEmpty)
                  const Center(
                    child: Text(
                      "All clear!",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  )
                else
                  ...quests.map((q) => _buildWearQuestTile(q, controller)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWearHeader(int level, String rank) {
    return Column(
      children: [
        Text(
          "LVL $level",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.blueAccent,
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Text(
          rank,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildWearQuestTile(Quest quest, PlayerProgressAndStatsController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          // Görevi saate tamamla ve telefona bildir
          controller.updateQuestProgress(quest, 1);
          // (Opsiyonel) Özel Wear OS Sync sinyali gönder:
          // SyncService.sendQuestCompletedToPhone(quest.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quest.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                quest.isProgressBased 
                    ? "${quest.currentProgress} / ${quest.targetProgress}" 
                    : "Tap to Complete",
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
              if (quest.isProgressBased) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: quest.targetProgress > 0 ? (quest.currentProgress / quest.targetProgress).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: Colors.black45,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
