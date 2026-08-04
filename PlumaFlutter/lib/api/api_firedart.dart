import 'package:firedart/firedart.dart';

import 'api.dart';
import 'models.dart';

/// Implementacja firedart — pure Dart Firebase Auth + Firestore.
/// Dziala natywnie na Windows bez zadnych natywnych pluginow.
class FiredartApi extends PlumaApi {
  static const _projectId = 'plumamsg';
  static const _apiKey = 'AIzaSyD_q9o1IWXBvf0UbLukMzB-pSf3lk6h3Co';
  static bool _initialized = false;

  late final FirebaseAuth _auth;
  late final Firestore _firestore;

  FiredartApi() {
    if (!_initialized) {
      _auth = FirebaseAuth.initialize(_apiKey, VolatileStore());
      _firestore = Firestore.initialize(_projectId);
      _initialized = true;
    } else {
      _auth = FirebaseAuth.instance;
      _firestore = Firestore.instance;
    }
  }

  // -----------------------------------------------------------------------
  // AUTH
  // -----------------------------------------------------------------------

  String _emailFor(String username) => '$username@pluma.app';

  @override
  Future<UserProfile> register(String username, String password) async {
    await _auth.signUp(_emailFor(username), password);
    final now = DateTime.now().millisecondsSinceEpoch;
    final profile = UserProfile(
      username: username,
      name: username,
      bio: 'uzytkownik pluma',
      color: '#ffb870',
      pfp: 'assets/logo-kogut-500x500.png',
      banner: 'assets/bliss-1024p.jpg',
      createdAt: now,
    );
    await _firestore
        .collection('users')
        .document(username)
        .set(profile.toMap());
    return profile;
  }

  @override
  Future<UserProfile> login(String username, String password) async {
    await _auth.signIn(_emailFor(username), password);
    return _getOrCreateProfile(username);
  }

  @override
  Future<void> logout() async {
    _auth.signOut();
  }

  // -----------------------------------------------------------------------
  // USERS
  // -----------------------------------------------------------------------

  Future<UserProfile> _getOrCreateProfile(String username) async {
    final doc = await _firestore.collection('users').document(username).get();
    if (await doc.reference.exists) {
      return UserProfile.fromMap(doc.map);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final profile = UserProfile(
      username: username,
      name: username,
      bio: 'uzytkownik pluma',
      color: '#ffb870',
      pfp: 'assets/logo-kogut-500x500.png',
      banner: 'assets/bliss-1024p.jpg',
      createdAt: now,
    );
    await _firestore
        .collection('users')
        .document(username)
        .set(profile.toMap());
    return profile;
  }

  @override
  Future<UserProfile> getOrCreateUser(String username) =>
      _getOrCreateProfile(username);

  @override
  Future<List<UserProfile>> getAllUsers() async {
    final page = await _firestore.collection('users').get();
    return page.map((d) => UserProfile.fromMap(d.map)).toList();
  }

  @override
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
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (bio != null) updates['bio'] = bio;
    if (pfp != null) updates['pfp'] = pfp;
    if (banner != null) updates['banner'] = banner;
    if (color != null) updates['color'] = color;
    if (joined != null) updates['joined'] = joined;
    if (pw != null) updates['pw'] = pw;
    if (theme != null) updates['theme'] = theme;
    if (themeId != null) updates['themeId'] = themeId;
    if (updates.isNotEmpty) {
      await _firestore
          .collection('users')
          .document(username)
          .update(updates);
    }
  }

  @override
  Stream<List<UserProfile>> usersStream() {
    return _firestore.collection('users').stream.map(
      (docs) => docs.map((d) => UserProfile.fromMap(d.map)).toList(),
    );
  }

  // -----------------------------------------------------------------------
  // MESSAGES — kolekcja dms/{convId}/messages/{msgId}
  // -----------------------------------------------------------------------

  String _conversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Future<void> sendMessage({
    required String sender,
    required String recipient,
    String text = '',
    String? imageUrl,
    String? videoUrl,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final h = DateTime.now().hour.toString().padLeft(2, '0');
    final m = DateTime.now().minute.toString().padLeft(2, '0');
    final msg = Message(
      id: 'msg_$now',
      sender: sender,
      recipient: recipient,
      text: text,
      timestamp: '$h:$m',
      createdAt: now,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
    );
    await _firestore
        .collection('dms')
        .document(_conversationId(sender, recipient))
        .collection('messages')
        .add(msg.toJson());
  }

  @override
  Future<List<Message>> getConversation(String user1, String user2) async {
    final page = await _firestore
        .collection('dms')
        .document(_conversationId(user1, user2))
        .collection('messages')
        .orderBy('createdAt')
        .get();
    return page.map((d) => Message.fromJson(d.map)).toList();
  }

  @override
  Future<List<Message>> getAllMessages() async {
    final convPage = await _firestore.collection('dms').get();
    final all = <Message>[];
    for (final conv in convPage) {
      final items = await conv.reference
          .collection('messages')
          .orderBy('createdAt')
          .get();
      all.addAll(items.map((d) => Message.fromJson(d.map)));
    }
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return all;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final convPage = await _firestore.collection('dms').get();
    for (final conv in convPage) {
      final docRef = conv.reference.collection('messages').document(messageId);
      if (await docRef.exists) {
        await docRef.delete();
        return;
      }
    }
  }

  @override
  Stream<List<Message>> conversationStream(String user1, String user2) async* {
    while (true) {
      yield await getConversation(user1, user2);
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Stream<List<Message>> allMessagesStream() async* {
    while (true) {
      yield await getAllMessages();
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
