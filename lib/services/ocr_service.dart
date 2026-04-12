import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'image_processor_service.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final _imageProcessor = ImageProcessorService();

  /// Extracts text from [imageFile]. If [roi] is provided, it will 
  /// crop and enhance the image before recognition.
  Future<String> extractText(File imageFile, {Rect? roi}) async {
    try {
      File fileToProcess = imageFile;
      
      if (roi != null) {
        fileToProcess = await _imageProcessor.processForOcr(
          imageFile: imageFile, 
          roi: roi,
        );
      }

      final inputImage = InputImage.fromFile(fileToProcess);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final StringBuffer buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          // Additional cleanup: ignore text that is clearly too short to be 
          // a medicine name or key instruction, unless it's a number.
          if (line.text.length < 2 && !RegExp(r'\d').hasMatch(line.text)) {
            continue;
          }
          buffer.writeln(line.text);
        }
      }

      final result = buffer.toString().trim();
      
      // Log for debugging
      print('DEBUG: Extracted ROI Text:\n$result');
      
      return result;
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
