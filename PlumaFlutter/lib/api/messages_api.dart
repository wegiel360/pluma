import 'models.dart';
import 'api_client.dart';

class MessagesApi {
  final ApiClient _client;

  MessagesApi(this._client);

  Future<void> sendMessage({
    required String sender,
    required String recipient,
    String text = '',
    String? imageUrl,
    String? videoUrl,
  }) async {
    await _client.post('/messages', {
      'sender': sender,
      'recipient': recipient,
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
    });
  }

  Future<List<Message>> getConversation(String user1, String user2) async {
    final res = await _client.get('/messages/$user1/$user2');
    final list = (res['messages'] as List? ?? []);
    return list
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<Message>> getAllMessages() async {
    final res = await _client.get('/messages');
    final list = (res['messages'] as List? ?? []);
    return list
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.delete('/messages/$messageId');
  }
}
