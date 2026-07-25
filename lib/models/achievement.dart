class Achievement {
  final String id;
  final String title;
  final String description;
  final int requiredLevel;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredLevel,
    this.isUnlocked = false,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    int? requiredLevel,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredLevel': requiredLevel,
      'isUnlocked': isUnlocked,
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      requiredLevel: map['requiredLevel'] ?? 1,
      isUnlocked: map['isUnlocked'] ?? false,
    );
  }
}

// Varsayılan Başarılar (Ranks)
final List<Achievement> defaultAchievements = [
  Achievement(id: 'rank_e', title: 'E-Rank', description: 'Uyanışını yeni tamamladın.', requiredLevel: 1, isUnlocked: true),
  Achievement(id: 'rank_d', title: 'D-Rank', description: 'Daha güçlü canavarlarla yüzleşmeye hazırsın.', requiredLevel: 10),
  Achievement(id: 'rank_c', title: 'C-Rank', description: 'Ortalama bir Avcı oldun.', requiredLevel: 20),
  Achievement(id: 'rank_b', title: 'B-Rank', description: 'Loncalar tarafından saygı duyulan biri.', requiredLevel: 30),
  Achievement(id: 'rank_a', title: 'A-Rank', description: 'Üst düzey Avcılar arasına girdin.', requiredLevel: 40),
  Achievement(id: 'rank_s', title: 'S-Rank', description: 'İnsanlığın zirvesine ulaştın.', requiredLevel: 50),
  Achievement(id: 'rank_ss', title: 'SS-Rank', description: 'Bir ordunun gücüne eşitsin.', requiredLevel: 60),
  Achievement(id: 'rank_sss', title: 'SSS-Rank', description: 'Tanrılara kafa tutacak güçtesin.', requiredLevel: 70),
];
