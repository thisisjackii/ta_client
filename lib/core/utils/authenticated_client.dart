import 'package:hive/hive.dart';
import 'package:http/http.dart';

class AuthenticatedClient extends BaseClient {
  AuthenticatedClient(this._inner);
  final Client _inner;

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    final token = Hive.box<String>('secureBox').get('jwt_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return _inner.send(request);
  }
}
