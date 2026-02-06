// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 1;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      age: fields[0] as int,
      weight: fields[1] as double,
      bodyFat: fields[2] as double,
      gender: fields[3] as String,
      goal: fields[4] as String,
      autoGenerateGoal: fields[5] as bool,
      manualCalorieGoal: fields[6] as int,
      manualProteinGoal: fields[7] as int,
      manualCarbsGoal: fields[8] as int,
      manualFatGoal: fields[9] as int,
      height: fields[10] as int,
      goalWeight: fields[11] as double?,
      weightHistory: (fields[12] as List?)?.cast<String>(),
      goalIntensity: (fields[13] as double?) ?? 0.5,
      stepGoal: (fields[14] as int?) ?? 10000,
      notifyWater: (fields[15] as bool?) ?? true,
      notifyProtein: (fields[16] as bool?) ?? true,
      notifyCalories: (fields[17] as bool?) ?? true,
      notifyWorkouts: (fields[18] as bool?) ?? true,
      notifyMotivation: (fields[19] as bool?) ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.age)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.bodyFat)
      ..writeByte(3)
      ..write(obj.gender)
      ..writeByte(4)
      ..write(obj.goal)
      ..writeByte(5)
      ..write(obj.autoGenerateGoal)
      ..writeByte(6)
      ..write(obj.manualCalorieGoal)
      ..writeByte(7)
      ..write(obj.manualProteinGoal)
      ..writeByte(8)
      ..write(obj.manualCarbsGoal)
      ..writeByte(9)
      ..write(obj.manualFatGoal)
      ..writeByte(10)
      ..write(obj.height)
      ..writeByte(11)
      ..write(obj.goalWeight)
      ..writeByte(12)
      ..write(obj.weightHistory)
      ..writeByte(13)
      ..write(obj.goalIntensity)
      ..writeByte(14)
      ..write(obj.stepGoal)
      ..writeByte(15)
      ..write(obj.notifyWater)
      ..writeByte(16)
      ..write(obj.notifyProtein)
      ..writeByte(17)
      ..write(obj.notifyCalories)
      ..writeByte(18)
      ..write(obj.notifyWorkouts)
      ..writeByte(19)
      ..write(obj.notifyMotivation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
