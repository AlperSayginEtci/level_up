import 'package:hive/hive.dart';

part 'quest.g.dart';

@HiveType(typeId: 0)
enum QuestDifficulty {
  @HiveField(0) E,
  @HiveField(1) D,
  @HiveField(2) C,
  @HiveField(3) B,
  @HiveField(4) A,
  @HiveField(5) S
}

@HiveType(typeId: 1)
enum StatType {
  @HiveField(0) strength,
  @HiveField(1) vitality,
  @HiveField(2) agility,
  @HiveField(3) intelligence,
  @HiveField(4) sense,
  @HiveField(5) none
}

@HiveType(typeId: 2)
class SubQuest {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final int rewardExp;
  @HiveField(3)
  final StatType rewardStat;
  
  @HiveField(4)
  final bool isProgressBased;
  @HiveField(5)
  final int targetProgress;
  @HiveField(6)
  int _currentProgress;
  @HiveField(7)
  bool _isCompleted;

  SubQuest({
    required this.id,
    required this.title,
    required this.rewardExp,
    this.rewardStat = StatType.none,
    this.isProgressBased = false,
    this.targetProgress = 1,
    int currentProgress = 0,
    bool isCompleted = false,
  }) : _currentProgress = currentProgress,
       _isCompleted = isCompleted;

  bool get isCompleted => _isCompleted;
  int get currentProgress => _currentProgress;

  bool addProgress(int amount) {
    if (isProgressBased) {
      bool wasCompleted = _isCompleted;
      _currentProgress += amount;
      if (_currentProgress >= targetProgress) {
        _isCompleted = true;
        return !wasCompleted;
      }
    } else {
      if (_isCompleted) return false;
      _isCompleted = true;
      return true;
    }
    return false;
  }

