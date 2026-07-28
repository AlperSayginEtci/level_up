// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_stats.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerStatsAdapter extends TypeAdapter<PlayerStats> {
  @override
  final int typeId = 4;

  @override
  PlayerStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerStats(
      level: fields[0] as int,
      exp: fields[1] as int,
      strength: fields[2] as int,
      vitality: fields[3] as int,
      agility: fields[4] as int,
      intelligence: fields[5] as int,
      sense: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PlayerStats obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.level)
      ..writeByte(1)
      ..write(obj.exp)
      ..writeByte(2)
      ..write(obj.strength)
      ..writeByte(3)
      ..write(obj.vitality)
      ..writeByte(4)
      ..write(obj.agility)
      ..writeByte(5)
      ..write(obj.intelligence)
      ..writeByte(6)
      ..write(obj.sense);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
