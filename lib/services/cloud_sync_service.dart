import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:level_up/services/database_service.dart';
import 'package:level_up/models/quest.dart';
import 'package:level_up/models/player_stats.dart';
import 'package:flutter/foundation.dart';
import 'package:level_up/models/achievement.dart';
import 'package:level_up/services/auth_service.dart';

class CloudSyncService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static String get _userId {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception("Oturum açmış bir kullanıcı bulunamadı.");
    }
    return user.uid;
  }
  
  static Future<void> backupDataToCloud() async {
    try {
      final quests = DatabaseService.getAllQuests().map((q) => q.toMap()).toList();
      final stats = DatabaseService.getPlayerStats().toMap();
      final achievements = DatabaseService.getAllAchievements().map((a) => a.toMap()).toList();
      
      await _db.collection('users').doc(_userId).set({
        'quests': quests,
        'stats': stats,
        'achievements': achievements,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('Veriler başarıyla buluta yedeklendi.');
    } catch (e) {
      debugPrint("Yedekleme hatası: $e");
      rethrow;
    }
  }

  static Future<void> restoreDataFromCloud() async {
    try {
      final doc = await _db.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        // İstatistikleri Yükle
        if (data.containsKey('stats')) {
          final stats = PlayerStats.fromMap(Map<String, dynamic>.from(data['stats']));
          await DatabaseService.savePlayerStats(stats);
        }
        
        // Görevleri Yükle
        if (data.containsKey('quests')) {
          final questsList = List<Map<String, dynamic>>.from(data['quests']);
          await DatabaseService.questsBox.clear(); // Eskileri temizle
          for (var questMap in questsList) {
            final q = Quest.fromMap(questMap);
            await DatabaseService.saveQuest(q);
          }
        }
        
        // Başarımları Yükle
        if (data.containsKey('achievements')) {
          final achList = List<Map<String, dynamic>>.from(data['achievements']);
          await DatabaseService.achievementsBox.clear(); // Eskileri temizle
          for (var achMap in achList) {
            final a = Achievement.fromMap(achMap);
            await DatabaseService.saveAchievement(a);
          }
        }
        debugPrint('Veriler başarıyla buluttan indirildi.');
      } else {
        throw Exception("Bulutta kayıtlı veri bulunamadı.");
      }
    } catch (e) {
      debugPrint("Geri yükleme hatası: $e");
      rethrow;
    }
  }
}
