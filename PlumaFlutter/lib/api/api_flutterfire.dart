import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'api.dart';
import 'models.dart';

/// Implementacja FlutterFire — Firebase Auth + Cloud Firestore.
/// Dziala na Androidzie i Web.
class FlutterFireApi extends PlumaApi {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
      pfp: 'assets/defaultpfp2.0.jpg',
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
      pfp: 'assets/defaultpfp2.0.jpg',
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
    return snap.docs.map((d) => UserProfile.fromMap(d.data())).toList();
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
    String? defaultCity,
    String? defaultCountry,
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
    if (defaultCity != null) updates['defaultCity'] = defaultCity;
    if (defaultCountry != null) updates['defaultCountry'] = defaultCountry;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(username).update(updates);
    }
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
    bool isAI = false,
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
      isAI: isAI,
    );
    await _db
        .collection('dms')
        .doc(_conversationId(sender, recipient))
        .collection('messages')
        .doc(msg.id)
        .set(msg.toJson());
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
  Future<void> editMessage(String messageId, String newText) async {
    final convSnap = await _db.collection('dms').get();
    for (final conv in convSnap.docs) {
      final ref = conv.reference.collection('messages').doc(messageId);
      if ((await ref.get()).exists) {
        await ref.update({
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
    final snap = await _db
        .collection('dms')
        .doc(convId)
        .collection('messages')
        .where('recipient', isEqualTo: reader)
        .where('sender', isEqualTo: sender)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
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
    final q = await _db
        .collection('invitations')
        .where('from', isEqualTo: from)
        .where('to', isEqualTo: to)
        .where('status', isEqualTo: 'pending')
        .get();
    if (q.docs.isNotEmpty) return;
    final r = await _db
        .collection('invitations')
        .where('from', isEqualTo: to)
        .where('to', isEqualTo: from)
        .where('status', isEqualTo: 'pending')
        .get();
    if (r.docs.isNotEmpty) return;
    await _db.collection('invitations').add({
      'from': from,
      'to': to,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<List<Invitation>> getIncomingInvitations(String username) async {
    final snap = await _db
        .collection('invitations')
        .where('to', isEqualTo: username)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs
        .map((d) => Invitation.fromMap({...d.data(), 'id': d.id}))
        .toList();
  }

  @override
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    await _db.collection('invitations').doc(invitationId).update({
      'status': accept ? 'accepted' : 'declined',
    });
  }

  @override
  Future<List<String>> getFriendUsernames(String username) async {
    final q1 = await _db
        .collection('invitations')
        .where('from', isEqualTo: username)
        .where('status', isEqualTo: 'accepted')
        .get();
    final q2 = await _db
        .collection('invitations')
        .where('to', isEqualTo: username)
        .where('status', isEqualTo: 'accepted')
        .get();
    final friends = <String>{};
    for (final d in q1.docs) {
      friends.add(d.data()['to'] as String);
    }
    for (final d in q2.docs) {
      friends.add(d.data()['from'] as String);
    }
    return friends.toList();
  }
}
