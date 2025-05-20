// lib/features/budgeting/models/period.dart
import 'package:equatable/equatable.dart';

class FrontendPeriod extends Equatable {
  // Flag to indicate if it's a local, unsynced period

  const FrontendPeriod({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.periodType,
    this.description,
    this.isLocal =
        false, // Default to false, set to true for offline-created periods
  });
  factory FrontendPeriod.fromJson(
    Map<String, dynamic> json, {
    bool local = false,
  }) {
    return FrontendPeriod(
      id: json['id'] as String,
      userId:
          json['userId'] as String? ??
          '', // Backend might not always send userId if context implies
      startDate: DateTime.parse(json['startDate'] as String).toLocal(),
      endDate: DateTime.parse(json['endDate'] as String).toLocal(),
      periodType: json['periodType'] as String,
      description: json['description'] as String?,
      isLocal:
          local, // If deserializing a locally cached object known to be local
    );
  }
  final String id; // Can be backend UUID or local temporary ID
  final String
  userId; // Usually populated when synced from backend or known user context
  final DateTime startDate;
  final DateTime endDate;
  final String periodType; // 'income', 'expense', 'general_evaluation'
  final String? description;
  final bool isLocal;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId':
        userId, // May not be sent for creation if backend infers from auth
    'startDate': startDate.toUtc().toIso8601String(),
    'endDate': endDate.toUtc().toIso8601String(),
    'periodType': periodType,
    if (description != null) 'description': description,
    // 'isLocal' is a client-side flag, not typically sent to backend
  };

  Map<String, dynamic> toCreateApiJson() {
    // For POST /periods
    return {
      'startDate': startDate
          .toUtc()
          .toIso8601String(), // Local to UTC ISO for API
      'endDate': endDate.toUtc().toIso8601String(), // Local to UTC ISO for API
      'periodType': periodType,
      if (description != null) 'description': description,
    };
  }

  Map<String, dynamic> toUpdateApiJson() {
    // For PUT /periods/:id
    return {
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'periodType': periodType,
      if (description != null) 'description': description,
    };
  }

  // copyWith method
  FrontendPeriod copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? periodType,
    String? description,
    bool? isLocal,
  }) {
    return FrontendPeriod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      periodType: periodType ?? this.periodType,
      description: description ?? this.description,
      isLocal: isLocal ?? this.isLocal,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    startDate,
    endDate,
    periodType,
    description,
    isLocal,
  ];
}
