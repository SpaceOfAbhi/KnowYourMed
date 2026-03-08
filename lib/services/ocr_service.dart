import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final StringBuffer buffer = StringBuffer();
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
