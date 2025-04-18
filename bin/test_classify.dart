import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'http://localhost:4000/api/v1';
  const testDescription = 'Order makanan via Gofood';

  final url = Uri.parse('$baseUrl/transactions/classify');
  debugPrint('Testing classification for: "$testDescription"');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'text': testDescription}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    debugPrint(
      'Predicted Category: ${data['category']} (Confidence: ${data['confidence']})',
    );
  } else {
    debugPrint('Error: ${response.statusCode} - ${response.body}');
  }
}
