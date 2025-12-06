class TranslationResult {
  final String text;
  final double confidence;
  final DateTime timestamp;
  final String? mediaPath;
  final MediaType mediaType;

  TranslationResult({
    required this.text,
    required this.confidence,
    required this.timestamp,
    this.mediaPath,
    required this.mediaType,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'mediaPath': mediaPath,
      'mediaType': mediaType.toString(),
    };
  }
}

enum MediaType {
  image,
  video,
  camera,
}





