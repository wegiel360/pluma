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
      pfp: 'assets/default-pfp.png',
      banner: 'assets/bliss-1024p.jpg',
      createdAt: now,
    );
    await _firestore.collection('users').document(username).set(profile.toMap());
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
      pfp: 'assets/default-pfp.png',
      banner: 'assets/bliss-1024p.jpg',
      createdAt: now,
    );
    await _firestore.collection('users').document(username).set(profile.toMap());
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
      await _firestore.collection('users').document(username).update(updates);
    }
  }

  // -----------------------------------------------------------------------
  // MESSAGES
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
  Future<void> editMessage(String messageId, String newText) async {
    final convPage = await _firestore.collection('dms').get();
    for (final conv in convPage) {
      final docRef = conv.reference.collection('messages').document(messageId);
      if (await docRef.exists) {
        await docRef.update({
          'text': newText,
          'edited': true,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        return;
      }
    }
  }

  @override
  Future<void> markConversationRead(String reader, String sender) async {
    final convId = _conversationId(reader, sender);
    final page = await _firestore
        .collection('dms')
        .document(convId)
        .collection('messages')
        .where('recipient', isEqualTo: reader)
        .where('sender', isEqualTo: sender)
        .get();
    for (final doc in page) {
      final data = doc.map;
      if (data['status'] != 'read') {
        await doc.reference.update({'status': 'read'});
      }
    }
  }

  // -----------------------------------------------------------------------
  // INVITATIONS
  // -----------------------------------------------------------------------

  @override
  Future<void> sendInvitation(String from, String to) async {
    final existing = await _firestore
        .collection('invitations')
        .where('from', isEqualTo: from)
        .where('to', isEqualTo: to)
        .where('status', isEqualTo: 'pending')
        .get();
    if (existing.isNotEmpty) return;
    final reverse = await _firestore
        .collection('invitations')
        .where('from', isEqualTo: to)
        .where('to', isEqualTo: from)
        .where('status', isEqualTo: 'pending')
        .get();
    if (reverse.isNotEmpty) return;
    await _firestore.collection('invitations').add({
      'from': from,
      'to': to,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<Invitation>> getIncomingInvitations(String username) async {
    final page = await _firestore
        .collection('invitations')
        .where('to', isEqualTo: username)
        .where('status', isEqualTo: 'pending')
        .get();
    return page
        .map((d) => Invitation.fromMap({...d.map, 'id': d.reference.id}))
        .toList();
  }

  @override
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    await _firestore.collection('invitations').document(invitationId).update({
      'status': accept ? 'accepted' : 'declined',
    });
  }

  @override
  Future<List<String>> getFriendUsernames(String username) async {
    final q1 = await _firestore
        .collection('invitations')
        .where('from', isEqualTo: username)
        .where('status', isEqualTo: 'accepted')
        .get();
    final q2 = await _firestore
        .collection('invitations')
        .where('to', isEqualTo: username)
        .where('status', isEqualTo: 'accepted')
        .get();
    final friends = <String>{};
    for (final d in q1) {
      friends.add(d.map['to'] as String);
    }
    for (final d in q2) {
      friends.add(d.map['from'] as String);
    }
    return friends.toList();
  }
}
