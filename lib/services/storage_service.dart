import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine.dart';

class StorageService {
  static const String _boxName = 'medicines';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(MedicineAdapter());
    await Hive.openBox<Medicine>(_boxName);
  }

  Box<Medicine> get _box => Hive.box<Medicine>(_boxName);

  Future<void> saveMedicine(Medicine medicine) async {
    await _box.put(medicine.id, medicine);
  }

  Future<void> deleteMedicine(String id) async {
    await _box.delete(id);
  }

  List<Medicine> getAllMedicines() {
    final medicines = _box.values.toList();
    medicines.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return medicines;
  }

  Medicine? getMedicineById(String id) {
    return _box.get(id);
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  int get count => _box.length;
}
