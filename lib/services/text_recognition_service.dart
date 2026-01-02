import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<RecognizedText> processImage(InputImage inputImage) async {
    return await _textRecognizer.processImage(inputImage);
  }

  String normalize(String text) {
    return text.toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('I', '1');
  }

  String extractWidth(List<String> lines) {
    const valid = ['M', 'D', 'W', 'N', 'E'];
    for (final l in lines) {
      final t = l.trim();
      if (valid.contains(t) && t.length == 1) return t;
    }
    return "";
  }

  String extractSku(String text) {
    final m = RegExp(r'\bGR[A-Z0-9]{4,6}\b').firstMatch(text);
    return m != null ? m.group(0)! : "";
  }

  String extractPo(String text) {
    final m = RegExp(r'\bP\d{5,7}\b').firstMatch(text);
    return m != null ? m.group(0)! : "";
  }

  String extractUsSize(List<String> lines) {
    for (final l in lines) {
      final m = RegExp(r'(\d{1,2}(\.\d)?)\s*US').firstMatch(l);
      if (m != null) return m.group(1)!;
    }
    return "";
  }

  void dispose() {
    _textRecognizer.close();
  }
}

