import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../widgets/info_card.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = medicine;
    final dateStr =
        DateFormat('MMMM d, yyyy • hh:mm a').format(m.scannedAt);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: const Text('Delete Medicine'),
                      content: Text('Remove "${m.name}" from saved medicines?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await StorageService().deleteMedicine(m.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SAVED MEDICINE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            if (m.medicineClass.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m.medicineClass.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          m.name.isEmpty ? 'Unknown Medicine' : m.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              'Scanned: $dateStr',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Key facts row
                if (m.expiry.isNotEmpty || m.manufacturer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        if (m.expiry.isNotEmpty)
                          Expanded(
                            child: _StatChip(
                              icon: Icons.event_rounded,
                              label: 'Expiry',
                              value: m.expiry,
                              color: Colors.orange,
                            ),
                          ),
                        if (m.expiry.isNotEmpty && m.manufacturer.isNotEmpty)
                          const SizedBox(width: 12),
                        if (m.manufacturer.isNotEmpty)
                          Expanded(
                            child: _StatChip(
                              icon: Icons.business_rounded,
                              label: 'Manufacturer',
                              value: m.manufacturer,
                              color: Colors.purple,
                            ),
                          ),
                      ],
                    ),
                  ),

                InfoCard(
                  title: 'Composition',
                  content: m.composition,
                  icon: Icons.science_rounded,
                  accentColor: Colors.blue.shade700,
                ),
                if (m.uses.isNotEmpty)
                  InfoCard(
                    title: 'Common Uses',
                    content: m.uses,
                    icon: Icons.healing_rounded,
                    accentColor: Colors.indigo.shade600,
                  ),
                InfoCard(
                  title: 'Dosage Instructions',
                  content: m.dosage,
                  icon: Icons.schedule_rounded,
                  accentColor: Colors.green.shade700,
                ),
                InfoCard(
                  title: 'Warnings & Precautions',
                  content: m.warnings,
                  icon: Icons.warning_amber_rounded,
                  accentColor: Colors.orange.shade700,
                ),
                if (m.sideEffects.isNotEmpty)
                  InfoCard(
                    title: 'Possible Side Effects',
                    content: m.sideEffects,
                    icon: Icons.assignment_late_rounded,
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

                // Disclaimer
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This information is extracted via OCR and may contain errors. Always consult a healthcare professional before taking any medication.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade800,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
