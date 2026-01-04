class TextExtractor {
  static String extractWidth(String ocrText) {
    final lines = ocrText.split('\n');
    int lineCount = 0;
    for (final line in lines) {
      if (lineCount >= 5) break; // Limit to first 5 lines to simulate "first paragraph"
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        // Prioritize single characters or short words (like 'M', 'W', 'XL')
        // Exclude lines containing numbers or longer descriptive text
        if (trimmedLine.length <= 2 && !RegExp(r'[0-9]').hasMatch(trimmedLine)) {
           return trimmedLine;
        }
      }
      lineCount++;
    }
    return "";
  }

  static String extractSize(String ocrText) {
    final normalizedOcrText = ocrText.toUpperCase();
    final lines = normalizedOcrText.split('\n');

    final numRegExp = RegExp(r'\b(\d+(?:\.\d+)?)\b'); // Matches numbers like "4", "4.5"
    
    for (int i = 0; i < lines.length; i++) {
      final currentLine = lines[i].trim();
      final numMatch = numRegExp.firstMatch(currentLine);

      if (numMatch != null) {
        final numberString = numMatch.group(1)!;
        final numValue = double.tryParse(numberString);

        // Heuristic: US shoe sizes are typically between 1 and 15 for adults.
        // We'll allow a slightly broader range to account for kids/larger sizes, e.g., up to 20.
        if (numValue != null && numValue > 0 && numValue <= 20) {
          // Check for "US" in the current line
          if (currentLine.contains("US")) {
            return numberString;
          }
          // Check for "US" in the next line
          if (i + 1 < lines.length) {
            final nextLine = lines[i + 1].trim();
            if (nextLine.contains("US")) {
              return numberString;
            }
          }
        }
      }
    }

    return ""; // Return empty string if no valid number-US combination is found
  }
}
