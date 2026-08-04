import 'models.dart';

/// Abstrakcyjna warstwa API — niezalezna od backendu.
/// Factory wybiera implementacje na podstawie platformy.
abstract class PlumaApi {
  // Auth
  Future<UserProfile> login(String username, String password);
  Future<UserProfile> register(String username, String password);
  Future<void> logout();

  // Users
  Future<UserProfile> getOrCreateUser(String username);
  Future<List<UserProfile>> getAllUsers();
  Future<void> updateUser(String username, {
    String? name,
    String? bio,
    String? pfp,
    String? banner,
    String? color,
    String? joined,
    String? pw,
    String? theme,
    String? themeId,
  });

  // Messages
  Future<void> sendMessage({
    required String sender,
    required String recipient,
    String text = '',
    String? imageUrl,
    String? videoUrl,
  });
  Future<List<Message>> getConversation(String user1, String user2);
  Future<List<Message>> getAllMessages();
  Future<void> deleteMessage(String messageId);
  Stream<List<Message>> conversationStream(String user1, String user2);
  Stream<List<Message>> allMessagesStream();
  Stream<List<UserProfile>> usersStream();
}
