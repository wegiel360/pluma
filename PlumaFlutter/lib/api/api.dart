import 'models.dart';

abstract class PlumaApi {
  Future<UserProfile> login(String username, String password);
  Future<UserProfile> register(String username, String password);
  Future<void> logout();

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
    String? defaultCity,
    String? defaultCountry,
  });

  Future<void> sendMessage({
    required String sender,
    required String recipient,
    String text = '',
    String? imageUrl,
    String? videoUrl,
    bool isAI = false,
  });
  Future<List<Message>> getConversation(String user1, String user2);
  Future<void> deleteMessage(String messageId);
  Future<void> editMessage(String messageId, String newText);

  Future<void> markConversationRead(String reader, String sender);

  Future<void> sendInvitation(String from, String to);
  Future<List<Invitation>> getIncomingInvitations(String username);
  Future<void> respondToInvitation(String invitationId, bool accept);
  Future<List<String>> getFriendUsernames(String username);
}
