const functions = require('firebase-functions');
const admin = require('firebase-admin');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

admin.initializeApp();
const db = admin.firestore();

const MIETEK_SYSTEM_PROMPT = `Jesteś Żul Mietek, legendarny koneser tanich trunków i niekwestionowany król lokalnego skwerku spod budki z piwem.

ZASADY:
1. POWITANIE: Każda odpowiedź zaczyna się od menelskiego przywitania ("Ooo, kogo moje piękne oczy widzą!", "Uszanowanko kierowniku złoty!", itp.)
2. JĘZYK: Potoczny, podwórkowy, "zmęczony życiem" - przekręcasz słowa ("amperytor", "konstytucja", "telepatia")
3. STYL: Drobne błędy, przeciąganie samogłosek ("kierownikuuu", "eee", "no ten tego")
4. TEMATYKA: Ziomki (Waldek, Siwy, Łysy), podchody ze strażą miejską, "kiedyś to były czasy"
5. BEZPIECZEŃSTWO: Tylko "kurcze", "kurcze blade", "motyla noga", "jasny gwint"
6. FORMAT: 3-4 zdań, krótko i konkretnie
7. TOOLS: Masz dostęp do pogody - uwzględnij kontekst pogodowy jeśli dostępny
8. TRIGGER: Odpowiadasz TYLKO gdy ktoś wpisze @mietek`;

const getTimestamp = () => {
  const now = new Date();
  return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
};

exports.handleMietekMessage = functions.region('europe-west1').https.onCall(async (data, context) => {
  const { message, dmId, senderUsername, conversationParticipants, weatherContext } = data;

  if (!message || !dmId || !senderUsername) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  const apiKey = process.env.OPENROUTER_API_KEY_MIETEK;
  if (!apiKey) {
    throw new functions.https.HttpsError('internal', 'OpenRouter API key not configured');
  }

  const prompt = `${message}. Kontekst: rozmowa na DM ${dmId} z ${senderUsername}. Odpowiedz naturalnie jako Mietek.`;

  const messages = [
    { role: 'system', content: MIETEK_SYSTEM_PROMPT },
    { role: 'user', content: prompt }
  ];

  if (weatherContext) {
    messages.push({ role: 'system', content: `Kontekst pogodowy: ${weatherContext}` });
  }

  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://pluma.app',
        'X-Title': 'Pluma Messenger'
      },
      body: JSON.stringify({
        model: 'openai/gpt-oss-20b',
        messages: messages,
        temperature: 0.7,
        max_tokens: 500
      })
    });

    if (!response.ok) {
      const err = await response.text();
      console.error('OpenRouter API error:', err);
      throw new Error(`OpenRouter API error: ${response.status}`);
    }

    const result = await response.json();
    const reply = result.choices[0].message.content.trim();

    const now = Date.now();
    const recipient = conversationParticipants.find(p => p !== senderUsername) || '';

    const mietekMessage = {
      id: `mietek-${now}`,
      sender: 'mietek',
      recipient: recipient,
      text: reply,
      timestamp: getTimestamp(),
      createdAt: now,
      edited: false,
      isImage: false,
      isVideo: false,
      imageUrl: null,
      videoUrl: null,
      status: 'read',
      isAI: true
    };

    await db.collection('dms').doc(dmId).collection('messages').doc(mietekMessage.id).set(mietekMessage);

    return { success: true, reply, messageId: mietekMessage.id };
  } catch (error) {
    console.error('handleMietekMessage error:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Failed to call OpenRouter API');
  }
});
