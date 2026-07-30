import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_state_manager.dart';
import '../models/quest.dart';
import '../widgets/stat_radar_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final stats = playerController.currentPlayerStats;
    final todayQuests = playerController.availableQuests; // We will filter this later for "today"
    
    final double expProgress = stats.exp / stats.requiredExp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LevelUp - Player Status'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section: Avatar, Level, and Exp ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${stats.level}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurpleAccent,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playerController.currentRank.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: expProgress,
                            minHeight: 12,
                            backgroundColor: Colors.grey[850],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurpleAccent),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.exp} / ${stats.requiredExp} EXP',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // --- Base Attributes/Stats Section ---
              Text(
                'Base Attributes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildStatDisplayRow('Strength (STR)', stats.strength),
                        _buildStatDisplayRow('Vitality (VIT)', stats.vitality),
                        _buildStatDisplayRow('Agility (AGI)', stats.agility),
                        _buildStatDisplayRow('Intelligence (INT)', stats.intelligence),
                        _buildStatDisplayRow('Sense (SEN)', stats.sense),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: StatRadarChart(stats: stats),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // --- Daily Quests Section ---
              Text(
                'Daily Quests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              if (todayQuests.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No quests available for today.', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayQuests.length,
                  itemBuilder: (context, index) {
                    final quest = todayQuests[index];
                    return _buildQuestCard(context, quest, playerController);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatDisplayRow(String statName, int statValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(statName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(
            statValue.toString(),
            style: const TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context, 
    Quest quest, 
    PlayerProgressAndStatsController controller,
  ) {
    final isDone = quest.isCompleted;
    final cardColor = isDone ? Colors.green.withValues(alpha: 0.2) : Colors.grey[850];
    final isCalories = quest.id == 'sys_calories';
    final isSteps = quest.id == 'sys_steps';

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              quest.description,
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),

            if (quest.subQuests.isNotEmpty)
              _buildSubQuestsList(context, quest, controller)
            else if (quest.isProgressBased)
              Builder(builder: (context) {
                final isLimitQuest = quest.isEndOfDayEvaluation;
                final limit = quest.maxLimit ?? quest.targetProgress;
                final isExceeded = isLimitQuest && quest.currentProgress > limit;
                
                String progressText = 'Progress: ${quest.currentProgress} / ${quest.targetProgress}';
                if (isLimitQuest) {
                  if (isExceeded) {
                    progressText = 'LIMIT EXCEEDED: ${quest.currentProgress} / $limit';
                  } else {
                    progressText = 'Current: ${quest.currentProgress} (Max: $limit)';
                  }
                }
                
                Color progressColor = isDone ? Colors.green : Colors.deepPurpleAccent;
                if (isLimitQuest) {
                  progressColor = isExceeded ? Colors.redAccent : Colors.blueAccent;
                }

                double progressRatio = quest.currentProgress / (isLimitQuest ? limit : quest.targetProgress);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          progressText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExceeded ? Colors.redAccent : Colors.white,
                          ),
                        ),
                        if (!isSteps) // Hide manual add button for steps
                          IconButton(
                            onPressed: () {
                              if (isCalories) {
                                _showCalorieInputDialog(context, quest, controller);
                              } else {
                                // Default manual increment (e.g., Water glasses)
                                controller.updateQuestProgress(quest, 1);
                              }
                            },
                            icon: Icon(
                              Icons.add_circle, 
                              color: isExceeded ? Colors.redAccent : Colors.deepPurpleAccent,
                            ),
                            iconSize: 32,
                          ),
                        if (!isDone && isSteps)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.directions_walk, color: Colors.deepPurpleAccent),
                          )
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressRatio.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                    if (isLimitQuest)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          '* Evaluated at the end of the day',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                );
              })

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

  Widget _buildSubQuestsList(BuildContext context, Quest quest, PlayerProgressAndStatsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.grey),
        const SizedBox(height: 8),
        Text(
          'Sub-Quests (Chain)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...quest.subQuests.map((subQuest) {
          final isSubDone = subQuest.isCompleted;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  isSubDone ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSubDone ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subQuest.title,
                    style: TextStyle(
                      decoration: isSubDone ? TextDecoration.lineThrough : null,
                      color: isSubDone ? Colors.grey : Colors.white,
                    ),
                  ),
                ),
                if (!isSubDone)
                  ElevatedButton(
                    onPressed: () {
                      controller.completeSubQuestAndRewardPlayer(quest, subQuest);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(0, 32),
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                    child: const Text('Do'),
                  )
                else
                  Text(
                    '+${subQuest.rewardExp} EXP',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  )
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showCalorieInputDialog(BuildContext context, Quest quest, PlayerProgressAndStatsController controller) {
    final TextEditingController calController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Calories'),
          content: TextField(
            controller: calController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 350',
              suffixText: 'kcal',
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
                final val = int.tryParse(calController.text);
                if (val != null && val > 0) {
                  controller.updateQuestProgress(quest, val);
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
