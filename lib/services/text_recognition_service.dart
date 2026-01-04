import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<RecognizedText> processImage(InputImage inputImage) {
    return _textRecognizer.processImage(inputImage);
  }

  String normalize(String text) {
    return text
        .toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('I', '1');
  }

  void dispose() {
    _textRecognizer.close();
  }
}
