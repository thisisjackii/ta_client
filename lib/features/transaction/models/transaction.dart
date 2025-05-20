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

class TransactionCategory extends Equatable {
  // Nested
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

class TransactionSubcategory extends Equatable {
  // Nested
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

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.subcategoryId,
    this.isBookmarked = false,
    this.userId,
    this.subcategoryName, // Denormalized for display
    this.categoryId, // Denormalized for display
    this.categoryName, // Denormalized for display
    this.accountTypeId, // << Add this
    this.accountTypeName, // Denormalized for display
    this.isLocal = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    bool markLocal = false, // Used when deserializing from pending queue
  }) {
    try {
      // Prioritize top-level fields if they exist (more common from direct API list response)
      // Fallback to nested 'subcategory' for cached items or detailed API responses
      final subcategoryDataFromTop = json['subcategory'] is Map<String, dynamic>
          ? json['subcategory'] as Map<String, dynamic>
          : null;
      final categoryDataFromTop =
          subcategoryDataFromTop?['category'] is Map<String, dynamic>
          ? subcategoryDataFromTop!['category'] as Map<String, dynamic>
          : null;
      final accountTypeDataFromTop =
          categoryDataFromTop?['accountType'] is Map<String, dynamic>
          ? categoryDataFromTop!['accountType'] as Map<String, dynamic>
          : null;

      return Transaction(
        id:
            json['id'] as String? ??
            (throw ArgumentError('Transaction ID is required')),
        description:
            json['description'] as String? ??
            (throw ArgumentError('Transaction description is required')),
        amount:
            (json['amount'] as num?)?.toDouble() ??
            (throw ArgumentError('Transaction amount is required')),
        date: DateTime.parse(
          json['date'] as String? ??
              (throw ArgumentError('Transaction date is required')),
        ).toLocal(),
        subcategoryId:
            json['subcategoryId'] as String? ??
            subcategoryDataFromTop?['id'] as String? ??
            (throw ArgumentError('Transaction subcategoryId is required')),
        isBookmarked: json['isBookmarked'] as bool? ?? false,
        userId: json['userId'] as String?,
        subcategoryName:
            json['subcategoryName'] as String? ??
            subcategoryDataFromTop?['name'] as String?,
        categoryId:
            json['categoryId'] as String? ??
            categoryDataFromTop?['id'] as String?,
        categoryName:
            json['categoryName'] as String? ??
            categoryDataFromTop?['name'] as String?,
        accountTypeId:
            json['accountTypeId'] as String? ??
            accountTypeDataFromTop?['id'] as String?,
        accountTypeName:
            json['accountTypeName'] as String? ??
            accountTypeDataFromTop?['name'] as String?,
        isLocal: markLocal || (json['isLocal'] as bool? ?? false),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String).toLocal()
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String).toLocal()
            : null,
      );
    } catch (e, s) {
      foundation.debugPrint(
        'Error parsing Transaction from JSON: $json. Error: $e\nStack: $s',
      );
      rethrow; // Rethrow to signal parsing failure
    }
  }

  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String subcategoryId;
  final bool isBookmarked;
  final String? userId;

  final String? subcategoryName;
  final String? categoryId;
  final String? categoryName;
  final String? accountTypeId; // << Add this
  final String? accountTypeName;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isLocal;

  // For sending to backend (create/update)
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'description': description,
      'amount': amount,
      'date': date.toUtc().toIso8601String(), // Send UTC to backend
      'subcategoryId': subcategoryId,
      'isBookmarked': isBookmarked,
    };
    // Only include backend ID for updates (if it's not a local_ ID)
    if (id.isNotEmpty && !id.startsWith('local_')) {
      data['id'] = id;
    }
    return data;
  }

  // For storing in Hive, includes all fields, including denormalized ones and isLocal
  Map<String, dynamic> toJsonForCache() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date
          .toUtc()
          .toIso8601String(), // Store UTC in cache for consistency
      'subcategoryId': subcategoryId,
      'isBookmarked': isBookmarked,
      'userId': userId,
      // Store denormalized fields derived from the full subcategory object if available
      // This structure helps in offline display without needing to join hierarchy data
      // 'subcategoryName': subcategoryName,
      // 'categoryId': categoryId,
      // 'categoryName': categoryName,
      // 'accountTypeId': accountTypeId, // << Add this
      // 'accountTypeName': accountTypeName,
      // Explicitly save the nested structure if you have it fully populated
      // and want to reconstruct it perfectly from cache.
      // Otherwise, relying on the flat denormalized fields above is simpler for cache.
      'subcategory': {
        'id': subcategoryId,
        'name': subcategoryName,
        'category': categoryId != null
            ? {
                'id': categoryId,
                'name': categoryName,
                'accountType': accountTypeName != null
                    ? {
                        // 'id': accountTypeId, // if you have accountTypeId
                        'name': accountTypeName,
                      }
                    : null,
              }
            : null,
      },
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
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
    String? accountTypeId,
    String? accountTypeName,
    bool? isLocal,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      accountTypeId: accountTypeId ?? this.accountTypeId,
      accountTypeName: accountTypeName ?? this.accountTypeName,
      isLocal: isLocal ?? this.isLocal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    accountTypeId,
    accountTypeName,
    isLocal,
    createdAt,
    updatedAt,
  ];
}
