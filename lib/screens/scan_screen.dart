
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/scan_overlay.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _captureImage({bool fromGallery = false}) async {
    setState(() => _isLoading = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) {
        setState(() => _isLoading = false);
        return;
      }
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        '/processing',
        arguments: {'imagePath': file.path},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open camera: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dark background with instructions
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D1117), Color(0xFF1A237E)],
              ),
            ),
          ),

          // Scan frame overlay
          const ScanOverlay(),

          // Safe-area content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'Scan Medicine',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(),

                // Frame label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'Align medicine label within the frame',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),

                const Spacer(),

                // Bottom controls
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gallery
                      _CircleButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: _isLoading
                            ? null
                            : () => _captureImage(fromGallery: true),
                        size: 52,
                      ),

                      // Capture
                      GestureDetector(
                        onTap: _isLoading ? null : () => _captureImage(),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLoading
                                ? Colors.white38
                                : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF1565C0),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_rounded,
                                  size: 32,
                                  color: Color(0xFF1565C0),
                                ),
                        ),
                      ),

                      // Tips
                      _CircleButton(
                        icon: Icons.tips_and_updates_rounded,
                        label: 'Tips',
                        onTap: () => _showTips(context),
                        size: 52,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTips(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scanning Tips',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 16),
            ...[
              ('Good Lighting', 'Scan in bright light for best results'),
              ('Hold Steady', 'Keep the camera still when capturing'),
              ('Fill the Frame', 'Align the label to fill the scan area'),
              ('Flat Surface', 'Flatten the strip or box for clearer text'),
            ].map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tip.$1,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(tip.$2,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white70, size: size * 0.44),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}
