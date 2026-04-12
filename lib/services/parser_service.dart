import 'package:knowyourmed/models/medicine.dart';
import 'package:uuid/uuid.dart';
import 'drug_lookup_service.dart';

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
  final _drugLookup = DrugLookupService();
  static final _uuid = const Uuid();

  /// Main entry – parses raw OCR text.
  Future<Medicine> parse(String rawText) async {
    // 1. Extract bottle-specific details (name, composition, dosage, etc.)
    final parsed = _extractSections(rawText);

    // 2. Generate Identification Candidates (Specific -> Broad -> Generic)
    final List<String> candidates = _generateCandidates(rawText, parsed);
    print('DEBUG: Generated ${candidates.length} search candidates: $candidates');

    // 3. High-Accuracy ID via RxNav & openFDA (Tiered Search)
    final Medicine? officialMatch = await _drugLookup.identify(candidates);

    if (officialMatch != null) {
      // Merge official data with bottle extractions (like expiry)
      return officialMatch.copyWith(
        expiry: parsed.expiry.isNotEmpty ? parsed.expiry : officialMatch.expiry,
        rawText: rawText,
      );
    }

    // 4. OCR Fallback: build an unverified Medicine from label text
    //    (covers Indian/regional brands not in US FDA database)
    print('DEBUG: No official match found – falling back to OCR-only result.');
    return _buildOcrFallback(parsed, rawText);
  }

  /// Constructs an unverified Medicine from raw OCR sections.
  Medicine _buildOcrFallback(ParsedMedicine parsed, String rawText) {
    return Medicine(
      id: _uuid.v4(),
      name: parsed.name,
      composition: parsed.composition.isNotEmpty
          ? parsed.composition
          : parsed.name,
      dosage: parsed.dosage,
      warnings: parsed.warnings,
      storage: parsed.storage,
      manufacturer: parsed.manufacturer,
      expiry: parsed.expiry,
      additionalInfo: parsed.additionalInfo,
      scannedAt: DateTime.now(),
      rawText: rawText,
      medicineClass: '',
      uses: '',
      sideEffects: '',
      isVerified: false,
    );
  }

  // buildMedicine is no longer needed since officialMatch returns a full model

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

    final storageRe = RegExp(r'^(store|storage|keep|protect|shelf\s+life)',
        caseSensitive: false);

    final manufacturerRe = RegExp(
        r'^(mfg\.?|mfr\.?|manufactured\s+by|marketed\s+by|distributed\s+by|marketed\s+&\s+distributed)',
        caseSensitive: false);

    final expiryRe =
        RegExp(r'(exp\.?\s*date|expiry|use\s+before)', caseSensitive: false);

    final expiryValueRe =
        RegExp(r'\b(\d{2}[/\-]\d{4}|\d{2}[/\-]\d{2}[/\-]\d{2,4}|\d{4})\b');

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
          ? lines.firstWhere((l) => l.length > 3,
              orElse: () => 'Unknown Medicine')
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
  List<String> _generateCandidates(String rawText, [ParsedMedicine? parsed]) {
    final lines = rawText.split('\n').map((l) => l.trim()).toList();
    final List<String> candidates = [];

    // 1. Identify Strength Part (e.g., 500mg, 10ml, 5%)
    final strengthRe = RegExp(
        r'(\d+(?:\.\d+)?)\s*(mg|g|ml|mcg|%|units|IU)\b',
        caseSensitive: false);
    String strength = '';
    for (var line in lines) {
      final match = strengthRe.firstMatch(line);
      if (match != null) {
        strength = match.group(0)!;
        break;
      }
    }

    // 2. Identify potential name parts (top of label)
    final noiseKeywords = [
      'tablet', 'capsule', 'daily', 'take', 'expiry', 'exp',
      'lot', 'batch', 'mfd', 'rx only'
    ];
    List<String> validLines = [];
    for (var line in lines.take(6)) {
      if (line.length < 3) continue;
      bool isNoise = noiseKeywords.any((k) => line.toLowerCase().contains(k));
      if (!isNoise) validLines.add(line);
    }

    if (validLines.isNotEmpty) {
      final firstLine = validLines.first;

      // Tier 1: Specific Name + Strength
      if (strength.isNotEmpty) {
        if (firstLine.toLowerCase().contains(strength.toLowerCase())) {
          candidates.add(firstLine);
        } else {
          candidates.add('$firstLine $strength');
        }
      }

      // Tier 2: Pure First Line (brand name only)
      candidates.add(firstLine);

      // Tier 3: Combined top two lines (for multi-word brands)
      if (validLines.length >= 2) {
        candidates.add('${validLines[0]} ${validLines[1]}');
      }
    }

    // Tier 4: Generic / active-ingredient names from composition section
    // This is the key tier for Indian brands like Dolo (Paracetamol),
    // Pantocid (Pantoprazole), etc.
    final compositionText = parsed?.composition ?? '';
    if (compositionText.isNotEmpty) {
      // Split on common separators and extract word-only fragments
      final genericRe = RegExp(r'[A-Za-z][A-Za-z\s\-]+');
      for (final m in genericRe.allMatches(compositionText)) {
        final fragment = m.group(0)!.trim();
        // Must be at least 4 chars and not a common noise word
        if (fragment.length >= 4 &&
            !noiseKeywords.any((k) =>
                fragment.toLowerCase().contains(k))) {
          // Add generic name, and generic + strength for precise lookup
          candidates.add(fragment);
          if (strength.isNotEmpty) {
            candidates.add('$fragment $strength');
          }
        }
      }
    }

    // Deduplicate and filter empty
    return candidates.where((c) => c.trim().isNotEmpty).toSet().toList();
  }
}
