import 'dart:io';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageProcessorService {
  /// Crops the image to the [roi] (Region of Interest) and applies 
  /// enhancements like grayscale and contrast boosting.
  Future<File> processForOcr({
    required File imageFile,
    required Rect roi, // Logical coordinates (0.0 to 1.0)
  }) async {
    // 1. Load the image
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return imageFile;

    // 2. Identify physical crop coordinates
    // roi is passed as normalized (0.0 - 1.0) values of the preview
    final int cropX = (roi.left * image.width).toInt();
    final int cropY = (roi.top * image.height).toInt();
    final int cropW = (roi.width * image.width).toInt();
    final int cropH = (roi.height * image.height).toInt();

    // 3. Perform cropping
    img.Image cropped = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    // 4. Enhancements (Grayscale + Contrast)
    // Grayscale helps ML Kit focus on shapes rather than colors
    img.Image enhanced = img.grayscale(cropped);
    
    // Boost contrast slightly to make text sharper
    enhanced = img.contrast(enhanced, contrast: 120);

    // 5. Save processed image to a temporary file
    final tempDir = await getTemporaryDirectory();
    final String fileName = 'ocr_prep_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = path.join(tempDir.path, fileName);
    
    final processedFile = File(filePath);
    await processedFile.writeAsBytes(img.encodeJpg(enhanced, quality: 85));

    return processedFile;
  }
}
