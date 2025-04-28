// lib/features/transaction/models/transaction.dart
class Transaction {
  Transaction({
    required this.id,
    required this.categoryId,
    required this.accountType,
    required this.description,
    required this.date,
    required this.categoryName,
    required this.subcategoryName,
    required this.amount,
    required this.isBookmarked,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      final cat = json['category'] as Map<String, dynamic>? ?? {};
      return Transaction(
        id: json['id'] as String? ?? '',
        categoryId: json['categoryId'] as String? ?? '',
        accountType: cat['accountType'] as String? ?? '',
        description: json['description'] as String? ?? '',
        date: DateTime.parse(json['date'] as String? ?? '').toLocal(),
        categoryName: cat['categoryName'] as String? ?? '',
        subcategoryName: cat['subcategoryName'] as String? ?? '',
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
  final String categoryId;
  final String accountType;
  final String description;
  final DateTime date;
  final String categoryName;
  final String subcategoryName;
  final double amount;
  final bool isBookmarked;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'categoryId': categoryId,
      'description': description,
      'date': date.toUtc().toIso8601String(),
      'amount': amount,
      'isBookmarked': isBookmarked,
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }
}
