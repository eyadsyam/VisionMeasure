import 'package:hive/hive.dart';

part 'vision_record.g.dart';

@HiveType(typeId: 0)
class VisionRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime createdAt;

  @HiveField(2)
  String testType; // 'snellen' | 'manual'

  @HiveField(3)
  double? odSphere;

  @HiveField(4)
  double? odCylinder;

  @HiveField(5)
  double? odAxis;

  @HiveField(6)
  double? osSphere;

  @HiveField(7)
  double? osCylinder;

  @HiveField(8)
  double? osAxis;

  @HiveField(9)
  double? snellenScore; // numeric denominator of 6/x (e.g. 6 means 6/6)

  @HiveField(10)
  String? notes;

  @HiveField(11)
  double? faceDistanceCm;

  @HiveField(12)
  String? odAcuity; // e.g. '6/12'

  @HiveField(13)
  String? osAcuity;

  VisionRecord({
    required this.id,
    required this.createdAt,
    required this.testType,
    this.odSphere,
    this.odCylinder,
    this.odAxis,
    this.osSphere,
    this.osCylinder,
    this.osAxis,
    this.snellenScore,
    this.notes,
    this.faceDistanceCm,
    this.odAcuity,
    this.osAcuity,
  });

  double? get odSphericalEquivalent {
    if (odSphere == null) return null;
    return odSphere! + (odCylinder ?? 0) / 2.0;
  }

  double? get osSphericalEquivalent {
    if (osSphere == null) return null;
    return osSphere! + (osCylinder ?? 0) / 2.0;
  }
}
