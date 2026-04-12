import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:string_similarity/string_similarity.dart';

class KnowledgeBaseService {
  static Database? _database;
  static const String _dbName = 'medicines.db';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    print('DEBUG: Expected DB Path: $path');

    final exists = await databaseExists(path);

    if (!exists) {
      print('DEBUG: DB not found at path. Attempting copy from assets...');
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets', 'data', _dbName));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        print('DEBUG: Copy successful. Size: ${bytes.length} bytes');
      } catch (e) {
        print('DEBUG: FATAL - Asset copy failed: $e');
        throw Exception('Error copying database from assets: $e');
      }
    } else {
      final size = await File(path).length();
      print('DEBUG: DB exists on disk. Size: $size bytes');
    }

    final db = await openDatabase(path, readOnly: true);

    try {
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM medicines'));
      print('DEBUG: Row count in medicines table: $count');
    } catch (e) {
      print('DEBUG: Row count check failed: $e');
    }

    return db;
  }

  /// Searches for potential medicine matches based on raw OCR text.
  /// Returns a list of candidates sorted by confidence score.
  Future<List<Map<String, dynamic>>> findTopMatches(String ocrText) async {
    final db = await database;

    // Normalize OCR text
    final cleanText =
        ocrText.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    // Common words to ignore
    final stopWords = {
      'tablet',
      'capsule',
      'mg',
      'ml',
      'dosage',
      'directions',
      'contains',
      'expiry',
      'manufactured',
      'warning',
      'keep',
      'store',
      'reach',
      'children',
      'daily'
    };

    final words =
        cleanText.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    print('DEBUG: OCR Words found: $words');

    if (words.isEmpty) return [];

    // FTS query using the most unique-looking words
    final ftsQuery = words
        .where((w) => !stopWords.contains(w) && w.length > 3)
        .take(15)
        .join(' OR ');

    if (ftsQuery.isEmpty) return [];

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT m.* 
      FROM medicines m
      JOIN medicines_fts f ON m.id = f.rowid
      WHERE f.name MATCH ?
      LIMIT 50
    ''', [ftsQuery]);

    // Simplify for fallback: return FTS results with a basic confidence score
    return results.map((r) {
      final res = Map<String, dynamic>.from(r);
      res['confidence'] = 1.0; // Basic confidence for FTS match
      return res;
    }).toList();
  }
}
