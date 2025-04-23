// lib/features/budgeting/models/expense.dart
class Expense {
  Expense({required this.id, required this.title, required this.value});
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      value: json['value'] as double? ?? 0.0,
    );
  }
  final String id;
  final String title;
  final double value;
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
