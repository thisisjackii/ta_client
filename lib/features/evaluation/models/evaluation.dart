// C:\Users\PONGO\RemoteProjects\ta_client\lib\features\evaluation\models\evaluation.dart
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
    required this.id,
    required this.title,
    required this.yourValue,
    required this.isIdeal,
    required this.status,
    required this.calculatedAt,
    this.startDate,
    this.endDate,
    this.idealText,
    this.breakdown,
    this.backendRatioCode,
    this.backendEvaluationResultId,
    this.calculatedNumerator, // <<< ADDED
    this.calculatedDenominator, // <<< ADDED
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    final ratioData = json['ratio'] as Map<String, dynamic>?;
    final value = (json['value'] as num? ?? 0).toDouble();
    final statusStringRaw = json['status'] as String?;
    final statusStringNormalized =
        statusStringRaw?.toUpperCase().replaceAll('_', '') ?? 'INCOMPLETE';
    EvaluationStatusModel parsedStatus;
    try {
      parsedStatus = EvaluationStatusModel.values.firstWhere(
        (e) => e.name.toUpperCase() == statusStringNormalized,
      );
    } catch (_) {
      debugPrint(
        "[Evaluation.fromJson] Warning: Unknown status string '$statusStringRaw'. Defaulting to INCOMPLETE.",
      );
      parsedStatus = EvaluationStatusModel.incomplete;
    }
    final isIdealResult = parsedStatus == EvaluationStatusModel.ideal;

    var finalIdealText =
        ratioData?['idealText'] as String? ??
        json['idealRangeDisplay'] as String?;
    if (finalIdealText == null ||
        finalIdealText == 'Rentang ideal tidak ditentukan' ||
        finalIdealText == 'N/A') {
      finalIdealText = _constructIdealTextFromRatioData(ratioData);
    }

    return Evaluation(
      id:
          json['ratioId'] as String? ??
          ratioData?['id'] as String? ??
          json['id'] as String,
      title:
          ratioData?['title'] as String? ??
          json['ratioTitle'] as String? ??
          json['title'] as String? ??
          'Unknown Ratio',
      yourValue: value,
      status: parsedStatus,
      isIdeal: isIdealResult,
      calculatedAt: DateTime.parse(
        json['calculatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ).toLocal(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String).toLocal()
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String).toLocal()
          : null,
      idealText: finalIdealText,
      backendRatioCode:
          ratioData?['code'] as String? ?? json['ratioCode'] as String?,
      backendEvaluationResultId:
          (json.containsKey('ratioId') && json.containsKey('userId'))
          ? json['id'] as String?
          : null,
      breakdown: (json['breakdownComponents'] as List<dynamic>?)
          ?.map(
            (e) => ConceptualComponentValue.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      calculatedNumerator: (json['calculatedNumerator'] as num?)
          ?.toDouble(), // <<< ADDED PARSING
      calculatedDenominator: (json['calculatedDenominator'] as num?)
          ?.toDouble(), // <<< ADDED PARSING
    );
  }

  static String? _constructIdealTextFromRatioData(
    Map<String, dynamic>? ratioData,
  ) {
    if (ratioData == null) return 'N/A';
    final code = ratioData['code'] as String?;
    final lower = (ratioData['lowerBound'] as num?)?.toDouble();
    final upper = (ratioData['upperBound'] as num?)?.toDouble();
    final multiplier = (ratioData['multiplier'] as num?)?.toDouble() ?? 1.0;
    final unit = multiplier == 100.0
        ? '%'
        : (code == 'LIQUIDITY_RATIO' ? ' Bulan' : '');
    String? formatB(double? v) => v != null ? v.toStringAsFixed(0) : '';

    if (code == 'LIQUIDITY_RATIO') {
      return lower != null ? '≥ ${formatB(lower)}$unit' : '≥ 3 Bulan';
    }
    if (code == 'SOLVENCY_RATIO') return '-';
    if (lower != null && upper != null) {
      return '${formatB(lower)}$unit - ${formatB(upper)}$unit';
    }
    if (lower != null) return '≥ ${formatB(lower)}$unit';
    if (upper != null) return '≤ ${formatB(upper)}$unit';
    return 'N/A';
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
  final double? calculatedNumerator; // <<< ADDED
  final double? calculatedDenominator; // <<< ADDED

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'yourValue': yourValue,
    'isIdeal': isIdeal,
    'status': status.name,
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
    if (calculatedNumerator != null)
      'calculatedNumerator': calculatedNumerator, // <<< ADDED
    if (calculatedDenominator != null)
      'calculatedDenominator': calculatedDenominator, // <<< ADDED
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
    ValueGetter<List<ConceptualComponentValue>?>? breakdown,
    String? backendRatioCode,
    String? backendEvaluationResultId,
    double? calculatedNumerator, // <<< ADDED
    double? calculatedDenominator, // <<< ADDED
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
      calculatedNumerator:
          calculatedNumerator ?? this.calculatedNumerator, // <<< ADDED
      calculatedDenominator:
          calculatedDenominator ?? this.calculatedDenominator, // <<< ADDED
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
    calculatedNumerator, calculatedDenominator, // <<< ADDED
  ];
}
