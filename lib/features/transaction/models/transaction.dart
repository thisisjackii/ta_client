// lib/features/transaction/models/transaction.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' as foundation;

// Assuming these models are also defined for hierarchy if not already
// These are simplified representations of what might be nested in a full Transaction object from backend
class TransactionAccountType extends Equatable {

  const TransactionAccountType({required this.id, required this.name});

  factory TransactionAccountType.fromJson(Map<String, dynamic> json) {
    return TransactionAccountType(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
  final String id;
  final String name;
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  @override
  List<Object?> get props => [id, name];
}

class TransactionCategory extends Equatable { // Nested

  const TransactionCategory({
    required this.id,
    required this.name,
    this.accountType,
  });

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      accountType: json['accountType'] != null
          ? TransactionAccountType.fromJson(
              json['accountType'] as Map<String, dynamic>,
            )
          : null,
    );
  }
  final String id;
  final String name;
  final TransactionAccountType? accountType;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'accountType': accountType?.toJson(),
  };
  @override
  List<Object?> get props => [id, name, accountType];
}

class TransactionSubcategory extends Equatable { // Nested

  const TransactionSubcategory({
    required this.id,
    required this.name,
    this.category,
  });

  factory TransactionSubcategory.fromJson(Map<String, dynamic> json) {
    return TransactionSubcategory(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] != null
          ? TransactionCategory.fromJson(
              json['category'] as Map<String, dynamic>,
            )
          : null,
    );
  }
  final String id;
  final String name;
  final TransactionCategory? category;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category?.toJson(),
  };
  @override
  List<Object?> get props => [id, name, category];
}

class Transaction extends Equatable { // Client-side flag for offline/pending sync status

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.subcategoryId,
    this.isBookmarked = false,
    this.userId,
    this.subcategoryName,
    this.categoryId,
    this.categoryName,
    this.accountTypeName,
    this.isLocal = false, // Default for newly created objects
  });

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    bool markLocal = false,
  }) {
    try {
      final subcategoryData = json['subcategory'] as Map<String, dynamic>?;
      final categoryData =
          subcategoryData?['category'] as Map<String, dynamic>?;
      final accountTypeData =
          categoryData?['accountType'] as Map<String, dynamic>?;

      return Transaction(
        id: json['id'] as String? ?? '', // Backend should always provide ID
        description: json['description'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.parse(
          json['date'] as String? ?? DateTime.now().toIso8601String(),
        ).toLocal(),
        subcategoryId:
            json['subcategoryId'] as String? ??
            subcategoryData?['id'] as String? ??
            '',
        isBookmarked: json['isBookmarked'] as bool? ?? false,
        userId: json['userId'] as String?,
        subcategoryName: subcategoryData?['name'] as String?,
        categoryId: categoryData?['id'] as String?,
        categoryName: categoryData?['name'] as String?,
        accountTypeName: accountTypeData?['name'] as String?,
        isLocal: markLocal || (json['isLocal'] as bool? ?? false),
      );
    } catch (e) {
      foundation.debugPrint(
        'Error parsing Transaction from JSON: $json. Error: $e',
      );
      // Fallback or rethrow
      throw ArgumentError('Invalid Transaction JSON structure: $e');
    }
  }
  final String id; // Backend UUID or local temporary ID for offline
  final String description;
  final double amount;
  final DateTime date;
  final String subcategoryId; // Foreign key
  final bool isBookmarked;
  final String? userId; // Optional, backend infers from token

  // Denormalized/derived fields for easy display, populated from nested subcategory object
  final String? subcategoryName;
  final String? categoryId;
  final String? categoryName;
  final String? accountTypeName; // e.g., "Pemasukan", "Pengeluaran"

  final bool isLocal;

  Map<String, dynamic> toJson() {
    // For sending to backend (create/update)
    final data = <String, dynamic>{
      'description': description,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
      'subcategoryId': subcategoryId, // Backend expects this ID
      'isBookmarked': isBookmarked,
      // userId is usually not sent, inferred from token by backend
    };
    if (id.isNotEmpty && !id.startsWith('local_')) {
      // Only include backend ID for updates
      data['id'] = id;
    }
    return data;
  }

  Map<String, dynamic> toJsonForCache() {
    // For storing in Hive, includes all fields
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
      'subcategoryId': subcategoryId,
      'isBookmarked': isBookmarked,
      'userId': userId,
      // Store denormalized fields in cache for faster offline display
      'subcategory': subcategoryName != null
          ? {
              'id': subcategoryId,
              'name': subcategoryName,
              'category': categoryName != null
                  ? {
                      'id': categoryId,
                      'name': categoryName,
                      'accountType': accountTypeName != null
                          ? {'name': accountTypeName}
                          : null,
                    }
                  : null,
            }
          : null,
      'isLocal': isLocal,
    };
  }

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? subcategoryId,
    bool? isBookmarked,
    String? userId,
    String? subcategoryName,
    String? categoryId,
    String? categoryName,
    String? accountTypeName,
    bool? isLocal,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      userId: userId ?? this.userId,
      subcategoryName: subcategoryName ?? this.subcategoryName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      accountTypeName: accountTypeName ?? this.accountTypeName,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    date,
    subcategoryId,
    isBookmarked,
    userId,
    subcategoryName,
    categoryId,
    categoryName,
    accountTypeName,
    isLocal,
  ];
}
