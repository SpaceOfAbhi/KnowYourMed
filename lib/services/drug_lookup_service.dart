import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';
import 'package:uuid/uuid.dart';

class DrugLookupService {
  static const String _rxNavBase = 'https://rxnav.nlm.nih.gov/REST';
  static const String _fdaBase = 'https://api.fda.gov/drug/label.json';
  static final _uuid = const Uuid();

  /// Tiered identification: tries more specific terms first, then falls back to broader ones.
  Future<Medicine?> identify(List<String> candidates) async {
    for (var candidate in candidates) {
      if (candidate.isEmpty) continue;
      
      try {
        print('DEBUG: Attempting identification with candidate: "$candidate"');
        
        // 1. Get RxCUI from RxNav
        final rxcui = await _findRxCui(candidate);
        if (rxcui == null) continue;

        // 2. Fetch FDA details
        final medicine = await _fetchFdaDetails(rxcui, candidate);
        if (medicine != null) {
          print('DEBUG: Successful identification! Match found for "$candidate"');
          return medicine;
        }
      } catch (e) {
        print('DEBUG: Failed attempt for "$candidate": $e');
        continue;
      }
    }
    return null;
  }

  /// Use RxNav's approximateTerm to find the most likely RxCUI for messy text.
  /// Returns null if the candidate looks like junk, or the match score is too low,
  /// or the returned drug name has no textual overlap with the candidate.
  Future<String?> _findRxCui(String text) async {
    // ── Pre-flight: skip obviously junk candidates ──────────────────────────
    final trimmed = text.trim();
    // Must be at least 3 chars and contain some letters (not just numbers/symbols)
    if (trimmed.length < 3) return null;
    if (!trimmed.contains(RegExp(r'[a-zA-Z]'))) return null;
    // Skip single words that are common noise terms
    const noiseWords = {
      'tablet', 'tablets', 'capsule', 'capsules', 'syrup', 'cream',
      'injection', 'solution', 'drops', 'patch', 'gel', 'ointment',
      'rx', 'only', 'lot', 'batch', 'exp', 'mfg', 'mfd',
    };
    if (noiseWords.contains(trimmed.toLowerCase())) return null;

    final cleanText = Uri.encodeComponent(trimmed.replaceAll('\n', ' '));
    final url = '$_rxNavBase/approximateTerm.json?term=$cleanText&maxEntries=3';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final candidates = data['approximateGroup']?['candidate'];

    if (candidates == null || candidates.isEmpty) return null;

    final best = candidates[0];
    final score = int.tryParse(best['score']?.toString() ?? '0') ?? 0;
    final rxcui = best['rxcui']?.toString();
    final matchedName = (best['name'] ?? '').toString().toLowerCase();

    // ── Score gate: require a high-confidence match ─────────────────────────
    // RxNav scores are 0-100; below 85 is almost certainly a false positive.
    if (score < 85 || rxcui == null) {
      print('DEBUG: Rejected "$trimmed" – score $score < 85');
      return null;
    }

    // ── Name-similarity gate: returned drug name must overlap with input ─────
    // Splits the candidate into words and checks at least one meaningful word
    // (≥4 chars) appears in the matched drug name returned by RxNav.
    final inputWords = trimmed
        .toLowerCase()
        .split(RegExp(r'[\s,/\-()]+'))
        .where((w) => w.length >= 4)
        .toList();

    final hasOverlap = inputWords.any((w) => matchedName.contains(w));
    if (!hasOverlap && inputWords.isNotEmpty) {
      print(
          'DEBUG: Rejected "$trimmed" – no name overlap with RxNav match "$matchedName" (score $score)');
      return null;
    }

    print('DEBUG: Accepted "$trimmed" → rxcui=$rxcui name="$matchedName" score=$score');
    return rxcui;
  }

  /// Use openFDA to get official label details for a given RxCUI.
  Future<Medicine?> _fetchFdaDetails(String rxcui, String rawText) async {
    final url = '$_fdaBase?search=openfda.rxcui:"$rxcui"&limit=1';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final result = data['results']?[0];
    if (result == null) return null;

    final fda = result['openfda'] ?? {};
    
    // Extract multi-line fields with fallback candidates
    String extractField(List<String> keys) {
      for (var key in keys) {
        final field = result[key];
        if (field != null) {
          if (field is List) return field.join('\n');
          final str = field.toString();
          if (str.trim().isNotEmpty) return str;
        }
      }
      return '';
    }

    final String brandName = (fda['brand_name'] as List?)?.first ?? 'Unknown';
    final String genericName = (fda['generic_name'] as List?)?.first ?? brandName;
    final String manufacture = (fda['manufacturer_name'] as List?)?.first ?? '';

    return Medicine(
      id: _uuid.v4(),
      name: brandName,
      composition: genericName,
      dosage: extractField(['dosage_and_administration', 'dosage_forms_and_strengths', 'active_ingredient', 'description']),
      warnings: extractField(['warnings', 'boxed_warning', 'precautions', 'stop_use', 'ask_doctor_or_pharmacist_before_use']),
      storage: extractField(['storage_and_handling', 'how_supplied']),
      manufacturer: manufacture,
      expiry: '', 
      additionalInfo: 'Verified official information from US FDA.',
      scannedAt: DateTime.now(),
      rawText: rawText,
      medicineClass: (fda['pharm_class_epc'] as List?)?.first ?? '',
      uses: extractField(['indications_and_usage', 'purpose', 'usage']),
      sideEffects: extractField(['adverse_reactions', 'side_effects']),
      isVerified: true,
      rxcui: rxcui,
    );
  }

  /// Checks for drug interactions between a target medicine and a list of existing medicines.
  Future<List<Map<String, String>>> checkInteractions(String targetRxcui, List<String> otherRxcuis) async {
    if (otherRxcuis.isEmpty) return [];
    
    final list = [targetRxcui, ...otherRxcuis].join('+');
    final url = '$_rxNavBase/interaction/list.json?rxcuis=$list';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];
      
      final data = json.decode(response.body);
      final interactions = <Map<String, String>>[];
      
      final groupList = data['fullInteractionTypeGroup'] as List?;
      if (groupList == null) return [];
      
      for (var group in groupList) {
        final fullInteractions = group['fullInteractionType'] as List?;
        if (fullInteractions == null) continue;
        
        for (var interaction in fullInteractions) {
          final concepts = interaction['minConcept'] as List?;
          if (concepts == null) continue;
          
          // Only care about interactions involving the newly scanned drug
          bool involvesTarget = concepts.any((c) => c['rxcui'] == targetRxcui);
          if (!involvesTarget) continue;
          
          final listMap = concepts.cast<Map<String,dynamic>>();
          final otherConcept = listMap.firstWhere((c) => c['rxcui'] != targetRxcui, orElse: () => <String,dynamic>{});
          final otherName = otherConcept['name'] ?? 'Unknown Medicine';
          
          final interactionPairs = interaction['interactionPair'] as List?;
          if (interactionPairs == null || interactionPairs.isEmpty) continue;
          
          final pair = interactionPairs.first;
          final description = pair['description'] ?? 'Potential interaction detected.';
          final severity = pair['severity'] ?? 'N/A';
          
          interactions.add({
            'interactingDrug': otherName.toString(),
            'description': description.toString(),
            'severity': severity.toString().toLowerCase() == 'high' ? 'High' : 'Moderate',
          });
        }
      }
      return interactions;
    } catch (e) {
      print('DEBUG: Interaction check failed: $e');
      return [];
    }
  }
}
