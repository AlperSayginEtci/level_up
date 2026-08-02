import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/player_state_manager.dart';
import '../models/quest.dart';
import '../widgets/stat_radar_chart.dart';
import '../theme/app_theme.dart';
import '../services/ai_nutrition_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerProgressAndStatsController>();
    final stats = playerController.currentPlayerStats;
    final todayQuests = playerController.availableQuests; // We will filter this later for "today"
    
    final double expProgress = stats.exp / stats.requiredExp;
    final isShadowMonarch = playerController.isShadowMonarchThemeActive;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('LevelUp - Player Status', style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 20, fontWeight: FontWeight.bold)),
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
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blueGrey,
                    backgroundImage: playerController.profileImageBase64 != null
                        ? MemoryImage(base64Decode(playerController.profileImageBase64!))
                        : null,
                    child: playerController.profileImageBase64 == null
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${stats.level}',
                          style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          playerController.currentRank.title,
                          style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: expProgress,
                            minHeight: 12,
                            backgroundColor: Colors.black45,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.getPrimaryColor(isShadowMonarch)),
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
                style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildStatDisplayRow('Strength (STR)', stats.strength, isShadowMonarch),
                        _buildStatDisplayRow('Vitality (VIT)', stats.vitality, isShadowMonarch),
                        _buildStatDisplayRow('Agility (AGI)', stats.agility, isShadowMonarch),
                        _buildStatDisplayRow('Intelligence (INT)', stats.intelligence, isShadowMonarch),
                        _buildStatDisplayRow('Sense (SEN)', stats.sense, isShadowMonarch),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: StatRadarChart(stats: stats, isShadowMonarch: isShadowMonarch),
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
                style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 22, fontWeight: FontWeight.bold),
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
                    return _buildQuestCard(context, quest, playerController, isShadowMonarch);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatDisplayRow(String statName, int statValue, bool isShadowMonarch) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(statName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(
            statValue.toString(),
            style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context, 
    Quest quest, 
    PlayerProgressAndStatsController controller,
    bool isShadowMonarch,
  ) {
    final isDone = quest.isCompleted;
    final isNutrition = quest.id == 'sys_nutrition' || quest.id == 'sys_calories';
    final isSteps = quest.id == 'sys_steps';

    return Container(
      decoration: isDone 
          ? AppTheme.systemCardDecoration(isShadowMonarch).copyWith(
              color: Colors.green.withValues(alpha: 0.15),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            )
          : AppTheme.systemCardDecoration(isShadowMonarch),
      margin: const EdgeInsets.only(bottom: 16.0),
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
                    style: AppTheme.systemTextStyle(isShadowMonarch, fontSize: 18, fontWeight: FontWeight.bold).copyWith(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: AppTheme.badgeDecoration(isShadowMonarch),
                  child: Text(
                    'Rank ${quest.difficulty.name}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.getPrimaryColor(isShadowMonarch)),
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
              _buildSubQuestsList(context, quest, controller, isShadowMonarch)
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
                              if (isNutrition) {
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
                  icon: Icon(isDone ? Icons.check : Icons.play_arrow, color: Colors.white),
                  label: const Text('Complete Quest', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone ? Colors.green : AppTheme.getPrimaryColor(isShadowMonarch),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubQuestsList(BuildContext context, Quest quest, PlayerProgressAndStatsController controller, bool isShadowMonarch) {
    bool isNutrition = quest.id == 'sys_nutrition' || quest.id == 'sys_calories';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.grey),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isNutrition ? 'Macros & Calories' : 'Sub-Quests (Chain)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (isNutrition && !quest.isCompleted)
              ElevatedButton.icon(
                onPressed: () => _handleAiFoodScan(context, controller, quest),
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                label: const Text('Scan Food', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.getPrimaryColor(isShadowMonarch),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 36),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (isNutrition) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calories', style: TextStyle(color: Colors.white)),
              Text('${quest.currentProgress} / ${quest.targetProgress}', style: TextStyle(color: quest.isCompleted ? Colors.green : Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (quest.currentProgress / quest.targetProgress).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[700],
            valueColor: AlwaysStoppedAnimation<Color>(quest.currentProgress > (quest.maxLimit ?? quest.targetProgress) ? Colors.redAccent : Colors.deepPurpleAccent),
          ),
          const SizedBox(height: 12),
        ],

        ...quest.subQuests.map((subQuest) {
          final isSubDone = subQuest.isCompleted;
          
          if (isNutrition) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text(subQuest.title, style: TextStyle(color: isSubDone ? Colors.green : Colors.white)),
                         Text('${subQuest.currentProgress} / ${subQuest.targetProgress}', style: TextStyle(color: isSubDone ? Colors.green : Colors.grey[400])),
                       ]
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (subQuest.currentProgress / subQuest.targetProgress).clamp(0.0, 1.0),
                      backgroundColor: Colors.grey[700],
                      valueColor: AlwaysStoppedAnimation<Color>(isSubDone ? Colors.green : Colors.amber),
                    ),
                  ],
                ),
              );
          }
          
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
                      backgroundColor: AppTheme.getPrimaryColor(isShadowMonarch),
                    ),
                    child: const Text('Do', style: TextStyle(color: Colors.white)),
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

  Future<void> _handleAiFoodScan(BuildContext context, PlayerProgressAndStatsController controller, Quest quest) async {
    if (controller.geminiApiKey == null || controller.geminiApiKey!.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please configure your Gemini API Key in Profile Settings first!'), backgroundColor: Colors.redAccent));
       return;
    }
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile == null) return;
    
    // Show Loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[900],
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('System Scanning...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Analyzing nutritional values...', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ),
      );
    }
    
    NutritionResult? result;
    try {
      result = await AiNutritionService.analyzeFoodImage(controller.geminiApiKey!, File(pickedFile.path));
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('API Error', style: TextStyle(color: Colors.redAccent)),
            content: SingleChildScrollView(child: Text(e.toString(), style: const TextStyle(color: Colors.white))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
            ],
            backgroundColor: Colors.grey[900],
          ),
        );
      }
      return;
    }
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to analyze food. No result returned.'), backgroundColor: Colors.redAccent));
        return;
      }
      
      // Show Result Confirmation
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.deepPurpleAccent)),
          title: Text('Scan Complete: ${result!.foodName}', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calories: ${result!.calories} kcal', style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Protein: ${result!.protein}g', style: const TextStyle(color: Colors.white)),
              Text('Carbs: ${result!.carbs}g', style: const TextStyle(color: Colors.white)),
              Text('Fat: ${result!.fat}g', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              const Text('Add these values to your daily goals?', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Discard', style: TextStyle(color: Colors.redAccent))),
            ElevatedButton(
              onPressed: () {
                controller.addNutritionProgress(result!.calories, result!.protein, result!.carbs, result!.fat);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nutrition data absorbed!'), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              child: const Text('Absorb Stats', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    }
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
