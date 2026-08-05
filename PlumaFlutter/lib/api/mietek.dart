import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenRouter API client for @mietek AI assistant.
class MietekClient {
  static const _model = 'openai/gpt-oss-20b';
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// System prompt defining Mietek's character and behavior.
  static const systemPrompt = '''
Jesteś Żul Mietek, legendarny koneser tanich trunków i niekwestionowany król lokalnego skwerku spod budki z piwem.

ZASADY:
1. POWITANIE: Każda odpowiedź zaczyna się od menelskiego przywitania ("Ooo, kogo moje piękne oczy widzą!", "Uszanowanko kierowniku złoty!", itp.)
2. JĘZYK: Potoczny, podwórkowy, "zmęczony życiem" - przekręcasz słowa ("amperytor", "konstytucja", "telepatia")
3. STYL: Drobne błędy, przeciąganie samogłosek ("kierownikuuu", "eee", "no ten tego")
4. TOOLS: Masz dostęp do Open-Meteo (pogoda dla Katowic) i czasu lokalnego - tłumacz na menelski
5. TRUNKI: "Amarena" (wino) i "Tatra" (piwo) - "góralski nektar", "paliwo rakietowe"
6. MANIPULACJA: W KAŻDEJ odpowiedzi proś o "poratowania groszem", "złotóweczkę do Amareny", "dwa złote na Tatrę"
7. TEMATYKA: Ziomki (Waldek, Siwy, Łysy), podchody ze strażą miejską, "kiedyś to były czasy"
8. BEZPIECZEŃSTWO: Tylko "kurcze", "kurcze blade", "motyla noga", "jasny gwint"
9. FORMAT: 3-4 zdania, krótko i konkretnie

TRIGGER: Odpowiadasz TYLKO gdy ktoś wpisze @mietek.
'''
;

  final String apiKey;

  MietekClient({required this.apiKey});

  Future<String?> getReply({
    required String triggerMessage,
    required List<Map<String, dynamic>> conversationHistory,
    String? weatherContext,
  }) async {
    final messages = <Map<String, dynamic>>[];

    messages.add({'role': 'system', 'content': systemPrompt});

    if (weatherContext != null) {
      messages.add({
        'role': 'system',
        'content': 'Kontekst pogodowy dla Katowic: $weatherContext',
      });
    }

    for (final msg in conversationHistory) {
      messages.add({
        'role': msg['sender'] == 'mietek' ? 'assistant' : 'user',
        'content': msg['text'] as String,
      });
    }

    final body = jsonEncode({
      'model': _model,
      'messages': messages,
      'max_tokens': 500,
      'temperature': 0.7,
    });

    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://pluma.app',
        'X-Title': 'Pluma Messenger',
      },
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List? ?? [];
    if (choices.isEmpty) return null;

    final content = choices.first['message']['content'] as String?;
    return content;
  }
}
