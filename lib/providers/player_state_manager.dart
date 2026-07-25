import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/player_stats.dart';
import '../models/quest.dart';
import '../models/achievement.dart';

class PlayerProgressAndStatsController extends ChangeNotifier {
  PlayerStats _currentPlayerStats;
  List<Quest> _availableQuests;
  List<Achievement> _achievements;
  
  // Pedometer states
  StreamSubscription<StepCount>? _stepCountStream;
  int _dailyBaseSteps = -1;

  // Level up tracking
  bool _hasLeveledUp = false;
  bool get hasLeveledUp => _hasLeveledUp;
  
  // Rank up tracking
  Achievement? _recentlyUnlockedRank;
  Achievement? get recentlyUnlockedRank => _recentlyUnlockedRank;

  void clearLevelUpFlag() {
    _hasLeveledUp = false;
    _recentlyUnlockedRank = null;
    notifyListeners();
  }

  PlayerProgressAndStatsController()
      : _currentPlayerStats = PlayerStats(),
        _availableQuests = [],
        _achievements = defaultAchievements.map((a) => a.copyWith()).toList() {
    // Controller oluşturulduğunda kayıtlı verileri yüklemeye başla
    _loadStatsFromStorage();
  }

  // Exposing the state through getters to prevent external mutation
  PlayerStats get currentPlayerStats => _currentPlayerStats;
  List<Quest> get availableQuests => List.unmodifiable(_availableQuests);
  List<Achievement> get achievements => List.unmodifiable(_achievements);

  Achievement get currentRank {
    return _achievements.lastWhere((a) => a.isUnlocked, orElse: () => _achievements.first);
  }

  // Veritabanından (Cihaz hafızası) değerleri çeken asenkron metod
  Future<void> _loadStatsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Stats
    final statsJsonString = prefs.getString('player_stats_data');
    if (statsJsonString != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(statsJsonString);
      _currentPlayerStats = PlayerStats.fromMap(decodedMap);
    }
    
    // Load Quests
    final questsJsonString = prefs.getString('player_quests_data');
    if (questsJsonString != null) {
      final List<dynamic> decodedList = jsonDecode(questsJsonString);
      _availableQuests = decodedList.map((q) => Quest.fromMap(q)).toList();
    }
    
    // Load Achievements
    final achievementsJsonString = prefs.getString('player_achievements_data');
    if (achievementsJsonString != null) {
      final List<dynamic> decodedList = jsonDecode(achievementsJsonString);
      _achievements = decodedList.map((a) => Achievement.fromMap(a)).toList();
    } else {
      _checkRankAchievements(notify: false); // İlk defa açıldığında veya eklenmediyse
    }
    
    // Load Pedometer base steps
    _dailyBaseSteps = prefs.getInt('daily_base_steps') ?? -1;

    // Eğer hiç görev yoksa (uygulama ilk kez açılmışsa), silinemez sistem görevlerini ekle
    if (_availableQuests.isEmpty) {
      _initializeSystemQuests();
    } else {
      // Geçiş (Migration): Eğer hafızadaki su görevi eski "3 Litre" ise "12 Bardak" olarak güncelle
      final waterQuestIndex = _availableQuests.indexWhere((q) => q.id == 'sys_water');
      if (waterQuestIndex != -1) {
        final wq = _availableQuests[waterQuestIndex];
        if (wq.targetProgress == 3) {
          _availableQuests[waterQuestIndex] = Quest(
            id: 'sys_water',
            title: 'Hydration (Glasses)',
            description: 'Drink 12 glasses of water (250ml each)',
            isProgressBased: true,
            targetProgress: 12,
            currentProgress: wq.currentProgress * 4, // Eski litreyi bardağa çevir (yaklaşık)
            isCompleted: wq.isCompleted,
            rewardExp: wq.rewardExp,
            rewardStat: wq.rewardStat,
            difficulty: wq.difficulty,
            isSystemQuest: true,
            isRecurring: true,
            activeDays: wq.activeDays,
            lastCompletedDate: wq.lastCompletedDate,
          );
        }
      }
    }
    
    final lastLoginStr = prefs.getString('last_login_date');
    DateTime? lastLogin;
    if (lastLoginStr != null) {
      lastLogin = DateTime.tryParse(lastLoginStr);
    }
    
    // Gece yarısı resetini kontrol et
    _checkDailyReset(lastLogin);
    
    await prefs.setString('last_login_date', DateTime.now().toIso8601String());

    // Değerler yüklendiğinde arayüze haber ver ki güncellensin
    notifyListeners();
    
