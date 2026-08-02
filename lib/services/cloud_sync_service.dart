import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:level_up/services/database_service.dart';
import 'package:level_up/models/quest.dart';
import 'package:level_up/models/player_stats.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      
      final prefs = await SharedPreferences.getInstance();
      final profileData = {
        'player_name': prefs.getString('player_name'),
        'profile_image_base64': prefs.getString('profile_image_base64'),
        'player_age': prefs.getInt('player_age'),
        'player_weight': prefs.getDouble('player_weight'),
        'player_height': prefs.getDouble('player_height'),
        'gemini_api_key': prefs.getString('gemini_api_key'),
        'total_completed_quests': prefs.getInt('total_completed_quests'),
      };
      
      await _db.collection('users').doc(_userId).set({
        'quests': quests,
        'stats': stats,
        'achievements': achievements,
        'profile': profileData,
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
        
        // Profil ve Ayarları Yükle
        if (data.containsKey('profile')) {
          final profile = data['profile'] as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();
          
          if (profile['player_name'] != null) await prefs.setString('player_name', profile['player_name']);
          if (profile['profile_image_base64'] != null) await prefs.setString('profile_image_base64', profile['profile_image_base64']);
          if (profile['player_age'] != null) await prefs.setInt('player_age', profile['player_age']);
          if (profile['player_weight'] != null) await prefs.setDouble('player_weight', (profile['player_weight'] as num).toDouble());
          if (profile['player_height'] != null) await prefs.setDouble('player_height', (profile['player_height'] as num).toDouble());
          if (profile['gemini_api_key'] != null) await prefs.setString('gemini_api_key', profile['gemini_api_key']);
          if (profile['total_completed_quests'] != null) await prefs.setInt('total_completed_quests', profile['total_completed_quests']);
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
