// lib//features/evaluation/models/history.dart
class History {
  History({
    required this.start,
    required this.end,
    required this.ideal,
    required this.notIdeal,
    required this.incomplete,
  });
  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      start: DateTime.parse(json['start'] as String).toLocal(),
      end: DateTime.parse(json['end'] as String).toLocal(),
      ideal: json['ideal'] as int? ?? 0,
      notIdeal: json['notIdeal'] as int? ?? 0,
      incomplete: json['incomplete'] as int? ?? 0,
    );
  }
  final DateTime start;
  final DateTime end;
  final int ideal;
  final int notIdeal;
  final int incomplete;
  Map<String, dynamic> toJson() {
    return {
      'start': start.toUtc().toIso8601String(), // Store as UTC ISO
      'end': end.toUtc().toIso8601String(), // Store as UTC ISO
      'ideal': ideal,
      'notIdeal': notIdeal,
      'incomplete': incomplete,
    }..removeWhere((key, value) => value == null);
  }
}
