class Transaction {
  Transaction({
    required this.id,
    required this.type,
    required this.description,
    required this.date,
    required this.category,
    required this.subcategory,
    required this.amount,
    required this.isBookmarked,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      return Transaction(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        description: json['description'] as String? ?? '',
        date: DateTime.parse(json['date'] as String? ?? '').toLocal(),
        category: json['category'] as String? ?? '',
        subcategory: json['subcategory'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        isBookmarked: json['isBookmarked'] as bool? ?? false,
      );
    } on FormatException catch (e) {
      throw ArgumentError('Invalid date format: ${e.message}');
    } on Exception catch (e) {
      throw ArgumentError('Invalid type: $e');
    }
  }
  final String id;
  final String type;
  final String description;
  final DateTime date;
  final String category;
  final String subcategory;
  final double amount;
  final bool isBookmarked;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'type': type,
      'description': description,
      'date': date.toUtc().toIso8601String(),
      'category': category,
      'subcategory': subcategory,
      'amount': amount,
      'isBookmarked': isBookmarked,
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}
