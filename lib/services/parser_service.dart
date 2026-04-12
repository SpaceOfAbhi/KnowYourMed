import '../models/medicine.dart';
import 'package:uuid/uuid.dart';
import 'knowledge_base_service.dart';

class ParsedMedicine {
  final String name;
  final String composition;
  final String dosage;
  final String warnings;
  final String storage;
  final String manufacturer;
  final String expiry;
  final String additionalInfo;
  final String rawText;

  ParsedMedicine({
    required this.name,
    required this.composition,
    required this.dosage,
    required this.warnings,
    required this.storage,
    required this.manufacturer,
    required this.expiry,
    required this.additionalInfo,
    required this.rawText,
  });
}

class ParserService {
  static final _uuid = const Uuid();

  /// Main entry – parses raw OCR text into a structured [Medicine] object.
  Future<Medicine> parse(String rawText) async {
    // 1. Extract generic features from OCR (Heuristic/Regex)
    final parsed = _extractSections(rawText);
    
    // 2. Search for the medicine in the offline Knowledge Base (SQLite)
    final kbService = KnowledgeBaseService();
    final match = await kbService.findBestMatch(rawText);

    // 3. Create enriched Medicine object
    if (match != null) {
      return Medicine(
        id: _uuid.v4(),
        name: match['name'] ?? parsed.name,
        composition: match['composition'] ?? parsed.composition,
        dosage: match['dosage'] ?? parsed.dosage,
        warnings: (match['warnings'] ?? '').isNotEmpty 
            ? match['warnings'] 
            : parsed.warnings,
        storage: parsed.storage,
        manufacturer: parsed.manufacturer,
        expiry: parsed.expiry,
        additionalInfo: parsed.additionalInfo,
        scannedAt: DateTime.now(),
        rawText: rawText,
        medicineClass: match['medicineClass'] ?? '',
        uses: match['uses'] ?? '',
        sideEffects: match['sideEffects'] ?? '',
      );
    }

    // Fallback if no match found in DB
    return Medicine(
      id: _uuid.v4(),
      name: parsed.name,
      composition: parsed.composition,
      dosage: parsed.dosage,
      warnings: parsed.warnings,
      storage: parsed.storage,
      manufacturer: parsed.manufacturer,
      expiry: parsed.expiry,
      additionalInfo: parsed.additionalInfo,
      scannedAt: DateTime.now(),
      rawText: rawText,
    );
  }

  ParsedMedicine _extractSections(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).toList();

    // ── Keyword patterns ────────────────────────────────────────────────────
    final compositionRe = RegExp(
        r'^(composition|contains|each\s*(tablet|capsule|ml|sachet|strip)\s*contains|ingredients)',
        caseSensitive: false);

    final dosageRe = RegExp(
        r'^(dosage|dose|directions?(\s+for\s+use)?|how\s+to\s+use|posology|recommended\s+dose)',
        caseSensitive: false);

    final warningRe = RegExp(
        r'^(warning|caution|contraindication|do\s+not|precaution|adverse\s+effect)',
        caseSensitive: false);

    final storageRe = RegExp(
        r'^(store|storage|keep|protect|shelf\s+life)',
        caseSensitive: false);

    final manufacturerRe = RegExp(
        r'^(mfg\.?|mfr\.?|manufactured\s+by|marketed\s+by|distributed\s+by|marketed\s+&\s+distributed)',
        caseSensitive: false);

    final expiryRe = RegExp(
        r'(exp\.?\s*date|expiry|use\s+before)',
        caseSensitive: false);

    final expiryValueRe = RegExp(
        r'\b(\d{2}[/\-]\d{4}|\d{2}[/\-]\d{2}[/\-]\d{2,4}|\d{4})\b');

    // ── Section buffers ──────────────────────────────────────────────────────
    String name = '';
    final composition = StringBuffer();
    final dosage = StringBuffer();
    final warnings = StringBuffer();
    final storage = StringBuffer();
    final manufacturer = StringBuffer();
    String expiry = '';
    final additional = StringBuffer();

    String? currentSection;
    int nameLineCount = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        currentSection = null;
        continue;
      }

      // ── Detect section headers ─────────────────────────────────────────
      if (compositionRe.hasMatch(line)) {
        currentSection = 'composition';
        final rest = _stripKeyword(line, compositionRe);
        if (rest.isNotEmpty) composition.writeln(rest);
        continue;
      }
      if (dosageRe.hasMatch(line)) {
        currentSection = 'dosage';
        final rest = _stripKeyword(line, dosageRe);
        if (rest.isNotEmpty) dosage.writeln(rest);
        continue;
      }
      if (warningRe.hasMatch(line)) {
        currentSection = 'warnings';
        final rest = _stripKeyword(line, warningRe);
        if (rest.isNotEmpty) warnings.writeln(rest);
        continue;
      }
      if (storageRe.hasMatch(line)) {
        currentSection = 'storage';
        final rest = _stripKeyword(line, storageRe);
        if (rest.isNotEmpty) storage.writeln(rest);
        continue;
      }
      if (manufacturerRe.hasMatch(line)) {
        currentSection = 'manufacturer';
        final rest = _stripKeyword(line, manufacturerRe);
        if (rest.isNotEmpty) manufacturer.writeln(rest);
        continue;
      }
      if (expiryRe.hasMatch(line)) {
        final match = expiryValueRe.firstMatch(line);
        if (match != null) expiry = match.group(0)!;
        currentSection = null;
        continue;
      }

      // ── Append to current section ────────────────────────────────────────
      switch (currentSection) {
        case 'composition':
          composition.writeln(line);
          break;
        case 'dosage':
          dosage.writeln(line);
          break;
        case 'warnings':
          warnings.writeln(line);
          break;
        case 'storage':
          storage.writeln(line);
          break;
        case 'manufacturer':
          manufacturer.writeln(line);
          break;
        default:
          // First 1-2 non-empty lines that look like a bold/title → medicine name
          if (name.isEmpty && nameLineCount < 2) {
            if (_looksLikeName(line)) {
              name = name.isEmpty ? line : '$name $line';
              nameLineCount++;
            } else {
              additional.writeln(line);
            }
          } else {
            additional.writeln(line);
          }
      }
    }

    // Fallback name
    if (name.isEmpty) {
      name = lines.isNotEmpty
          ? lines.firstWhere((l) => l.length > 3, orElse: () => 'Unknown Medicine')
          : 'Unknown Medicine';
    }

    return ParsedMedicine(
      name: name.trim(),
      composition: composition.toString().trim(),
      dosage: dosage.toString().trim(),
      warnings: warnings.toString().trim(),
      storage: storage.toString().trim(),
      manufacturer: manufacturer.toString().trim(),
      expiry: expiry.trim(),
      additionalInfo: additional.toString().trim(),
      rawText: rawText,
    );
  }

  bool _looksLikeName(String line) {
    // Likely a medicine name: mostly alphabetic, short, possibly with
    // numbers (dosage strength), not a sentence.
    final wordCount = line.trim().split(RegExp(r'\s+')).length;
    final hasLower = line.contains(RegExp(r'[a-z]'));
    return wordCount <= 6 && line.length <= 60 && hasLower;
  }

  String _stripKeyword(String line, RegExp re) {
    return line
        .replaceFirst(re, '')
        .replaceFirst(RegExp(r'^[\s:]+'), '')
        .trim();
  }
}
