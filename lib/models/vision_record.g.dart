// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vision_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VisionRecordAdapter extends TypeAdapter<VisionRecord> {
  @override
  final int typeId = 0;

  @override
  VisionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VisionRecord(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      testType: fields[2] as String,
      odSphere: fields[3] as double?,
      odCylinder: fields[4] as double?,
      odAxis: fields[5] as double?,
      osSphere: fields[6] as double?,
      osCylinder: fields[7] as double?,
      osAxis: fields[8] as double?,
      snellenScore: fields[9] as double?,
      notes: fields[10] as String?,
      faceDistanceCm: fields[11] as double?,
      odAcuity: fields[12] as String?,
      osAcuity: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VisionRecord obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.testType)
      ..writeByte(3)
      ..write(obj.odSphere)
      ..writeByte(4)
      ..write(obj.odCylinder)
      ..writeByte(5)
      ..write(obj.odAxis)
      ..writeByte(6)
      ..write(obj.osSphere)
      ..writeByte(7)
      ..write(obj.osCylinder)
      ..writeByte(8)
      ..write(obj.osAxis)
      ..writeByte(9)
      ..write(obj.snellenScore)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.faceDistanceCm)
      ..writeByte(12)
      ..write(obj.odAcuity)
      ..writeByte(13)
      ..write(obj.osAcuity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
