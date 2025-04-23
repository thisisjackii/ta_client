// lib/features/budgeting/models/allocation.dart
class Allocation {
  Allocation({required this.id, required this.title, required this.target});
  factory Allocation.fromJson(Map<String, dynamic> json) {
    try {
      return Allocation(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        target: json['target'] as double? ?? 0.0,
      );
    } on Exception catch (e) {
      throw ArgumentError('Invalid type: $e');
    }
  }
  final String id;
  final String title;
  final double target;
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'title': title,
      'target': target,
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}
