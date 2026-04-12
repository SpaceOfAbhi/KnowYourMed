import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';
import 'package:uuid/uuid.dart';

class DrugLookupService {
  static const String _rxNavBase = 'https://rxnav.nlm.nih.gov/REST';
  static const String _fdaBase = 'https://api.fda.gov/drug/label.json';
  static final _uuid = const Uuid();

  /// Attempt to identify a medicine using both RxNav and openFDA.
  Future<Medicine?> identify(String ocrText) async {
    try {
      // 1. Get standardized name/RxCUI from RxNav (Fuzzy Matching)
      final rxcui = await _findRxCui(ocrText);
      if (rxcui == null) return null;

      // 2. Fetch official label details from openFDA using RxCUI
      return await _fetchFdaDetails(rxcui, ocrText);
    } catch (e) {
      print('DEBUG: Global identification failed: $e');
      return null;
    }
  }

  /// Use RxNav's approximateTerm to find the most likely RxCUI for messy text.
  Future<String?> _findRxCui(String text) async {
    final cleanText = Uri.encodeComponent(text.replaceAll('\n', ' '));
    final url = '$_rxNavBase/approximateTerm.json?term=$cleanText&maxEntries=1';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final candidates = data['approximateGroup']?['candidate'];
    
    if (candidates != null && candidates.isNotEmpty) {
      final best = candidates[0];
      // Only accept relatively strong matches
      if (int.parse(best['score'] ?? '0') > 60) {
        return best['rxcui'];
      }
    }
    return null;
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
    
    // Extract multi-line fields safely
    String extractField(String key) {
      final field = result[key];
      if (field == null) return '';
      if (field is List) return field.join('\n');
      return field.toString();
    }

    final String brandName = (fda['brand_name'] as List?)?.first ?? 'Unknown';
    final String genericName = (fda['generic_name'] as List?)?.first ?? brandName;
    final String manufacture = (fda['manufacturer_name'] as List?)?.first ?? '';

    return Medicine(
      id: _uuid.v4(),
      name: brandName,
      composition: genericName,
      dosage: extractField('dosage_and_administration'),
      warnings: extractField('warnings'),
      storage: extractField('storage_and_handling'),
      manufacturer: manufacture,
      expiry: '', // API unlikely to provide expiry for a specific bottle
      additionalInfo: 'Verified official information from US FDA.',
      scannedAt: DateTime.now(),
      rawText: rawText,
      medicineClass: (fda['pharm_class_epc'] as List?)?.first ?? '',
      uses: extractField('indications_and_usage'),
      sideEffects: extractField('adverse_reactions'),
      isVerified: true,
    );
  }
}
