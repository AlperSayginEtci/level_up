import 'dart:async';
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
  static bool _isSyncing = false;
  static StreamSubscription<DocumentSnapshot>? _syncSubscription;
  
  static String get _userId {
    final user = AuthService.currentUser;
    if (user == null) {
      throw Exception("Oturum açmış bir kullanıcı bulunamadı.");
    }
    return user.uid;
  }
  
  // Start Real-time sync
  static void startRealTimeSync(Function onDataUpdated) {
    if (_syncSubscription != null) return;
    
    _syncSubscription = _db.collection('users').doc(_userId).snapshots().listen((doc) async {
      if (_isSyncing) return; // Prevent loop when we are the ones uploading
      
      if (doc.exists && doc.data() != null) {
        try {
          _isSyncing = true;
          await _parseAndSaveLocalData(doc.data()!);
          onDataUpdated();
        } catch (e) {
          debugPrint("Real-time sync parse error: \$e");
        } finally {
          _isSyncing = false;
        }
      }
    });
  }

  static void stopRealTimeSync() {
    _syncSubscription?.cancel();
    _syncSubscription = null;
  }
  
  static Future<void> backupDataToCloud() async {
    try {
      _isSyncing = true; // Prevent reading our own writes
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
      }).timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("Buluta bağlanılamadı (Zaman Aşımı). Lütfen internetinizi kontrol edin.");
      });
      debugPrint('Veriler başarıyla buluta yedeklendi.');
    } catch (e) {
      debugPrint("Yedekleme hatası: \$e");
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> restoreDataFromCloud() async {
    try {
      _isSyncing = true;
      final doc = await _db.collection('users').doc(_userId).get().timeout(const Duration(seconds: 15), onTimeout: () {
        throw Exception("Buluta bağlanılamadı (Zaman Aşımı). Lütfen internetinizi kontrol edin.");
      });
      if (doc.exists && doc.data() != null) {
        await _parseAndSaveLocalData(doc.data()!);
        debugPrint('Veriler başarıyla buluttan indirildi.');
      } else {
        throw Exception("Bulutta kayıtlı veri bulunamadı.");
      }
    } catch (e) {
      debugPrint("Geri yükleme hatası: \$e");
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  static Future<void> _parseAndSaveLocalData(Map<String, dynamic> data) async {
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
      
      // Bulutta profili olan biri zaten yeni oyuncu olamaz
      await prefs.setBool('is_new_player', false);
    }
  }
}
