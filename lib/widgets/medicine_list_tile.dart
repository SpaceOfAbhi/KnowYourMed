import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'package:intl/intl.dart';

class MedicineListTile extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const MedicineListTile({
    super.key,
    required this.medicine,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(medicine.scannedAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medication_rounded, color: Colors.white, size: 22),
        ),
        title: Text(
          medicine.composition.isEmpty ? 'Unknown Medicine' : medicine.composition,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: theme.colorScheme.error.withOpacity(0.7), size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            Icon(Icons.chevron_right_rounded,
                color: theme.colorScheme.primary.withOpacity(0.7)),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