  void resetDaily() {
    _isCompleted = false;
    _currentProgress = 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'rewardExp': rewardExp,
      'rewardStat': rewardStat.index,
      'isProgressBased': isProgressBased,
      'targetProgress': targetProgress,
      'currentProgress': _currentProgress,
      'isCompleted': _isCompleted,
    };
  }

  factory SubQuest.fromMap(Map<String, dynamic> map) {
    return SubQuest(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      rewardExp: map['rewardExp'] ?? 0,
      rewardStat: StatType.values[map['rewardStat'] ?? 5],
      isProgressBased: map['isProgressBased'] ?? false,
      targetProgress: map['targetProgress'] ?? 1,
      currentProgress: map['currentProgress'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

@HiveType(typeId: 3)
class Quest {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final QuestDifficulty difficulty;
  @HiveField(4)
  final StatType rewardStat;
  @HiveField(5)
  final int rewardExp;
  
  // Progress tracking
  @HiveField(6)
  final bool isProgressBased;
  @HiveField(7)
  final int targetProgress;
  @HiveField(8)
  int _currentProgress;
  @HiveField(9)
  bool _isCompleted;
  
  // Sub-Quests (Chain Quests)
  @HiveField(10)
  final List<SubQuest> subQuests;
  
  // Scheduling
  @HiveField(11)
  final bool isRecurring;
  @HiveField(12)
  final List<int> activeDays; // 1 = Monday, ..., 7 = Sunday
  
  // End-of-day limit evaluation
  @HiveField(13)
  final bool isEndOfDayEvaluation;
  @HiveField(14)
  final int? maxLimit;
  
  // System protection
  @HiveField(15)
  final bool isSystemQuest;
  
  // Tracking resets
  @HiveField(16)
  DateTime? lastCompletedDate;
  
  // History tracking
  @HiveField(17)
  List<DateTime> completedDates;
  
  @HiveField(18, defaultValue: 0)
  int completionCount;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    this.difficulty = QuestDifficulty.E,
    this.rewardStat = StatType.none,
    required this.rewardExp,
    
    this.isProgressBased = false,
    this.targetProgress = 1,
    int currentProgress = 0,
    bool isCompleted = false,
    
    this.subQuests = const [],
    
    this.isRecurring = false,
    this.activeDays = const [],
    this.isSystemQuest = false,
    
    this.isEndOfDayEvaluation = false,
    this.maxLimit,
    
    this.lastCompletedDate,
    List<DateTime>? completedDates,
    this.completionCount = 0,
  }) : _currentProgress = currentProgress,
       _isCompleted = isCompleted,
       completedDates = completedDates ?? [];

  // Ana görevin tamamlanma durumu: Ya kendi barı dolduysa ya da tüm alt görevleri bittiyse.
  bool get isCompleted {
    if (subQuests.isNotEmpty) {
      return subQuests.every((sq) => sq.isCompleted);
    }
    return _isCompleted;
  }
  
  int get currentProgress => _currentProgress;

  bool addProgress(int amount) {
    if (subQuests.isNotEmpty) {
      // Eğer zincirleme görevse, ilerleme ana görevde değil, alt görevlerde yapılmalıdır.
      return false; 
    }
    
    if (isProgressBased) {
      bool wasCompleted = _isCompleted;
      _currentProgress += amount;
      
      if (isEndOfDayEvaluation) {
        // Limitli görevler anında tamamlanmaz, sadece ilerleme artar.
        return false;
      }
      
      if (_currentProgress >= targetProgress) {
        // İlerlemeyi kısıtlamıyoruz (örn: 13/12 olabilir)
        _isCompleted = true;
        lastCompletedDate = DateTime.now();
        if (!wasCompleted) {
          completedDates.add(lastCompletedDate!);
          completionCount++;
        }
        return !wasCompleted; // Sadece İLK KEZ tamamlandığında true döner (Ödül için)
      }
    } else {
      if (_isCompleted) return false;
      _isCompleted = true;
      lastCompletedDate = DateTime.now();
      completedDates.add(lastCompletedDate!);
      completionCount++;
      return true; // Just completed
    }
    return false; // Progressed but not fully completed yet
  }
  
  void forceComplete() {
    if (!_isCompleted) {
      _isCompleted = true;
      lastCompletedDate = DateTime.now();
      completedDates.add(lastCompletedDate!);
      completionCount++;
    } else {
      lastCompletedDate = DateTime.now();
    }
  }

  void resetDaily() {
    _isCompleted = false;
    _currentProgress = 0;
    for (var sq in subQuests) {
      sq.resetDaily();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'difficulty': difficulty.index,
      'rewardStat': rewardStat.index,
      'rewardExp': rewardExp,
      'isProgressBased': isProgressBased,
      'targetProgress': targetProgress,
      'currentProgress': _currentProgress,
      'isCompleted': _isCompleted,
      'subQuests': subQuests.map((sq) => sq.toMap()).toList(),
      'isRecurring': isRecurring,
      'activeDays': activeDays,
      'isSystemQuest': isSystemQuest,
      'isEndOfDayEvaluation': isEndOfDayEvaluation,
      'maxLimit': maxLimit,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'completionCount': completionCount,
    };
  }

  factory Quest.fromMap(Map<String, dynamic> map) {
    bool isProg = map['isProgressBased'] ?? false;
    int currentProg = map['currentProgress'] ?? 0;
    int targetProg = map['targetProgress'] ?? 1;
    bool isComp = map['isCompleted'] ?? false;

    // Eğer progress bazlıysa ve hedefe ulaşılmamışsa, "isCompleted" true kalamaz!
    // (Özellikle eski önbellek hatalarını temizlemek için)
    if (isProg && currentProg < targetProg) {
      isComp = false;
    }

    return Quest(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      difficulty: QuestDifficulty.values[map['difficulty'] ?? 0],
      rewardStat: StatType.values[map['rewardStat'] ?? 5],
      rewardExp: map['rewardExp'] ?? 0,
      
      isProgressBased: isProg,
      targetProgress: targetProg,
      currentProgress: currentProg,
      isCompleted: isComp,
      
      subQuests: map['subQuests'] != null 
          ? (map['subQuests'] as List).map((sq) => SubQuest.fromMap(sq)).toList() 
          : [],
      
      isRecurring: map['isRecurring'] ?? false,
      activeDays: List<int>.from(map['activeDays'] ?? []),
      isSystemQuest: map['isSystemQuest'] ?? false,
      isEndOfDayEvaluation: map['isEndOfDayEvaluation'] ?? false,
      maxLimit: map['maxLimit'],
      
      lastCompletedDate: map['lastCompletedDate'] != null 
          ? DateTime.tryParse(map['lastCompletedDate']) 
          : null,
      completedDates: map['completedDates'] != null
          ? (map['completedDates'] as List).map((d) => DateTime.parse(d)).toList()
          : [],
      completionCount: map['completionCount'] ?? 0,
    );
  }
}
