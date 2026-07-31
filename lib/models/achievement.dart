import 'package:hive/hive.dart';

part 'achievement.g.dart';

@HiveType(typeId: 5)
class Achievement {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final int requiredLevel;
  @HiveField(4)
  final bool isUnlocked;
  @HiveField(5)
  final DateTime? unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredLevel,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    int? requiredLevel,
    bool? isUnlocked,
    DateTime? unlockedDate,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredLevel': requiredLevel,
      'isUnlocked': isUnlocked,
      'unlockedDate': unlockedDate?.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      requiredLevel: map['requiredLevel'] ?? 1,
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedDate: map['unlockedDate'] != null ? DateTime.tryParse(map['unlockedDate']) : null,
    );
  }
}

// Varsayılan Başarılar (Ranks)
final List<Achievement> defaultAchievements = [
  Achievement(id: 'rank_e', title: 'E-Rank', description: 'Uyanışını yeni tamamladın.', requiredLevel: 1, isUnlocked: true, unlockedDate: DateTime.now()),
  Achievement(id: 'rank_d', title: 'D-Rank', description: 'Daha güçlü canavarlarla yüzleşmeye hazırsın.', requiredLevel: 10),
  Achievement(id: 'rank_c', title: 'C-Rank', description: 'Ortalama bir Avcı oldun.', requiredLevel: 20),
  Achievement(id: 'rank_b', title: 'B-Rank', description: 'Loncalar tarafından saygı duyulan biri.', requiredLevel: 30),
  Achievement(id: 'rank_a', title: 'A-Rank', description: 'Üst düzey Avcılar arasına girdin.', requiredLevel: 40),
  Achievement(id: 'rank_s', title: 'S-Rank', description: 'İnsanlığın zirvesine ulaştın.', requiredLevel: 50),
  Achievement(id: 'rank_ss', title: 'SS-Rank', description: 'Bir ordunun gücüne eşitsin.', requiredLevel: 60),
  Achievement(id: 'rank_sss', title: 'SSS-Rank', description: 'Tanrılara kafa tutacak güçtesin.', requiredLevel: 70),
];
