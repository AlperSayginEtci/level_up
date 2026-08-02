import 'package:hive/hive.dart';

part 'player_stats.g.dart';

@HiveType(typeId: 4)
class PlayerStats {
  @HiveField(0)
  int level;
  @HiveField(1)
  int exp;

  //Core attributes

  @HiveField(2)
  int strength;
  @HiveField(3)
  int vitality;
  @HiveField(4)
  int agility;
  @HiveField(5)
  int intelligence;
  @HiveField(6)
  int sense;

  PlayerStats({
    this.level = 1,
    this.exp = 0,
    this.strength = 1,
    this.vitality = 1,
    this.agility = 1,
    this.intelligence = 1,
    this.sense = 1,
  });
  //Next level calculator
  int get requiredExp => level * 50 + 50;

  //Adding exp and leveling up
  bool addExp(int amount) {
    exp += amount;
    bool levelUp = false;
    while (exp >= requiredExp) {
      exp -= requiredExp;
      level++; // Seviyeyi artırmayı unutmuşuz!
      levelUp = true;
    }
    return levelUp;
  }

  //Stat increase
  void increaseStat(String statName, int amount) {
    switch (statName.toUpperCase()) {
      case 'STR' || 'STRENGTH':
        strength += amount;
        break;
      case 'VIT' || 'VITALITY':
        vitality += amount;
        break;
      case 'AGI' || 'AGILITY':
        agility += amount;
        break;
      case 'INT' || 'INTELLIGENCE':
        intelligence += amount;
        break;
      case 'SEN' || 'SENSE':
        sense += amount;
        break;
    }
  }

  //Convert to map for saving to local storage
  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'exp': exp,
      'strength': strength,
      'vitality': vitality,
      'agility': agility,
      'intelligence': intelligence,
      'sense': sense,
    };
  }

  PlayerStats copyWith({
    int? level,
    int? exp,
    int? strength,
    int? vitality,
    int? agility,
    int? intelligence,
    int? sense,
  }) {
    return PlayerStats(
      level: level ?? this.level,
      exp: exp ?? this.exp,
      strength: strength ?? this.strength,
      vitality: vitality ?? this.vitality,
      agility: agility ?? this.agility,
      intelligence: intelligence ?? this.intelligence,
      sense: sense ?? this.sense,
    );
  }

  // Create from Map when loading from Local storage
  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      level: map['level'] ?? 1,
      exp: map['exp'] ?? 0,
      strength: map['strength'] ?? 1,
      vitality: map['vitality'] ?? 1,
      agility: map['agility'] ?? 1,
      intelligence: map['intelligence'] ?? 1,
      sense: map['sense'] ?? 1,
    );
  }
}
