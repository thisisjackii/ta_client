//lib/
class Evaluation {
  Evaluation({
    required this.id,
    required this.title,
    required this.yourValue,
    this.idealText,
  });
  factory Evaluation.fromJson(Map<String, dynamic> json) {
    try {
      return Evaluation(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        yourValue: json['yourValue'] as double? ?? 0.0,
        idealText: json['idealText'] as String? ?? '',
      );
    } on Exception catch (e) {
      throw ArgumentError('Invalid type: $e');
    }
  }
  final String id;
  final String title;
  final double yourValue;
  final String? idealText;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'title': title,
      'yourValue': yourValue,
      'idealText': idealText,
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}
