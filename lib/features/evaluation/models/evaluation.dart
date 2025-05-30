// lib/features/evaluation/models/evaluation.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

enum EvaluationStatusModel { ideal, notIdeal, incomplete }

class ConceptualComponentValue extends Equatable {
  const ConceptualComponentValue({required this.name, required this.value});

  factory ConceptualComponentValue.fromJson(Map<String, dynamic> json) {
    return ConceptualComponentValue(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }
  final String name;
  final double value;

  @override
  List<Object?> get props => [name, value];
}

class Evaluation extends Equatable {
  const Evaluation({
    required this.id, // Can be Ratio.id (from backend) or client-side '0', '1'
    required this.title,
    required this.yourValue,
    required this.isIdeal,
    required this.status,
    required this.calculatedAt,
    this.startDate, // ADDED for evaluation scope
    this.endDate, // ADDED for evaluation scope
    // ratioId is essentially 'id' if it's from backend Ratio.id
    this.idealText,
    this.breakdown,
    this.backendRatioCode,
    this.backendEvaluationResultId, // This is the DB ID of the EvaluationResult record
  });

  // This factory needs to handle various JSON structures it might receive
  factory Evaluation.fromJson(Map<String, dynamic> json) {
    final ratioData = json['ratio'] as Map<String, dynamic>?;
    final value = (json['value'] as num? ?? 0).toDouble();
    final statusStringFromJson =
        (json['status'] as String?)?.toUpperCase().replaceAll('_', '') ??
        'INCOMPLETE'; // Normalize by removing underscore and uppercasing

    final parsedStatus = EvaluationStatusModel.values.firstWhere(
      (e) =>
          e.name.toUpperCase() ==
          statusStringFromJson, // e.g., "NOTIDEAL" == "NOTIDEAL"
      orElse: () {
        // It seems you have another status parser below, maybe consolidate?
        // For now, just ensure this one works for "NOT_IDEAL"
        final originalStatusString = (json['status'] as String?);
        debugPrint(
          "Warning: Unknown status string '$originalStatusString' received (normalized: $statusStringFromJson). Defaulting to INCOMPLETE.",
        );
        return EvaluationStatusModel.incomplete;
      },
    );

    final derivedIsIdeal = parsedStatus == EvaluationStatusModel.ideal;

    // If backend also sends an 'isIdeal' boolean, you might prioritize it or log a mismatch
    // For now, we derive from 'status' if 'isIdeal' is not directly in the 'json' map for this specific item
    final isIdealFromJson = json['isIdeal'] as bool? ?? derivedIsIdeal;
    EvaluationStatusModel statusModel;
    try {
      statusModel = EvaluationStatusModel.values.firstWhere(
        (e) =>
            e.name.toLowerCase() == (json['status'] as String?)?.toLowerCase(),
        orElse: () => EvaluationStatusModel.incomplete,
      );
    } catch (_) {
      statusModel = EvaluationStatusModel.incomplete;
    }

    var isIdealCurrent =
        isIdealFromJson || statusModel == EvaluationStatusModel.ideal;
    // If full ratio data is available, re-calculate isIdeal based on bounds for safety
    if (ratioData != null && ratioData['lowerBound'] != null) {
      final lowerBound = (ratioData['lowerBound'] as num).toDouble();
      final isLowerBoundInclusive =
          ratioData['isLowerBoundInclusive'] as bool? ?? true;
      final meetsLower = isLowerBoundInclusive
          ? value >= lowerBound
          : value > lowerBound;

      if (ratioData['upperBound'] != null) {
        final upperBound = (ratioData['upperBound'] as num).toDouble();
        final isUpperBoundInclusive =
            ratioData['isUpperBoundInclusive'] as bool? ?? true;
        final meetsUpper = isUpperBoundInclusive
            ? value <= upperBound
            : value < upperBound;
        isIdealCurrent = meetsLower && meetsUpper;
      } else {
        isIdealCurrent = meetsLower;
      }
    } else if (ratioData != null && ratioData['upperBound'] != null) {
      final upperBound = (ratioData['upperBound'] as num).toDouble();
      final isUpperBoundInclusive =
          ratioData['isUpperBoundInclusive'] as bool? ?? true;
      isIdealCurrent = isUpperBoundInclusive
          ? value <= upperBound
          : value < upperBound;
    }

    return Evaluation(
      // If 'ratioId' is present (from SingleRatioCalculationResultDto or EvaluationResult), use it.
      // Otherwise, 'id' might be the EvaluationResult.id or a client-side ID.
      id:
          json['ratioId'] as String? ??
          ratioData?['id'] as String? ??
          json['id'] as String,
      title:
          ratioData?['title'] as String? ??
          json['title'] as String? ??
          'Unknown Ratio',
      yourValue: value,
      status: statusModel,
      isIdeal: isIdealCurrent,
      calculatedAt: DateTime.parse(
        json['calculatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ).toLocal(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String).toLocal()
          : null, // ADDED
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String).toLocal()
          : null, // ADDED
      idealText:
          ratioData?['idealText'] as String? ??
          _constructIdealText(ratioData) ??
          json['idealRangeDisplay'] as String?,
      backendRatioCode:
          ratioData?['code'] as String? ?? json['ratioCode'] as String?,
      backendEvaluationResultId:
          json['id']
              as String?, // If json is an EvaluationResult, its 'id' is backendEvaluationResultId
      breakdown: (json['breakdownComponents'] as List<dynamic>?)
          ?.map(
            (e) => ConceptualComponentValue.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static String? _constructIdealText(Map<String, dynamic>? ratioData) {
    if (ratioData == null) return 'N/A';
    final lower = ratioData['lowerBound'] as num?;
    final upper = ratioData['upperBound'] as num?;
    final isLowerInc = ratioData['isLowerBoundInclusive'] as bool? ?? true;
    final isUpperInc = ratioData['isUpperBoundInclusive'] as bool? ?? true;
    final multiplier = (ratioData['multiplier'] as num?)?.toDouble() ?? 1.0;
    final unit = multiplier == 100.0
        ? '%'
        : (ratioData['code'] == 'LIQUIDITY_RATIO' ? ' Bulan' : '');
    if (ratioData['code'] == 'LIQUIDITY_RATIO') return '3-6 Bulan';
    if (lower != null && upper != null) {
      return "${isLowerInc ? '>=' : '>'} ${lower.toStringAsFixed(0)}$unit dan ${isUpperInc ? '<=' : '<'} ${upper.toStringAsFixed(0)}$unit";
    }
    if (lower != null) {
      return "${isLowerInc ? '>=' : '>'} ${lower.toStringAsFixed(0)}$unit";
    }
    if (upper != null) {
      return "${isUpperInc ? '<=' : '<'} ${upper.toStringAsFixed(0)}$unit";
    }
    return (ratioData['title']?.toString().toLowerCase().contains(
              'solvabilitas',
            ) ??
            false)
        ? '> 0%'
        : 'N/A';
  }

  final String id;
  final String? backendRatioCode;
  final String? backendEvaluationResultId;
  final String title;
  final EvaluationStatusModel status;
  final double yourValue;
  final bool isIdeal;
  final String? idealText;
  final List<ConceptualComponentValue>? breakdown;
  final DateTime calculatedAt;
  final DateTime? startDate; // ADDED
  final DateTime? endDate; // ADDED

  Map<String, dynamic> toJson() => {
    'id':
        id, // This should consistently be the Ratio ID for caching client-side definitions if needed
    'title': title,
    'yourValue': yourValue,
    'isIdeal': isIdeal,
    'status': status.name,
    'calculatedAt': calculatedAt.toUtc().toIso8601String(),
    if (startDate != null)
      'startDate': startDate!.toUtc().toIso8601String(), // ADDED
    if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(), // ADDED
    if (idealText != null) 'idealText': idealText,
    if (backendRatioCode != null) 'backendRatioCode': backendRatioCode,
    if (backendEvaluationResultId != null)
      'backendEvaluationResultId': backendEvaluationResultId,
    'breakdown': breakdown
        ?.map((e) => {'name': e.name, 'value': e.value})
        .toList(),
  };

  Evaluation copyWith({
    String? id,
    String? title,
    double? yourValue,
    bool? isIdeal,
    EvaluationStatusModel? status,
    DateTime? calculatedAt,
    DateTime? startDate,
    DateTime? endDate,
    String? idealText,
    List<ConceptualComponentValue>? breakdown,
    String? backendRatioCode,
    String? backendEvaluationResultId,
  }) {
    return Evaluation(
      id: id ?? this.id,
      title: title ?? this.title,
      yourValue: yourValue ?? this.yourValue,
      isIdeal: isIdeal ?? this.isIdeal,
      status: status ?? this.status,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      idealText: idealText ?? this.idealText,
      breakdown: breakdown ?? this.breakdown,
      backendRatioCode: backendRatioCode ?? this.backendRatioCode,
      backendEvaluationResultId:
          backendEvaluationResultId ?? this.backendEvaluationResultId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    yourValue,
    isIdeal,
    status,
    calculatedAt,
    startDate,
    endDate,
    idealText,
    breakdown,
    backendRatioCode,
    backendEvaluationResultId,
  ];
}
