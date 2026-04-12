// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 0;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicine(
      id: fields[0] as String,
      name: fields[1] as String,
      composition: fields[2] as String,
      dosage: fields[3] as String,
      warnings: fields[4] as String,
      storage: fields[5] as String,
      manufacturer: fields[6] as String,
      expiry: fields[7] as String,
      additionalInfo: fields[8] as String,
      scannedAt: fields[9] as DateTime,
      rawText: fields[10] as String,
      medicineClass: fields[11] as String? ?? '',
      uses: fields[12] as String? ?? '',
      sideEffects: fields[13] as String? ?? '',
      isVerified: fields[14] as bool? ?? false,
      rxcui: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.composition)
      ..writeByte(3)
      ..write(obj.dosage)
      ..writeByte(4)
      ..write(obj.warnings)
      ..writeByte(5)
      ..write(obj.storage)
      ..writeByte(6)
      ..write(obj.manufacturer)
      ..writeByte(7)
      ..write(obj.expiry)
      ..writeByte(8)
      ..write(obj.additionalInfo)
      ..writeByte(9)
      ..write(obj.scannedAt)
      ..writeByte(10)
      ..write(obj.rawText)
      ..writeByte(11)
      ..write(obj.medicineClass)
      ..writeByte(12)
      ..write(obj.uses)
      ..writeByte(13)
      ..write(obj.sideEffects)
      ..writeByte(14)
      ..write(obj.isVerified)
      ..writeByte(15)
      ..write(obj.rxcui);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
