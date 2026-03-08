import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/medicine.dart';
import '../widgets/medicine_list_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  List<Medicine> _recentMedicines = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  void _loadRecents() {
    setState(() {
      _recentMedicines = _storageService.getAllMedicines().take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KnowYourMed',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Understand your medicines',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Scan CTA
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/scan')
                            .then((_) => _loadRecents()),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.document_scanner_rounded,
                                  color: colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Scan Medicine',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Point camera at medicine label',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  color: Colors.white70, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Recent scans
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Scans',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/saved')
                        .then((_) => _loadRecents()),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          ),

          if (_recentMedicines.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 64, color: colorScheme.primary.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'No scans yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan a medicine label to get started',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final medicine = _recentMedicines[index];
                  return MedicineListTile(
                    medicine: medicine,
                    onTap: () => Navigator.pushNamed(context, '/detail',
                            arguments: {'medicine': medicine})
                        .then((_) => _loadRecents()),
                  );
                },
                childCount: _recentMedicines.length,
              ),
            ),

          // Quick actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.bookmark_rounded,
                      label: 'Saved\nMedicines',
                      onTap: () => Navigator.pushNamed(context, '/saved')
                          .then((_) => _loadRecents()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.history_rounded,
                      label: 'Scan\nHistory',
                      onTap: () => Navigator.pushNamed(context, '/saved')
                          .then((_) => _loadRecents()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.settings_rounded,
                      label: 'App\nSettings',
                      onTap: () => Navigator.pushNamed(context, '/settings')
                          .then((_) => _loadRecents()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
