// lib/features/evaluation/models/evaluation.dart
class Evaluation {
  // optional per-component values

  Evaluation({
    required this.id,
    required this.title,
    required this.yourValue,
    required this.isIdeal,
    this.idealText,
    this.breakdown,
  });

  /// For detail screens we may include breakdown values.
  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      id: json['id'] as String,
      title: json['title'] as String,
      yourValue: (json['yourValue'] as num).toDouble(),
      isIdeal: json['isIdeal'] as bool,
      idealText: json['idealText'] as String?,
      breakdown: (json['breakdown'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      ),
    );
  }
  final String id;
  final String title;
  final double yourValue; // actual computed ratio
  final bool isIdeal;
  final String? idealText; // e.g. "3–6 Bulan", "> 15%"
  final Map<String, double>? breakdown;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'yourValue': yourValue,
    'isIdeal': isIdeal,
    if (idealText != null) 'idealText': idealText,
    if (breakdown != null) 'breakdown': breakdown,
  };
}
