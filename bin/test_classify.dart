import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const baseUrl = 'http://localhost:4000/api/v1';
  const testDescription = 'Order makanan via Gofood';

  final url = Uri.parse('$baseUrl/transactions/classify');
  print('Testing classification for: "$testDescription"');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'text': testDescription}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    print(
      'Predicted Category: ${data['category']} (Confidence: ${data['confidence']})',
    );
  } else {
    print('Error: ${response.statusCode} - ${response.body}');
  }
}
