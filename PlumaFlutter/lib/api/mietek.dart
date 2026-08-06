import 'package:cloud_functions/cloud_functions.dart';

class MietekClient {
  final FirebaseFunctions _functions;

  MietekClient(this._functions);

  Future<String?> getReply({
    required String triggerMessage,
    required String dmId,
    required String senderUsername,
    required List<String> participants,
    String? weatherContext,
  }) async {
    final HttpsCallable callable =
        _functions.httpsCallable('handleMietekMessage');

    try {
      final result = await callable.call({
        'message': triggerMessage,
        'dmId': dmId,
        'senderUsername': senderUsername,
        'conversationParticipants': participants,
        'weatherContext': weatherContext,
      });

      return result.data['reply'] as String?;
    } catch (e) {
      print('MietekClient error: $e');
      return null;
    }
  }
}
