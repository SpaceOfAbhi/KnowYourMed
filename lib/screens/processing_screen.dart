import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ocr_service.dart';
import '../services/parser_service.dart';


class ProcessingScreen extends StatefulWidget {
  final String imagePath;
  const ProcessingScreen({super.key, required this.imagePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  String _statusText = 'Reading medicine label...';

  final List<String> _steps = [
    'Reading medicine label...',
    'Analyzing text structure...',
    'Extracting medicine info...',
    'Organizing data...',
  ];
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _runProcessing();
  }

  Future<void> _runProcessing() async {
    // Step cycling for UX
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _statusText = _steps[i];
        _stepIndex = i;
      });
    }

    try {
      final file = File(widget.imagePath);
      final ocrService = OcrService();
      final rawText = await ocrService.extractText(file);
      ocrService.dispose();

      final parserService = ParserService();
      final medicine = await parserService.parse(rawText);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: {'medicine': medicine},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing image: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 2),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Analyzing Medicine Label',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusText,
                    key: ValueKey(_statusText),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Progress steps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: List.generate(_steps.length, (i) {
                      final isDone = i < _stepIndex;
                      final isActive = i == _stepIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? Colors.white
                                    : isActive
                                        ? Colors.white.withOpacity(0.4)
                                        : Colors.white.withOpacity(0.15),
                              ),
                              child: isDone
                                  ? const Icon(Icons.check_rounded,
                                      size: 14, color: Color(0xFF1565C0))
                                  : isActive
                                      ? const Padding(
                                          padding: EdgeInsets.all(5),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _steps[i],
                              style: TextStyle(
                                color: isDone || isActive
                                    ? Colors.white
                                    : Colors.white38,
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
