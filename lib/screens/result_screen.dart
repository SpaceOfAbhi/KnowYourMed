import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../widgets/info_card.dart';

class ResultScreen extends StatefulWidget {
  final Medicine medicine;
  final List<Map<String, String>>? interactions;
  const ResultScreen({super.key, required this.medicine, this.interactions});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _storageService = StorageService();
  bool _isSaved = false;

  Future<void> _saveMedicine() async {
    await _storageService.saveMedicine(widget.medicine);
    if (!mounted) return;
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Medicine saved successfully!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = widget.medicine;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          m.composition.isEmpty ? 'Unknown Medicine' : m.composition,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (m.isVerified || m.expiry.isNotEmpty || m.medicineClass.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (m.isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade400,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified_rounded, size: 10, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text(
                                        'VERIFIED BY FDA',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (m.medicineClass.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    m.medicineClass,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              if (m.expiry.isNotEmpty) ...[
                                const Icon(Icons.event_rounded,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  'Exp: ${m.expiry}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (widget.interactions != null && widget.interactions!.isNotEmpty)
                  _InteractionAlert(interactions: widget.interactions!),
                  
                InfoCard(
                  title: 'Composition',
                  content: m.composition,
                  icon: Icons.science_rounded,
                  accentColor: Colors.blue.shade700,
                ),
                InfoCard(
                  title: 'Common Uses',
                  content: m.uses,
                  icon: Icons.healing_rounded,
                  accentColor: Colors.indigo.shade600,
                ),
                InfoCard(
                  title: 'Usage & Dosage',
                  content: m.dosage,
                  icon: Icons.schedule_rounded,
                  accentColor: Colors.green.shade700,
                ),
                InfoCard(
                  title: 'Warnings',
                  content: m.warnings,
                  icon: Icons.warning_amber_rounded,
                  accentColor: Colors.orange.shade700,
                ),
                InfoCard(
                  title: 'Side Effects',
                  content: m.sideEffects,
                  icon: Icons.report_problem_rounded,
                  accentColor: Colors.red.shade600,
                ),
                InfoCard(
                  title: 'Storage Instructions',
                  content: m.storage,
                  icon: Icons.thermostat_rounded,
                  accentColor: Colors.teal.shade600,
                ),
                if (m.additionalInfo.isNotEmpty)
                  InfoCard(
                    title: 'Additional Information',
                    content: m.additionalInfo,
                    icon: Icons.info_outline_rounded,
                    accentColor: Colors.blueGrey.shade600,
                  ),

                // Raw text toggle
                _RawTextSection(rawText: m.rawText),

                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/scan', (r) => r.settings.name == '/home');
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Scan Again'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSaved ? null : _saveMedicine,
                icon: Icon(_isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded),
                label: Text(_isSaved ? 'Saved' : 'Save Medicine'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawTextSection extends StatefulWidget {
  final String rawText;
  const _RawTextSection({required this.rawText});

  @override
  State<_RawTextSection> createState() => _RawTextSectionState();
}

class _RawTextSectionState extends State<_RawTextSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.text_snippet_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 8),
                  Text(
                    'Raw OCR Text',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.rawText.isEmpty ? 'No text extracted' : widget.rawText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InteractionAlert extends StatelessWidget {
  final List<Map<String, String>> interactions;
  
  const _InteractionAlert({required this.interactions});

  @override
  Widget build(BuildContext context) {
    bool hasHigh = interactions.any((i) => i['severity'] == 'High');
    final color = hasHigh ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasHigh ? 'Critical Interaction Alert' : 'Potential Interactions detected',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This medicine interacts with your saved medications:',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...interactions.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('• ${i['interactingDrug']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                 if ((i['description'] ?? '').isNotEmpty)
                   Padding(
                     padding: const EdgeInsets.only(left: 12, top: 2),
                     child: Text(i['description']!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), fontSize: 12)),
                   ),
               ]
            ),
          )),
        ],
      ),
    );
  }
}
