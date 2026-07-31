// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubQuestAdapter extends TypeAdapter<SubQuest> {
  @override
  final int typeId = 2;

  @override
  SubQuest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubQuest(
      id: fields[0] as String,
      title: fields[1] as String,
      rewardExp: fields[2] as int,
      rewardStat: fields[3] as StatType,
      isProgressBased: fields[4] as bool,
      targetProgress: fields[5] as int,
    )
      .._currentProgress = fields[6] as int
      .._isCompleted = fields[7] as bool;
  }

  @override
  void write(BinaryWriter writer, SubQuest obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.rewardExp)
      ..writeByte(3)
      ..write(obj.rewardStat)
      ..writeByte(4)
      ..write(obj.isProgressBased)
      ..writeByte(5)
      ..write(obj.targetProgress)
      ..writeByte(6)
      ..write(obj._currentProgress)
      ..writeByte(7)
      ..write(obj._isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubQuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestAdapter extends TypeAdapter<Quest> {
  @override
  final int typeId = 3;

  @override
  Quest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Quest(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      difficulty: fields[3] as QuestDifficulty,
      rewardStat: fields[4] as StatType,
      rewardExp: fields[5] as int,
      isProgressBased: fields[6] as bool,
      targetProgress: fields[7] as int,
      subQuests: (fields[10] as List).cast<SubQuest>(),
      isRecurring: fields[11] as bool,
      activeDays: (fields[12] as List).cast<int>(),
      isSystemQuest: fields[15] as bool,
      isEndOfDayEvaluation: fields[13] as bool,
      maxLimit: fields[14] as int?,
      lastCompletedDate: fields[16] as DateTime?,
      completedDates: (fields[17] as List?)?.cast<DateTime>(),
      completionCount: fields[18] == null ? 0 : fields[18] as int,
    )
      .._currentProgress = fields[8] as int
      .._isCompleted = fields[9] as bool;
  }

  @override
  void write(BinaryWriter writer, Quest obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.rewardStat)
      ..writeByte(5)
      ..write(obj.rewardExp)
      ..writeByte(6)
      ..write(obj.isProgressBased)
      ..writeByte(7)
      ..write(obj.targetProgress)
      ..writeByte(8)
      ..write(obj._currentProgress)
      ..writeByte(9)
      ..write(obj._isCompleted)
      ..writeByte(10)
      ..write(obj.subQuests)
      ..writeByte(11)
      ..write(obj.isRecurring)
      ..writeByte(12)
      ..write(obj.activeDays)
      ..writeByte(13)
      ..write(obj.isEndOfDayEvaluation)
      ..writeByte(14)
      ..write(obj.maxLimit)
      ..writeByte(15)
      ..write(obj.isSystemQuest)
      ..writeByte(16)
      ..write(obj.lastCompletedDate)
      ..writeByte(17)
      ..write(obj.completedDates)
      ..writeByte(18)
      ..write(obj.completionCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QuestDifficultyAdapter extends TypeAdapter<QuestDifficulty> {
  @override
  final int typeId = 0;

  @override
  QuestDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuestDifficulty.E;
      case 1:
        return QuestDifficulty.D;
      case 2:
        return QuestDifficulty.C;
      case 3:
        return QuestDifficulty.B;
      case 4:
        return QuestDifficulty.A;
      case 5:
        return QuestDifficulty.S;
      default:
        return QuestDifficulty.E;
    }
  }

  @override
  void write(BinaryWriter writer, QuestDifficulty obj) {
    switch (obj) {
      case QuestDifficulty.E:
        writer.writeByte(0);
        break;
      case QuestDifficulty.D:
        writer.writeByte(1);
        break;
      case QuestDifficulty.C:
        writer.writeByte(2);
        break;
      case QuestDifficulty.B:
        writer.writeByte(3);
        break;
      case QuestDifficulty.A:
        writer.writeByte(4);
        break;
      case QuestDifficulty.S:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StatTypeAdapter extends TypeAdapter<StatType> {
  @override
  final int typeId = 1;

  @override
  StatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StatType.strength;
      case 1:
        return StatType.vitality;
      case 2:
        return StatType.agility;
      case 3:
        return StatType.intelligence;
      case 4:
        return StatType.sense;
      case 5:
        return StatType.none;
      default:
        return StatType.strength;
    }
  }

  @override
  void write(BinaryWriter writer, StatType obj) {
    switch (obj) {
      case StatType.strength:
        writer.writeByte(0);
        break;
      case StatType.vitality:
        writer.writeByte(1);
        break;
      case StatType.agility:
        writer.writeByte(2);
        break;
      case StatType.intelligence:
        writer.writeByte(3);
        break;
      case StatType.sense:
        writer.writeByte(4);
        break;
      case StatType.none:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
