import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.document_scanner_rounded,
      title: 'Scan Medicine Labels',
      description:
          'Simply point your camera at any medicine strip or box. Our AI-powered OCR instantly reads and extracts all the text from the label.',
      gradient: [Color(0xFF1565C0), Color(0xFF1976D2)],
    ),
    _OnboardingData(
      icon: Icons.analytics_rounded,
      title: 'Understand the Info',
      description:
          'We automatically identify the medicine name, composition, dosage instructions, and more — displayed in clean, easy-to-read sections.',
      gradient: [Color(0xFF0288D1), Color(0xFF0097A7)],
    ),
    _OnboardingData(
      icon: Icons.health_and_safety_rounded,
      title: 'Stay Safe',
      description:
          'View warnings, interactions, and storage instructions at a glance. Save your medicines locally and access them anytime — even offline.',
      gradient: [Color(0xFF00897B), Color(0xFF1565C0)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) =>
                _OnboardingPage(data: _pages[index]),
          ),
          // Dots indicator + buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                              _currentPage == i ? 0.9 : 0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Back'),
                          ),
                        )
                      else
                        Expanded(
                          child: TextButton(
                            onPressed: _finish,
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white70),
                            child: const Text('Skip'),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1565C0),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 60, 32, 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: Icon(data.icon, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 40),
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                data.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
