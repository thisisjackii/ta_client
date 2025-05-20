// lib/features/evaluation/models/evaluation.dart

enum EvaluationStatusModel { ideal, notIdeal, incomplete }

// Define the ConceptualComponentValue model if not already defined elsewhere
class ConceptualComponentValue {
  ConceptualComponentValue({required this.name, required this.value});

  // fromJson if needed from complex API responses, not directly used in current service mapping
  factory ConceptualComponentValue.fromJson(Map<String, dynamic> json) {
    return ConceptualComponentValue(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }
  final String name;
  final double value;
}

class Evaluation {
  Evaluation({
    required this.id, // This will now be the backend Ratio.id (UUID) when online
    required this.title,
    required this.yourValue,

    required this.status,
    required this.calculatedAt,
    this.periodId,
    this.ratioId, // Optional: Store the client-side ratio ID ('0', '1'...)
    this.idealText,
    this.breakdown, // This will be List<ConceptualComponentValue>?
    this.backendRatioCode, // Optional: Store the backend's code for the ratio
    this.backendEvaluationResultId, // Optional: Store the ID of the EvaluationResult record from DB
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    // This fromJson might primarily be used for offline scenarios or if backend
    // directly returns something matching this structure (less likely now).
    // For online, specific mapping is done in the service.
    return Evaluation(
      id: json['id'] as String, // Or ratioId
      title: json['title'] as String,
      yourValue: (json['yourValue'] as num).toDouble(),

      status: EvaluationStatusModel.values.firstWhere(
        (e) => e.toString() == 'EvaluationStatusModel.${json['status']}',
      ),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String).toLocal(),
      idealText: json['idealText'] as String?,
      backendRatioCode: json['backendRatioCode'] as String?,
      backendEvaluationResultId: json['backendEvaluationResultId'] as String?,
      breakdown: (json['breakdown'] as List<dynamic>?)
          ?.map(
            (e) => ConceptualComponentValue.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
  final String
  id; // Represents Ratio ID (from backend) or client-side def.id ('0', '1'...)
  final String? backendRatioCode;
  final String? backendEvaluationResultId;
  final String? ratioId;
  final String? periodId;
  final String title;
  final EvaluationStatusModel status;
  final double yourValue;

  final String? idealText;
  final List<ConceptualComponentValue>? breakdown; // Updated type
  final DateTime calculatedAt;

  Map<String, dynamic> toJson() => {
    'id': id, // or backendRatioId if that's what you need to send
    'title': title,
    'yourValue': yourValue,

    if (idealText != null) 'idealText': idealText,
    if (backendRatioCode != null) 'backendRatioCode': backendRatioCode,
    if (backendEvaluationResultId != null)
      'backendEvaluationResultId': backendEvaluationResultId,
    // Breakdown is usually not sent back to server, but calculated or fetched
  };
}
