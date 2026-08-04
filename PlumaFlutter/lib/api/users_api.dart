import 'models.dart';
import 'api_client.dart';

class UsersApi {
  final ApiClient _client;

  UsersApi(this._client);

  Future<UserProfile> getOrCreateUser(String username) async {
    final user = UserProfile(
      username: username,
      bio: 'uzytkownik pluma',
      color: '#ffb870',
      pfp: 'assets/logo-kogut-500x500.png',
      banner: 'assets/bliss-1024p.jpg',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      final res = await _client.get('/users/$username');
      return UserProfile.fromJson(res['user'] as Map<String, dynamic>);
    } on ApiException {
      // User not found - create default profile.
    }

    await _client.post('/users/$username', {
      'bio': user.bio,
      'pfp': user.pfp,
      'banner': user.banner,
      'color': user.color,
    });
    return user;
  }

  Future<List<UserProfile>> getAllUsers() async {
    final res = await _client.get('/users');
    final list = (res['users'] as List? ?? []);
    return list
        .map((u) => UserProfile.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateUser(String username, {
    String? bio,
    String? pfp,
    String? banner,
    String? color,
  }) async {
    await _client.post('/users/$username', {
      'bio': bio,
      'pfp': pfp,
      'banner': banner,
      'color': color,
    });
  }
}
