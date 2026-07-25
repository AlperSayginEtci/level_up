import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../models/quest.dart';

class QuestBoardScreen extends StatelessWidget {
  const QuestBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final quests = playerController.availableQuests;

    // TODO: İleride burada sadece "Bugün" (activeDays) yapılması gereken görevleri filtreleyebiliriz.
    // Şimdilik test amaçlı oluşturduğumuz tüm görevleri gösteriyoruz.
    final todayQuests = quests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planner (Quests)'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: todayQuests.isEmpty
          ? const Center(
              child: Text(
                'No quests available for today.\nRest well, Player.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: todayQuests.length,
              itemBuilder: (context, index) {
                final quest = todayQuests[index];
                return _buildQuestCard(context, quest, playerController);
              },
            ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context, 
    Quest quest, 
    PlayerProgressAndStatsController controller,
  ) {
    // Determine the color based on completion
    final isDone = quest.isCompleted;
    final cardColor = isDone ? Colors.green.withValues(alpha: 0.2) : Colors.grey[850];

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Rank
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quest.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rank ${quest.difficulty.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              quest.description,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),

            // Progress Bar (if applicable) or Simple Button
            if (quest.isProgressBased)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: ${quest.currentProgress} / ${quest.targetProgress}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (!isDone)
                        IconButton(
                          onPressed: () {
                            // Controller üzerinden ilerleme kaydet
                            controller.updateQuestProgress(quest, 1);
                          },
                          icon: const Icon(Icons.add_circle, color: Colors.deepPurpleAccent),
                          iconSize: 32,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: quest.currentProgress / quest.targetProgress,
                    backgroundColor: Colors.grey[700],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? Colors.green : Colors.deepPurpleAccent,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: isDone
                      ? null
                      : () {
                          controller.completeSpecificQuestAndRewardPlayer(quest);
                        },
                  icon: Icon(isDone ? Icons.check : Icons.play_arrow),
                  label: Text(isDone ? 'Completed' : 'Complete Quest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone ? Colors.green : Colors.deepPurpleAccent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
