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
    this.idealText,
    this.breakdown,
    this.backendRatioCode,
    this.backendEvaluationResultId, // This is the DB ID of the EvaluationResult record
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    final ratioData =
        json['ratio']
            as Map<String, dynamic>?; // From nested EvaluationResult.ratio
    final value = (json['value'] as num? ?? 0).toDouble();

    final statusStringRaw = json['status'] as String?;
    // Normalize: remove underscore and uppercase. Handles "NOT_IDEAL" and "NOTIDEAL"
    final statusStringNormalized =
        statusStringRaw?.toUpperCase().replaceAll('_', '') ?? 'INCOMPLETE';

    EvaluationStatusModel parsedStatus;
    try {
      parsedStatus = EvaluationStatusModel.values.firstWhere(
        (e) => e.name.toUpperCase() == statusStringNormalized,
      );
    } catch (_) {
      debugPrint(
        "[Evaluation.fromJson] Warning: Unknown status string '$statusStringRaw' (normalized: $statusStringNormalized). Defaulting to INCOMPLETE.",
      );
      parsedStatus = EvaluationStatusModel.incomplete;
    }

    final isIdeal = parsedStatus == EvaluationStatusModel.ideal;

    return Evaluation(
      id:
          json['ratioId']
              as String? ?? // From SingleRatioCalculationResultDto (backend /evaluations/calculate response)
          ratioData?['id']
              as String? ?? // From nested EvaluationResult.ratio.id (backend /evaluations/history response)
          json['id']
              as String, // Fallback to EvaluationResult.id itself if other IDs are missing
      title:
          ratioData?['title'] as String? ??
          json['ratioTitle']
              as String? ?? // From SingleRatioCalculationResultDto
          json['title']
              as String? ?? // Fallback if top-level title exists from other sources
          'Unknown Ratio',
      yourValue: value,
      status: parsedStatus,
      isIdeal: isIdeal,
      calculatedAt: DateTime.parse(
        json['calculatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ).toLocal(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String).toLocal()
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String).toLocal()
          : null,
      idealText:
          ratioData?['idealText']
              as String? ?? // Prefer idealText from nested Ratio
          _constructIdealText(
            ratioData,
          ) ?? // Construct if needed from bounds (if ratioData available)
          json['idealRangeDisplay']
              as String?, // From SingleRatioCalculationResultDto
      backendRatioCode:
          ratioData?['code'] as String? ?? json['ratioCode'] as String?,
      // If the root json object is an EvaluationResult, its 'id' is the backendEvaluationResultId
      backendEvaluationResultId:
          (json.containsKey('ratioId') && json.containsKey('userId'))
          ? json['id'] as String?
          : null,
      breakdown: (json['breakdownComponents'] as List<dynamic>?)
          ?.map(
            (e) => ConceptualComponentValue.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  static String? _constructIdealText(Map<String, dynamic>? ratioData) {
    if (ratioData == null) {
      return 'N/A'; // Default if no ratio data to construct from
    }
    final lower = ratioData['lowerBound'] as num?;
    final upper = ratioData['upperBound'] as num?;
    final isLowerInc = ratioData['isLowerBoundInclusive'] as bool? ?? true;
    final isUpperInc = ratioData['isUpperBoundInclusive'] as bool? ?? true;
    final multiplier = (ratioData['multiplier'] as num?)?.toDouble() ?? 1.0;
    final unit = multiplier == 100.0
        ? '%'
        : (ratioData['code'] == 'LIQUIDITY_RATIO' ? ' Bulan' : '');

    if (ratioData['code'] == 'LIQUIDITY_RATIO') {
      return '3-6 Bulan'; // Specific text
    }

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
        ? '> 0%' // Specific for solvency if no bounds given
        : 'N/A'; // General fallback
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
  final DateTime? startDate;
  final DateTime? endDate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'yourValue': yourValue,
    'isIdeal': isIdeal,
    'status': status
        .name, // Ensure this matches what backend might expect if re-serializing
    'calculatedAt': calculatedAt.toUtc().toIso8601String(),
    if (startDate != null) 'startDate': startDate!.toUtc().toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
    if (idealText != null) 'idealText': idealText,
    if (backendRatioCode != null) 'backendRatioCode': backendRatioCode,
    if (backendEvaluationResultId != null)
      'backendEvaluationResultId': backendEvaluationResultId,
    'breakdown': breakdown
        ?.map((e) => {'name': e.name, 'value': e.value})
        .toList(),
    // Include 'ratio' if needed for caching/re-serialization in specific contexts
    // For now, keeping it flat as it's primarily for consuming backend data.
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
    ValueGetter<List<ConceptualComponentValue>?>?
    breakdown, // Use ValueGetter for nullable list
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
      breakdown: breakdown != null ? breakdown() : this.breakdown,
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
