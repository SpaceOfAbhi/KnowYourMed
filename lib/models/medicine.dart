import 'package:hive/hive.dart';

part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String composition;

  @HiveField(3)
  String dosage;

  @HiveField(4)
  String warnings;

  @HiveField(5)
  String storage;

  @HiveField(6)
  String manufacturer;

  @HiveField(7)
  String expiry;

  @HiveField(8)
  String additionalInfo;

  @HiveField(9)
  DateTime scannedAt;

  @HiveField(10)
  String rawText;

  Medicine({
    required this.id,
    required this.name,
    required this.composition,
    required this.dosage,
    required this.warnings,
    required this.storage,
    required this.manufacturer,
    required this.expiry,
    required this.additionalInfo,
    required this.scannedAt,
    required this.rawText,
  });

  Medicine copyWith({
    String? id,
    String? name,
    String? composition,
    String? dosage,
    String? warnings,
    String? storage,
    String? manufacturer,
    String? expiry,
    String? additionalInfo,
    DateTime? scannedAt,
    String? rawText,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      composition: composition ?? this.composition,
      dosage: dosage ?? this.dosage,
      warnings: warnings ?? this.warnings,
      storage: storage ?? this.storage,
      manufacturer: manufacturer ?? this.manufacturer,
      expiry: expiry ?? this.expiry,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      scannedAt: scannedAt ?? this.scannedAt,
      rawText: rawText ?? this.rawText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'composition': composition,
      'dosage': dosage,
      'warnings': warnings,
      'storage': storage,
      'manufacturer': manufacturer,
      'expiry': expiry,
      'additionalInfo': additionalInfo,
      'scannedAt': scannedAt.toIso8601String(),
      'rawText': rawText,
    };
  }

  bool get isEmpty =>
      name.isEmpty &&
      composition.isEmpty &&
      dosage.isEmpty &&
      warnings.isEmpty;
}
