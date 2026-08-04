import 'models.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<UserProfile> login(String username, String password) async {
    final res = await _client.post('/auth/login', {
      'username': username,
      'password': password,
    });
    final user = res['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(user);
  }

  Future<UserProfile> register(String username, String password) async {
    final res = await _client.post('/auth/register', {
      'username': username,
      'password': password,
    });
    final user = res['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(user);
  }
}
