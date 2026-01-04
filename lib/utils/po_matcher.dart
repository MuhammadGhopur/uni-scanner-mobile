class PoMatcher {
  static String? findPoFromOcr({
    required String ocrText,
    required List<String> poList,
  }) {
    final text = ocrText
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '');
    for (final po in poList) {
      final cleanPo = po
          .toUpperCase()
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(RegExp(r'"'), '');

      if (cleanPo.isEmpty) continue;

      if (text.contains(cleanPo)) {
        return po;
      }
    }
    return null;
  }
}
