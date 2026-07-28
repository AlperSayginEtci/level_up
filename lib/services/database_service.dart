import 'package:hive_flutter/hive_flutter.dart';
import 'package:level_up/models/achievement.dart';
import 'package:level_up/models/player_stats.dart';
import 'package:level_up/models/quest.dart';

class DatabaseService {
  static const String questsBoxName = 'questsBox';
  static const String statsBoxName = 'statsBox';
  static const String achievementsBoxName = 'achievementsBox';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(QuestDifficultyAdapter());
    Hive.registerAdapter(StatTypeAdapter());
    Hive.registerAdapter(SubQuestAdapter());
    Hive.registerAdapter(QuestAdapter());
    Hive.registerAdapter(PlayerStatsAdapter());
    Hive.registerAdapter(AchievementAdapter());

    // Open Boxes
    await Hive.openBox<Quest>(questsBoxName);
    await Hive.openBox<PlayerStats>(statsBoxName);
    await Hive.openBox<Achievement>(achievementsBoxName);
  }

  // --- Quests ---
  static Box<Quest> get questsBox => Hive.box<Quest>(questsBoxName);

  static Future<void> saveQuest(Quest quest) async {
    await questsBox.put(quest.id, quest);
  }

  static Future<void> deleteQuest(String id) async {
    await questsBox.delete(id);
  }

  static List<Quest> getAllQuests() {
    return questsBox.values.toList();
  }

  // --- Player Stats ---
  static Box<PlayerStats> get statsBox => Hive.box<PlayerStats>(statsBoxName);

  static Future<void> savePlayerStats(PlayerStats stats) async {
    await statsBox.put('current_stats', stats);
  }

  static PlayerStats getPlayerStats() {
    // Return default stats if none found
    return statsBox.get('current_stats') ?? PlayerStats();
  }

  // --- Achievements ---
  static Box<Achievement> get achievementsBox => Hive.box<Achievement>(achievementsBoxName);

  static Future<void> saveAchievement(Achievement achievement) async {
    await achievementsBox.put(achievement.id, achievement);
  }

  static List<Achievement> getAllAchievements() {
    return achievementsBox.values.toList();
  }
}