    // Adım sayar dinlemesini başlat
    _initPedometer();
  }

  Future<void> _initPedometer() async {
    if (kIsWeb) {
      print("Adım sayar web'de çalışmaz. Test için 500 adım ekleniyor.");
      _handleStepUpdate(500); // Test amaçlı
      return;
    }

    // Android/iOS izin isteği
    if (await Permission.activityRecognition.request().isGranted) {
      _stepCountStream = Pedometer.stepCountStream.listen(
        (StepCount event) {
          _handleStepUpdate(event.steps);
        },
        onError: (error) {
          print('Adım sayar hatası: \$error');
        },
      );
    }
  }

  void _handleStepUpdate(int totalStepsSinceReboot) {
    if (_dailyBaseSteps == -1) {
      // Günün ilk verisi, referans olarak kaydet
      _dailyBaseSteps = totalStepsSinceReboot;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('daily_base_steps', _dailyBaseSteps);
      });
    }

    int todaySteps = totalStepsSinceReboot - _dailyBaseSteps;
    if (todaySteps < 0) {
      // Cihaz yeniden başlatılmış olabilir
      _dailyBaseSteps = totalStepsSinceReboot;
      todaySteps = 0;
    }

    // Adım görevini bul ve güncelle
    final stepQuestIndex = _availableQuests.indexWhere((q) => q.id == 'sys_steps');
    if (stepQuestIndex != -1) {
      final stepQuest = _availableQuests[stepQuestIndex];
      if (!stepQuest.isCompleted) {
        // Hedefi aşmamak için Math.min kullanmıyoruz çünkü addProgress kendi içinde hallediyor
        int progressToAdd = todaySteps - stepQuest.currentProgress;
        if (progressToAdd > 0) {
          updateQuestProgress(stepQuest, progressToAdd);
        }
      }
    }
  }
  
  void _initializeSystemQuests() {
    _availableQuests.addAll([
      Quest(
        id: 'sys_water',
        title: 'Hydration (Glasses)',
        description: 'Drink 12 glasses of water (250ml each)',
        isProgressBased: true,
        targetProgress: 12,
        rewardExp: 50,
        rewardStat: StatType.vitality,
        difficulty: QuestDifficulty.E,
        isSystemQuest: true,
        isRecurring: true,
      ),
      Quest(
        id: 'sys_steps',
        title: 'Daily Walk',
        description: 'Walk 10,000 steps',
        isProgressBased: true,
        targetProgress: 10000,
        rewardExp: 100,
        rewardStat: StatType.agility,
        difficulty: QuestDifficulty.D,
        isSystemQuest: true,
        isRecurring: true,
      ),
      Quest(
        id: 'sys_calories',
        title: 'Diet Control',
        description: 'Consume between 2000 and 2300 Calories',
        isProgressBased: true,
        targetProgress: 2000,
        isEndOfDayEvaluation: true,
        maxLimit: 2300,
        rewardExp: 80,
        rewardStat: StatType.vitality,
        difficulty: QuestDifficulty.D,
        isSystemQuest: true,
        isRecurring: true,
      ),
    ]);
    _saveStatsToStorage();
  }

  void _checkDailyReset(DateTime? lastLogin) {
    final now = DateTime.now();
    bool needsSave = false;
    
    bool dayChanged = false;
    if (lastLogin != null) {
      if (lastLogin.day != now.day || lastLogin.month != now.month || lastLogin.year != now.year) {
        dayChanged = true;
      }
    }
    
    if (dayChanged) {
      for (var quest in _availableQuests) {
        if (quest.isEndOfDayEvaluation) {
          if (quest.currentProgress <= (quest.maxLimit ?? quest.targetProgress)) {
            // Ödülleri ver
            bool leveledUp = _currentPlayerStats.addExp(quest.rewardExp);
            if (leveledUp) _hasLeveledUp = true;
            if (quest.rewardStat != StatType.none) {
              _currentPlayerStats.increaseStat(quest.rewardStat.name, 1);
            }
          }
        }
        if (quest.isRecurring) {
          quest.resetDaily();
          needsSave = true;
        }
      }
      _dailyBaseSteps = -1;
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('daily_base_steps');
      });
    } else {
      // Fallback for quests that were completed but dayChanged wasn't correctly triggered
      for (var quest in _availableQuests) {
        if (quest.isRecurring && quest.isCompleted && quest.lastCompletedDate != null) {
          if (quest.lastCompletedDate!.day != now.day || 
              quest.lastCompletedDate!.month != now.month || 
              quest.lastCompletedDate!.year != now.year) {
            quest.resetDaily();
            needsSave = true;
          }
        }
      }
    }
    
    if (needsSave) {
      _saveStatsToStorage();
    }
  }

  // Değerleri cihaz hafızasına kaydeden asenkron metod
  Future<void> _saveStatsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Statları Map'e, oradan da JSON string'e dönüştürüp kaydediyoruz
    final statsJsonString = jsonEncode(_currentPlayerStats.toMap());
    await prefs.setString('player_stats_data', statsJsonString);
    
    // Görevleri listeye dönüştürüp JSON olarak kaydediyoruz
    final questsList = _availableQuests.map((q) => q.toMap()).toList();
    final questsJsonString = jsonEncode(questsList);
    await prefs.setString('player_quests_data', questsJsonString);
    
    // Başarıları JSON olarak kaydediyoruz
    final achievementsList = _achievements.map((a) => a.toMap()).toList();
    final achievementsJsonString = jsonEncode(achievementsList);
    await prefs.setString('player_achievements_data', achievementsJsonString);
  }

  void _checkRankAchievements({bool notify = true}) {
    bool newlyUnlocked = false;
    for (int i = 0; i < _achievements.length; i++) {
      if (!_achievements[i].isUnlocked && _currentPlayerStats.level >= _achievements[i].requiredLevel) {
        _achievements[i] = _achievements[i].copyWith(isUnlocked: true);
        _recentlyUnlockedRank = _achievements[i];
        newlyUnlocked = true;
      }
    }
    if (newlyUnlocked) {
      _saveStatsToStorage();
      if (notify) notifyListeners();
    }
  }

  // Kısmi ilerleme eklendiğinde UI'ı ve hafızayı güncellemek için
  void updateQuestProgress(Quest quest, int amount) {
    // Sadece Progress-Based OLMAYAN görevler bitmişse engelle
    if (!quest.isProgressBased && quest.isCompleted) return;

    bool justCompleted = quest.addProgress(amount);
    
    if (justCompleted) {
      // Eğer bu tık ile görev bittiyse (11->12) ödülü ver
      bool leveledUp = _currentPlayerStats.addExp(quest.rewardExp);
      if (leveledUp) {
        _hasLeveledUp = true;
        _checkRankAchievements();
      }
      if (quest.rewardStat != StatType.none) {
        _currentPlayerStats.increaseStat(quest.rewardStat.name, 1);
      }
    }
    
    _saveStatsToStorage();
    notifyListeners();
  }

  void completeSubQuestAndRewardPlayer(Quest parentQuest, SubQuest completedSubQuest) {
    if (completedSubQuest.isCompleted) return;

    // 1. Sub-quest'i tamamlandı işaretle
    completedSubQuest.addProgress(completedSubQuest.targetProgress);

    // 2. Sub-quest ödüllerini ver
    bool leveledUp = _currentPlayerStats.addExp(completedSubQuest.rewardExp);
    if (leveledUp) {
      _hasLeveledUp = true;
      _checkRankAchievements();
    }
    if (completedSubQuest.rewardStat != StatType.none) {
      _currentPlayerStats.increaseStat(completedSubQuest.rewardStat.name, 1);
    }

    // 3. Eğer tüm sub-quest'ler bittiyse ana görev de bitmiş demektir, onun büyük ödülünü de ver
    if (parentQuest.isCompleted) {
      parentQuest.forceComplete(); // Sadece tarihi güncellemek için
      bool parentLeveledUp = _currentPlayerStats.addExp(parentQuest.rewardExp);
      if (parentLeveledUp) {
        _hasLeveledUp = true;
        _checkRankAchievements();
      }
      if (parentQuest.rewardStat != StatType.none) {
        _currentPlayerStats.increaseStat(parentQuest.rewardStat.name, 1);
      }
    }

    _saveStatsToStorage();
    notifyListeners();
  }

  void completeSpecificQuestAndRewardPlayer(Quest completedQuest) {
    if (completedQuest.isCompleted) return; // Zaten tamamlandıysa işlemi durdur

    // 1. Görevi tamamlandı olarak işaretle
    completedQuest.addProgress(completedQuest.targetProgress);

    // 2. Add experience points to the player
    bool leveledUp = _currentPlayerStats.addExp(completedQuest.rewardExp);
    if (leveledUp) {
      _hasLeveledUp = true;
      _checkRankAchievements();
    }

    // 3. Add specific stat rewards if applicable
    if (completedQuest.rewardStat != StatType.none) {
      _currentPlayerStats.increaseStat(
        completedQuest.rewardStat.name,
        1, // We could make this dynamic, but for now completing a quest grants 1 point
      );
    }

    // 4. Değişiklikleri hem ekrana yansıt hem de kalıcı olarak cihaz hafızasına kaydet!
    _saveStatsToStorage();
    notifyListeners();
  }

  void addNewQuestToPlayerBoard(Quest newQuest) {
    _availableQuests.add(newQuest);
    _saveStatsToStorage();
    notifyListeners();
  }

  void deleteQuest(String questId) {
    _availableQuests.removeWhere((q) => q.id == questId);
    _saveStatsToStorage();
    notifyListeners();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }
}
