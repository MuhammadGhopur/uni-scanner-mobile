import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<RecognizedText> processImage(InputImage inputImage) {
    return _textRecognizer.processImage(inputImage);
  }

  String normalize(String text) {
    return text.toUpperCase().replaceAll('O', '0').replaceAll('I', '1');
  }

  // ambil PO dari baris ke-4
  String extractPoFromLine4(List<String> lines) {
    if (lines.length < 4) return "";
    final line4 = lines[3].trim();
    final match = RegExp(r'^P\d{5,7}$').firstMatch(line4);
    return match != null ? match.group(0)! : "";
  }

  void dispose() {
    _textRecognizer.close();
  }
}
