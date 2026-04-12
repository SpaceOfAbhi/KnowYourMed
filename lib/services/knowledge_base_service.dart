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

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Should be copied from assets
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(join('assets', 'data', _dbName));
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        throw Exception('Error copying database from assets: $e');
      }
    }

    return await openDatabase(path, readOnly: true);
  }

  /// Searches for the best medicine match based on raw OCR text.
  /// This uses a hybrid approach:
  /// 1. FTS5 full-text search for coarse matching.
  /// 2. string_similarity for fine-grained ranking of the results.
  Future<Map<String, dynamic>?> findBestMatch(String ocrText) async {
    final db = await database;

    // Normalize OCR text
    final cleanText =
        ocrText.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final words = cleanText
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toSet()
        .toList();

    if (words.isEmpty) return null;

    // We build an FTS query from the words
    // Example: "paracetamol OR amoxicillin OR ..."
    final ftsQuery = words.take(10).join(' OR ');

    // Query the FTS table (FTS4 uses rowid to link to content tables)
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT m.* 
      FROM medicines m
      JOIN medicines_fts f ON m.id = f.rowid
      WHERE f.name MATCH ?
      LIMIT 20
    ''', [ftsQuery]);

    if (results.isEmpty) return null;

    // Fine-grained ranking using Dice's Coefficient (string_similarity)
    Map<String, dynamic>? bestMatch;
    double highestScore = 0;

    for (var result in results) {
      final String name = result['name'].toString().toLowerCase();

      // Check if the name appears in the OCR text using fuzzy matching
      final score = name.bestMatch(words).bestMatch.rating ?? 0.0;

      if (score > highestScore) {
        highestScore = score;
        bestMatch = result;
      }
    }

    // Only return if confidence is high enough (e.g., > 0.4)
    return highestScore > 0.4 ? bestMatch : null;
  }
}
