import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/image_utils.dart';
import '../api/models.dart';
import '../main.dart';
import '../theme/glass_components.dart';
import '../theme/pluma_theme.dart';

class MessagingView extends StatefulWidget {
  final AppServices services;
  final UserProfile currentUser;
  final List<UserProfile> allUsers;

  const MessagingView({
    super.key,
    required this.services,
    required this.currentUser,
    required this.allUsers,
  });

  @override
  State<MessagingView> createState() => _MessagingViewState();
}

class _MessagingViewState extends State<MessagingView> {
  final _inputCtrl = TextEditingController();
  UserProfile? _selected;
  List<Message> _messages = [];
  String _search = '';
  bool _sending = false;
  bool _showAddModal = false;
  String _modalSearch = '';
  String _customUsername = '';
  String? _attachedBase64;
  String? _attachedType; // 'image' | 'video'
  bool _isCompressing = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _selectDefault();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _selectDefault() {
    final others = widget.allUsers
        .where((u) => u.username != widget.currentUser.username)
        .toList();
    if (others.isNotEmpty && _selected == null) {
      _selected = others.first;
      _startPolling();
    }
  }

  void _startPolling() {
    _poll?.cancel();
    final sel = _selected;
    if (sel == null) return;
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _loadMessages());
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final sel = _selected;
    if (sel == null) return;
    try {
      final msgs = await widget.services.api
          .getConversation(widget.currentUser.username, sel.username);
      if (mounted && _selected?.username == sel.username) {
        setState(() => _messages = msgs);
      }
    } catch (_) {
      // ignore
    }
  }

  void _selectPerson(UserProfile user) {
    setState(() {
      _selected = user;
      _messages = [];
    });
    _startPolling();
  }

  Future<void> _send() async {
    final sel = _selected;
    final text = _inputCtrl.text.trim();
    if (sel == null || (text.isEmpty && _attachedBase64 == null)) return;

    final optimistic = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      sender: widget.currentUser.username,
      recipient: sel.username,
      text: text,
      timestamp: DateFormatShort.time(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isImage: _attachedType == 'image',
      isVideo: _attachedType == 'video',
      imageUrl: _attachedType == 'image' ? _attachedBase64 : null,
      videoUrl: _attachedType == 'video' ? _attachedBase64 : null,
    );

    final currentText = text;
    final currentMedia = _attachedBase64;
    final currentType = _attachedType;

    setState(() {
      _messages = [..._messages, optimistic];
      _inputCtrl.clear();
      _attachedBase64 = null;
      _attachedType = null;
      _sending = true;
    });

    try {
      await widget.services.api.sendMessage(
        sender: widget.currentUser.username,
        recipient: sel.username,
        text: currentText,
        imageUrl: currentType == 'image' ? currentMedia : null,
        videoUrl: currentType == 'video' ? currentMedia : null,
      );
    } catch (_) {
      setState(() {
        _messages = _messages.where((m) => m.id != optimistic.id).toList();
      });
      _showSnack('Nie udalo sie wyslac wiadomosci. Sprawdz polaczenie.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final source = await _chooseSource();
    if (source == null) return;
    setState(() => _isCompressing = true);
    try {
      final mediaType = await _chooseMediaType();
      if (mediaType == null) return;
      if (mediaType == 'video') {
        final file = await picker.pickVideo(source: source, maxDuration: const Duration(minutes: 2));
        if (file == null) return;
        final base64 = await ImageUtils.convertVideoToBase64(file);
        setState(() {
          _attachedBase64 = base64;
          _attachedType = 'video';
        });
      } else {
        final file = await picker.pickImage(source: source, maxWidth: 1200);
        if (file == null) return;
        final base64 = await ImageUtils.compressToBase64(file);
        setState(() {
          _attachedBase64 = base64;
          _attachedType = 'image';
        });
      }
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  Future<String?> _chooseMediaType() async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Obraz'),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Wideo'),
              onTap: () => Navigator.pop(ctx, 'video'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ImageSource?> _chooseSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Aparat'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCustomUser() async {
    final clean = _customUsername.trim().toLowerCase().replaceAll(RegExp(r'^@'), '');
    if (clean.isEmpty) return;
    try {
      final user = await widget.services.api.getOrCreateUser(clean);
      if (mounted) {
        setState(() {
          _customUsername = '';
          _showAddModal = false;
        });
        _selectPerson(user);
      }
    } catch (_) {
      _showSnack('Nie udalo sie dodac osoby.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final others = widget.allUsers
        .where((u) => u.username != widget.currentUser.username)
        .toList();
    final filtered = others
        .where((u) =>
            u.username.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: GlassCard(
            padding: EdgeInsets.zero,
            radius: 28,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 700;
                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 300, child: _buildPeopleList(filtered)),
                      VerticalDivider(width: 1, color: Colors.white10),
                      Expanded(child: _buildChat()),
                    ],
                  );
                }
                if (_selected != null) {
                  return _buildChat();
                }
                return _buildPeopleList(filtered);
              },
            ),
          ),
        ),
        if (_showAddModal)
          GlassModal(
            onClose: () => setState(() => _showAddModal = false),
            child: _buildAddModal(),
          ),
      ],
    );
  }

  Widget _buildPeopleList(List<UserProfile> filtered) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'osoby (${filtered.length})',
                  style: const TextStyle(
                    color: PlumaColors.onSurfaceVariant,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showAddModal = true),
                child: const Text(
                  '+ znajdz osobe',
                  style: TextStyle(
                    color: PlumaColors.primary,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: PlumaColors.onSurface, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'szukaj w rozmowach...',
              hintStyle: TextStyle(
                color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final u = filtered[i];
              final isSel = _selected?.username == u.username;
              return ListTile(
                onTap: () => _selectPerson(u),
                leading: NeonAvatar(image: u.pfp, online: true, size: 40),
                title: Text(
                  '@${u.username}',
                  style: TextStyle(
                    color: isSel ? PlumaColors.primary : PlumaColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  u.bio.isEmpty ? 'uzytkownik pluma' : u.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PlumaColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                tileColor: isSel
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChat() {
    final sel = _selected!;
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selected = null),
                child: const Icon(Icons.arrow_back, color: PlumaColors.primary),
              ),
              const SizedBox(width: 12),
              NeonAvatar(image: sel.pfp, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'czat z @${sel.username}',
                      style: const TextStyle(
                        color: PlumaColors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'online',
                      style: TextStyle(
                        color: PlumaColors.neonActive,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mark_chat_unread,
                          color: color.withValues(alpha: 0.4), size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'brak wiadomosci. napisz cos do @${sel.username}!',
                        style: const TextStyle(
                          color: PlumaColors.onSurfaceVariant,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final isMe = m.sender == widget.currentUser.username;
                    return _messageBubble(m, isMe);
                  },
                ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_attachedBase64 != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _attachedType == 'video' ? Icons.movie : Icons.image,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _attachedType == 'video'
                          ? 'zalaczono plik wideo'
                          : 'zalaczono obraz (<1MB)',
                      style: TextStyle(color: color, fontSize: 12, fontFamily: 'monospace'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() {
                        _attachedBase64 = null;
                        _attachedType = null;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  IconButton(
                    onPressed: _isCompressing ? null : _pickFile,
                    icon: _isCompressing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: PlumaColors.primary,
                            ),
                          )
                        : const Icon(Icons.attach_file, color: PlumaColors.onSurfaceVariant),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      style: const TextStyle(color: PlumaColors.onSurface, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _isCompressing
                            ? 'przetwarzanie pliku...'
                            : 'napisz wiadomosc do @${sel.username}...',
                        hintStyle: TextStyle(
                          color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: PlumaColors.onPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _messageBubble(Message m, bool isMe) {
    final color = Theme.of(context).colorScheme.primary;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isMe
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          border: Border.all(
            color: isMe
                ? color.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.isImage && m.imageUrl != null)
              Image.network(
                m.imageUrl!,
                width: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image, size: 60),
              ),
            if (m.isVideo && m.videoUrl != null)
              Container(
                width: 220,
                height: 120,
                color: Colors.black54,
                child: const Center(child: Icon(Icons.play_circle, size: 48)),
              ),
            if (m.text.isNotEmpty)
              Text(
                m.text,
                style: const TextStyle(color: PlumaColors.onSurface, fontSize: 14),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _deleteMessage(m.id),
                  child: const Icon(Icons.delete_outline,
                      color: Color(0xFFFF6B6B), size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  m.timestamp,
                  style: TextStyle(
                    color: isMe
                        ? color.withValues(alpha: 0.8)
                        : PlumaColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(String id) async {
    try {
      setState(() => _messages = _messages.where((m) => m.id != id).toList());
      await widget.services.api.deleteMessage(id);
    } catch (_) {
      _showSnack('Blad usuwania wiadomosci.');
    }
  }

  Widget _buildAddModal() {
    final color = Theme.of(context).colorScheme.primary;
    final others = widget.allUsers
        .where((u) => u.username != widget.currentUser.username)
        .where((u) =>
            u.username.toLowerCase().contains(_modalSearch.toLowerCase()) ||
            u.bio.toLowerCase().contains(_modalSearch.toLowerCase()))
        .toList();

    return SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.group_add, color: PlumaColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'wybierz osobe z platformy',
                  style: TextStyle(
                    color: PlumaColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showAddModal = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _modalSearch = v),
            style: const TextStyle(color: PlumaColors.onSurface, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'szukaj uzytkownika po nazwie lub opis...',
              hintStyle: TextStyle(
                color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: others.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'brak zarejestrowanych osob pasujacych do szukania',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: PlumaColors.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: others.length,
                    itemBuilder: (context, i) {
                      final u = others[i];
                      return ListTile(
                        onTap: () {
                          setState(() => _showAddModal = false);
                          _selectPerson(u);
                        },
                        leading: NeonAvatar(image: u.pfp, size: 40),
                        title: Text(
                          '@${u.username}',
                          style: const TextStyle(
                            color: PlumaColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          u.bio.isEmpty ? 'uzytkownik pluma' : u.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PlumaColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'czatuj',
                            style: TextStyle(
                                color: color, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _customUsername = v),
                  style: const TextStyle(color: PlumaColors.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'lub wpisz nowy pseudonim...',
                    hintStyle: TextStyle(
                      color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.4),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              NeonButton(label: 'dodaj', onPressed: _addCustomUser),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small helper for short time formatting without intl DateFormat at build time.
class DateFormatShort {
  static String time() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
