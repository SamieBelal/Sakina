class ReflectVerse {
  final String arabic;
  final String translation;
  final String reference;

  const ReflectVerse({
    required this.arabic,
    required this.translation,
    required this.reference,
  });

  bool get isComplete =>
      arabic.trim().isNotEmpty &&
      translation.trim().isNotEmpty &&
      reference.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'arabic': arabic,
        'translation': translation,
        'reference': reference,
      };

  factory ReflectVerse.fromJson(Map<String, dynamic> json) => ReflectVerse(
        arabic: json['arabic'] as String? ?? '',
        translation: json['translation'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
      );
}

typedef SavedVerse = ReflectVerse;
