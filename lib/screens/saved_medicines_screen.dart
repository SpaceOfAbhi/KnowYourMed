import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/medicine.dart';
import '../widgets/medicine_list_tile.dart';

class SavedMedicinesScreen extends StatefulWidget {
  const SavedMedicinesScreen({super.key});

  @override
  State<SavedMedicinesScreen> createState() => _SavedMedicinesScreenState();
}

class _SavedMedicinesScreenState extends State<SavedMedicinesScreen> {
  final _storageService = StorageService();
  List<Medicine> _medicines = [];
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMedicines() {
    setState(() {
      _medicines = _storageService.getAllMedicines();
    });
  }

  List<Medicine> get _filtered {
    if (_searchQuery.isEmpty) return _medicines;
    return _medicines
        .where((m) =>
            m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            m.composition.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Medicine'),
        content: Text('Remove "${medicine.name}" from saved medicines?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storageService.deleteMedicine(medicine.id);
      _loadMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Medicines'),
        actions: [
          if (_medicines.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear All',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Clear All'),
                    content: const Text(
                        'This will permanently delete all saved medicines.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _storageService.clearAll();
                  _loadMedicines();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Count
          if (_medicines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} medicine${filtered.length != 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.bookmark_border_rounded,
                          size: 72,
                          color: theme.colorScheme.primary.withOpacity(0.25),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results for "$_searchQuery"'
                              : 'No saved medicines',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Scan a medicine and tap "Save Medicine"',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final medicine = filtered[index];
                      return MedicineListTile(
                        medicine: medicine,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: {'medicine': medicine},
                        ).then((_) => _loadMedicines()),
                        onDelete: () => _deleteMedicine(medicine),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/scan').then((_) => _loadMedicines()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Scan New'),
      ),
    );
  }
}
