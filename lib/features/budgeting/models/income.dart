// lib/features/budgeting/models/income.dart
class Income {
  Income({required this.id, required this.title, required this.value});

  factory Income.fromJson(Map<String, dynamic> json) {
    try {
      return Income(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        value: json['value'] as int? ?? 0,
      );
    } on Exception catch (e) {
      throw ArgumentError('Invalid type: $e');
    }
  }
  final String id;
  final String title;
  final int value;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'title': title,
      'value': value,
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}
