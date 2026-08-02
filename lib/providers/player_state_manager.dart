import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/player_stats.dart';
import '../models/quest.dart';
import '../models/achievement.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/auth_service.dart';

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

  // Player Profile
  String _playerName = "Player";
  String get playerName => _playerName;
  bool _isNewPlayer = false;
  bool get isNewPlayer => _isNewPlayer;

  String? _profileImageBase64;
  String? get profileImageBase64 => _profileImageBase64;

  // Body Metrics & API
  int _playerAge = 25;
  int get playerAge => _playerAge;
  
  double _playerWeight = 70.0;
  double get playerWeight => _playerWeight;
  
  double _playerHeight = 175.0; // cm
  double get playerHeight => _playerHeight;
  
  String? _geminiApiKey;
  String? get geminiApiKey => _geminiApiKey;

  int _totalCompletedQuests = 0;
  int get totalCompletedQuests => _totalCompletedQuests;

  // Theme Easter Egg
  bool _isShadowMonarchThemeUnlocked = false;
  bool get isShadowMonarchThemeUnlocked => _isShadowMonarchThemeUnlocked;
  
  bool _isShadowMonarchThemeActive = false;
  bool get isShadowMonarchThemeActive => _isShadowMonarchThemeActive;

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
  
  Future<void> reloadFromStorage() async {
    await _loadStatsFromStorage();
  }

  Future<void> syncWithCloudOnLogin() async {
    if (AuthService.currentUser == null) return;
    try {
      await CloudSyncService.restoreDataFromCloud();
      await reloadFromStorage(); 
    } catch (e) {
      // Bulutta veri yoksa veya hata olursa mevcut lokal verileri buluta yükle
      await CloudSyncService.backupDataToCloud();
    }
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
    _currentPlayerStats = DatabaseService.getPlayerStats();
    
    // Load Quests
    _availableQuests = DatabaseService.getAllQuests();
    
    // Load Achievements
    _achievements = DatabaseService.getAllAchievements();
    if (_achievements.isEmpty) {
      _achievements = defaultAchievements.map((a) => a.copyWith()).toList();
      _checkRankAchievements(notify: false); // İlk defa açıldığında
    }
    
    // Load Player Name & Profile
    _playerName = prefs.getString('player_name') ?? "Player";
    _isNewPlayer = prefs.getBool('is_new_player') ?? true;
    _profileImageBase64 = prefs.getString('profile_image_base64');
    _totalCompletedQuests = prefs.getInt('total_completed_quests') ?? 0;

    // Load Body Metrics & API Key
    _playerAge = prefs.getInt('player_age') ?? 25;
    _playerWeight = prefs.getDouble('player_weight') ?? 70.0;
    _playerHeight = prefs.getDouble('player_height') ?? 175.0;
    _geminiApiKey = prefs.getString('gemini_api_key');

    _isShadowMonarchThemeUnlocked = prefs.getBool('shadow_monarch_unlocked') ?? false;
    _isShadowMonarchThemeActive = prefs.getBool('shadow_monarch_active') ?? false;

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

      // Migration for Calories -> Nutrition
      final calQuestIndex = _availableQuests.indexWhere((q) => q.id == 'sys_calories' || q.id == 'sys_nutrition');
      if (calQuestIndex != -1) {
        final cq = _availableQuests[calQuestIndex];
        if (cq.subQuests.isEmpty) { // It's the old sys_calories
          _recalculateMacros(initialMigration: true);
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

    // Uygulama her açıldığında offline kalmış verileri buluta eşitlemeyi dene
    if (AuthService.currentUser != null) {
      CloudSyncService.backupDataToCloud().catchError((e) => null);
    }
  }

  Future<void> _initPedometer() async {
    if (kIsWeb) {
      debugPrint("Adım sayar web'de çalışmaz. Test için 500 adım ekleniyor.");
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
          debugPrint('Adım sayar hatası: \$error');
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
        id: 'sys_nutrition',
        title: 'Diet Control (Nutrition)',
        description: 'Meet your daily macro goals',
        isProgressBased: true,
        targetProgress: 2000,
        isEndOfDayEvaluation: true,
        maxLimit: 2300,
        rewardExp: 80,
        rewardStat: StatType.vitality,
        difficulty: QuestDifficulty.D,
        isSystemQuest: true,
        isRecurring: true,
        subQuests: [
          SubQuest(id: 'sq_protein', title: 'Protein (g)', rewardExp: 10, isProgressBased: true, targetProgress: 140),
          SubQuest(id: 'sq_carbs', title: 'Carbs (g)', rewardExp: 10, isProgressBased: true, targetProgress: 200),
          SubQuest(id: 'sq_fat', title: 'Fat (g)', rewardExp: 10, isProgressBased: true, targetProgress: 60),
        ]
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
    await DatabaseService.savePlayerStats(_currentPlayerStats);
    
    for (var q in _availableQuests) {
      await DatabaseService.saveQuest(q);
    }
    
    for (var a in _achievements) {
      await DatabaseService.saveAchievement(a);
    }
    
    // Send updated quests to Wear OS
    await SyncService.sendQuestsToWatch(_availableQuests);

    // Save key stats to SharedPreferences so Native Android TileService can read them
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stat_level', _currentPlayerStats.level);
    await prefs.setString('stat_rank', currentRank.title);
    await prefs.setInt('stat_str', _currentPlayerStats.strength);
    await prefs.setInt('stat_agi', _currentPlayerStats.agility);
    await prefs.setInt('stat_int', _currentPlayerStats.intelligence);
    await prefs.setInt('stat_sen', _currentPlayerStats.sense);
    await prefs.setInt('stat_vit', _currentPlayerStats.vitality);

    // Otomatik Bulut Senkronizasyonu (Arka planda çalışır)
    if (AuthService.currentUser != null) {
      CloudSyncService.backupDataToCloud().catchError((e) {
        debugPrint("Auto-sync error: $e");
      });
    }
  }

  void _checkRankAchievements({bool notify = true}) {
    bool newlyUnlocked = false;
    for (int i = 0; i < _achievements.length; i++) {
      if (!_achievements[i].isUnlocked && _currentPlayerStats.level >= _achievements[i].requiredLevel) {
        _achievements[i] = _achievements[i].copyWith(isUnlocked: true, unlockedDate: DateTime.now());
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
      _totalCompletedQuests++;
      SharedPreferences.getInstance().then((prefs) => prefs.setInt('total_completed_quests', _totalCompletedQuests));

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
      _totalCompletedQuests++;
      SharedPreferences.getInstance().then((prefs) => prefs.setInt('total_completed_quests', _totalCompletedQuests));

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
    
    _totalCompletedQuests++;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('total_completed_quests', _totalCompletedQuests));

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
    DatabaseService.deleteQuest(questId);
    _saveStatsToStorage();
    notifyListeners();
  }

  Future<void> updatePlayerProfile(String newName) async {
    _playerName = newName;
    _isNewPlayer = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', newName);
    await prefs.setBool('is_new_player', false);
    notifyListeners();
  }

  Future<void> updateProfileImageBase64(String base64) async {
    _profileImageBase64 = base64;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_base64', base64);
    notifyListeners();
  }

  Future<void> unlockShadowMonarchTheme() async {
    if (!_isShadowMonarchThemeUnlocked) {
      _isShadowMonarchThemeUnlocked = true;
      _isShadowMonarchThemeActive = true; // Auto activate on unlock
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shadow_monarch_unlocked', true);
      await prefs.setBool('shadow_monarch_active', true);
      notifyListeners();
    }
  }

  Future<void> toggleShadowMonarchTheme() async {
    if (_isShadowMonarchThemeUnlocked) {
      _isShadowMonarchThemeActive = !_isShadowMonarchThemeActive;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('shadow_monarch_active', _isShadowMonarchThemeActive);
      notifyListeners();
    }
  }

  Future<void> updatePlayerMetrics(int age, double weight, double height) async {
    _playerAge = age;
    _playerWeight = weight;
    _playerHeight = height;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('player_age', age);
    await prefs.setDouble('player_weight', weight);
    await prefs.setDouble('player_height', height);
    
    _recalculateMacros();
    notifyListeners();
  }
  
  Future<void> updateGeminiApiKey(String key) async {
    _geminiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    notifyListeners();
  }

  void _recalculateMacros({bool initialMigration = false}) {
    double bmr = (10 * _playerWeight) + (6.25 * _playerHeight) - (5 * _playerAge) + 5;
    int targetCalories = (bmr * 1.375).round();
    int targetProtein = (_playerWeight * 2.0).round();
    int targetFat = (_playerWeight * 0.8).round();
    int targetCarbs = ((targetCalories - (targetProtein * 4) - (targetFat * 9)) / 4).round();
    
    final qIndex = _availableQuests.indexWhere((q) => q.id == 'sys_calories' || q.id == 'sys_nutrition');
    if (qIndex != -1) {
      final oldQ = _availableQuests[qIndex];
      
      List<SubQuest> updatedSubQuests = [];
      if (oldQ.subQuests.isEmpty) {
          updatedSubQuests = [
            SubQuest(id: 'sq_protein', title: 'Protein (g)', rewardExp: 10, isProgressBased: true, targetProgress: targetProtein),
            SubQuest(id: 'sq_carbs', title: 'Carbs (g)', rewardExp: 10, isProgressBased: true, targetProgress: targetCarbs),
            SubQuest(id: 'sq_fat', title: 'Fat (g)', rewardExp: 10, isProgressBased: true, targetProgress: targetFat),
          ];
      } else {
        for (var sq in oldQ.subQuests) {
          if (sq.id == 'sq_protein') {
             updatedSubQuests.add(SubQuest(id: sq.id, title: 'Protein (g)', rewardExp: sq.rewardExp, rewardStat: sq.rewardStat, isProgressBased: true, targetProgress: targetProtein, currentProgress: sq.currentProgress, isCompleted: sq.currentProgress >= targetProtein));
          } else if (sq.id == 'sq_carbs') {
             updatedSubQuests.add(SubQuest(id: sq.id, title: 'Carbs (g)', rewardExp: sq.rewardExp, rewardStat: sq.rewardStat, isProgressBased: true, targetProgress: targetCarbs, currentProgress: sq.currentProgress, isCompleted: sq.currentProgress >= targetCarbs));
          } else if (sq.id == 'sq_fat') {
             updatedSubQuests.add(SubQuest(id: sq.id, title: 'Fat (g)', rewardExp: sq.rewardExp, rewardStat: sq.rewardStat, isProgressBased: true, targetProgress: targetFat, currentProgress: sq.currentProgress, isCompleted: sq.currentProgress >= targetFat));
          } else {
             updatedSubQuests.add(sq);
          }
        }
      }
      
      _availableQuests[qIndex] = Quest(
        id: 'sys_nutrition', // Rename to sys_nutrition if it was sys_calories
        title: 'Diet Control (Nutrition)',
        description: 'Meet your daily macro goals: $targetCalories kcal',
        isProgressBased: oldQ.isProgressBased,
        targetProgress: targetCalories,
        currentProgress: oldQ.currentProgress,
        isCompleted: oldQ.isCompleted,
        subQuests: updatedSubQuests,
        rewardExp: oldQ.rewardExp,
        rewardStat: oldQ.rewardStat,
        difficulty: oldQ.difficulty,
        isSystemQuest: true,
        isRecurring: true,
        activeDays: oldQ.activeDays,
        isEndOfDayEvaluation: true,
        maxLimit: targetCalories + 300,
        lastCompletedDate: oldQ.lastCompletedDate,
        completedDates: oldQ.completedDates,
        completionCount: oldQ.completionCount,
      );
      
      if (!initialMigration) {
        _saveStatsToStorage();
      }
    }
  }

  void addNutritionProgress(int calories, int protein, int carbs, int fat) {
    final qIndex = _availableQuests.indexWhere((q) => q.id == 'sys_nutrition' || q.id == 'sys_calories');
    if (qIndex != -1) {
      final quest = _availableQuests[qIndex];
      
      // Update Main Quest (Calories)
      quest.addProgress(calories, forceMain: true);
      
      // Update SubQuests (Macros)
      for (var sq in quest.subQuests) {
        bool wasCompleted = sq.isCompleted;
        if (sq.id == 'sq_protein') sq.addProgress(protein);
        if (sq.id == 'sq_carbs') sq.addProgress(carbs);
        if (sq.id == 'sq_fat') sq.addProgress(fat);
        
        if (!wasCompleted && sq.isCompleted) {
           bool leveledUp = _currentPlayerStats.addExp(sq.rewardExp);
           if (leveledUp) _hasLeveledUp = true;
           if (sq.rewardStat != StatType.none) _currentPlayerStats.increaseStat(sq.rewardStat.name, 1);
        }
      }
      _checkRankAchievements();
      
      _saveStatsToStorage();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    super.dispose();
  }
}
