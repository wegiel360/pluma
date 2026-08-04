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
  });

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
  Future<void> editMessage(String messageId, String newText);
  Stream<List<Message>> conversationStream(String user1, String user2);
  Stream<List<Message>> allMessagesStream();
  Stream<List<UserProfile>> usersStream();

  Future<void> updateMessageStatus(String messageId, String status);
  Future<void> markConversationRead(String reader, String sender);
  Future<void> toggleReaction(String messageId, String username, String emoji);

  Future<void> sendInvitation(String from, String to);
  Future<List<Invitation>> getIncomingInvitations(String username);
  Future<void> respondToInvitation(String invitationId, bool accept);
  Future<bool> areFriends(String user1, String user2);
  Future<List<String>> getFriendUsernames(String username);
}
