import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'api.dart';
import 'models.dart';

/// Implementacja FlutterFire — Firebase Auth + Cloud Firestore.
/// Dziala na Androidzie i Web.
class FlutterFireApi extends PlumaApi {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -----------------------------------------------------------------------
  // AUTH
  // -----------------------------------------------------------------------

  String _emailFor(String username) => '$username@pluma.app';

  @override
  Future<UserProfile> register(String username, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: _emailFor(username),
      password: password,
    );
    await cred.user!.updateDisplayName(username);

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
    await _db.collection('users').doc(username).set(profile.toMap());
    return profile;
  }

  @override
  Future<UserProfile> login(String username, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: _emailFor(username),
      password: password,
    );
    return _getOrCreateProfile(username);
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  // -----------------------------------------------------------------------
  // USERS
  // -----------------------------------------------------------------------

  Future<UserProfile> _getOrCreateProfile(String username) async {
    final doc = await _db.collection('users').doc(username).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
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
    await _db.collection('users').doc(username).set(profile.toMap());
    return profile;
  }

  @override
  Future<UserProfile> getOrCreateUser(String username) =>
      _getOrCreateProfile(username);

  @override
  Future<List<UserProfile>> getAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs
        .map((d) => UserProfile.fromMap(d.data()))
        .toList();
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
      await _db.collection('users').doc(username).update(updates);
    }
  }

  @override
  Stream<List<UserProfile>> usersStream() {
    return _db.collection('users').snapshots().map(
      (snap) => snap.docs.map((d) => UserProfile.fromMap(d.data())).toList(),
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
    await _db
        .collection('dms')
        .doc(_conversationId(sender, recipient))
        .collection('messages')
        .add(msg.toJson());
  }

  @override
  Future<List<Message>> getConversation(String user1, String user2) async {
    final snap = await _db
        .collection('dms')
        .doc(_conversationId(user1, user2))
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs.map((d) => Message.fromJson(d.data())).toList();
  }

  @override
  Future<List<Message>> getAllMessages() async {
    final convSnap = await _db.collection('dms').get();
    final all = <Message>[];
    for (final conv in convSnap.docs) {
      final items = await conv.reference
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .get();
      all.addAll(items.docs.map((d) => Message.fromJson(d.data())));
    }
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return all;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    final convSnap = await _db.collection('dms').get();
    for (final conv in convSnap.docs) {
      final ref = conv.reference.collection('messages').doc(messageId);
      if ((await ref.get()).exists) {
        await ref.delete();
        return;
      }
    }
  }

  @override
  Stream<List<Message>> conversationStream(String user1, String user2) {
    return _db
        .collection('dms')
        .doc(_conversationId(user1, user2))
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
      (snap) => snap.docs.map((d) => Message.fromJson(d.data())).toList(),
    );
  }

  @override
  Stream<List<Message>> allMessagesStream() async* {
    final convSnap = await _db.collection('dms').get();
    if (convSnap.docs.isEmpty) return;
    for (final conv in convSnap.docs) {
      yield* conv.reference
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => Message.fromJson(d.data())).toList());
    }
  }
}
