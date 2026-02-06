// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_meal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedMealAdapter extends TypeAdapter<SavedMeal> {
  @override
  final int typeId = 4;

  @override
  SavedMeal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedMeal(
      id: fields[0] as String,
      name: fields[1] as String,
      calories: fields[2] as int,
      protein: fields[3] as int,
      carbs: fields[4] as int,
      fat: fields[5] as int,
      imagePath: (fields[6] as String?) ?? '',
      fiber: (fields[7] as int?) ?? 0,
      sugar: (fields[8] as int?) ?? 0,
      sodium: (fields[9] as int?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, SavedMeal obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.calories)
      ..writeByte(3)
      ..write(obj.protein)
      ..writeByte(4)
      ..write(obj.carbs)
      ..writeByte(5)
      ..write(obj.fat)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.fiber)
      ..writeByte(8)
      ..write(obj.sugar)
      ..writeByte(9)
      ..write(obj.sodium);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedMealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
