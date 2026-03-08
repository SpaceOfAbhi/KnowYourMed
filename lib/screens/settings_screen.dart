import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Appearance section
          _SectionHeader(title: 'Appearance'),
          _SettingsCard(
            children: [
              SwitchListTile(
                value: settings.isDarkMode,
                onChanged: (v) => settings.setDarkMode(v),
                title: const Text('Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Switch between light and dark themes'),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    settings.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),

          // Text size section
          _SectionHeader(title: 'Accessibility'),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.text_fields_rounded,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Text Size',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            _textSizeLabel(settings.textSize),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.text_decrease_rounded, size: 18),
                    Expanded(
                      child: Slider(
                        value: settings.textSize,
                        min: 0.8,
                        max: 1.4,
                        divisions: 3,
                        onChanged: (v) => settings.setTextSize(v),
                      ),
                    ),
                    const Icon(Icons.text_increase_rounded, size: 22),
                  ],
                ),
              ),
            ],
          ),

          // About section
          _SectionHeader(title: 'About'),
          _SettingsCard(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.info_outline_rounded,
                      color: theme.colorScheme.primary),
                ),
                title: const Text('App Version',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: Text('1.0.0',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.gavel_rounded, color: Colors.orange),
                ),
                title: const Text('Medical Disclaimer',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showDisclaimer(context),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.privacy_tip_rounded,
                      color: Colors.green),
                ),
                title: const Text('Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showPrivacy(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
          // App branding footer
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medication_liquid_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 8),
                const Text('KnowYourMed',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Understand every medicine you take',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _textSizeLabel(double size) {
    if (size <= 0.8) return 'Small';
    if (size <= 1.0) return 'Normal';
    if (size <= 1.2) return 'Large';
    return 'Extra Large';
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.gavel_rounded,
                color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Medical Disclaimer'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'KnowYourMed uses Optical Character Recognition (OCR) technology to extract text from medicine labels. '
            'The extracted information may not be perfectly accurate due to image quality, label damage, or OCR limitations.\n\n'
            'This app is NOT a substitute for professional medical advice. Always:\n'
            '• Consult a licensed healthcare professional before taking any medication.\n'
            '• Verify information with the original medicine packaging.\n'
            '• Contact a pharmacist or doctor for specific medical questions.\n\n'
            'The developers of KnowYourMed are not liable for any health decisions made based on information provided by this app.',
            style: TextStyle(height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_rounded,
                color: Colors.green.shade700, size: 22),
            const SizedBox(width: 8),
            const Text('Privacy Policy'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Your Privacy:\n\n'
            '• All data stays on your device — we collect no personal information.\n'
            '• Medicine scans and saved data are stored locally using secure on-device storage.\n'
            '• OCR processing is performed entirely on-device — no images are sent to any server.\n'
            '• Camera access is used only when you initiate a scan.\n\n'
            'We respect your privacy and are committed to keeping your health data secure.',
            style: TextStyle(height: 1.6),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }
}
