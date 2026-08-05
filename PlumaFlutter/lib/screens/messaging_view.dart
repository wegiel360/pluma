import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _attachedType;
  bool _isCompressing = false;
  bool _mobileShowChat = false;
  bool _showAllUsers = false;
  List<String> _friendsList = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _selectDefault();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _selectDefault() {
    final others = _filteredPeople();
    if (others.isNotEmpty && _selected == null) {
      _selected = others.first;
    }
  }

  List<UserProfile> _filteredPeople() {
    var list = widget.allUsers
        .where((u) => u.username != widget.currentUser.username)
        .toList();
    if (!_showAllUsers && _friendsList.isNotEmpty) {
      list = list
          .where((u) => _friendsList.contains(u.username))
          .toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where((u) => u.username.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await widget.services.api
          .getFriendUsernames(widget.currentUser.username);
      if (mounted) setState(() => _friendsList = friends);
    } catch (_) {}
  }

  void _selectPerson(UserProfile user) {
    setState(() {
      _selected = user;
      _messages = [];
      _mobileShowChat = true;
    });
  }

  Future<void> _send() async {
    final sel = _selected;
    final text = _inputCtrl.text.trim();
    if (sel == null || (text.isEmpty && _attachedBase64 == null)) return;

    final now = DateTime.now();
    final optimistic = Message(
      id: 'temp-${now.millisecondsSinceEpoch}',
      sender: widget.currentUser.username,
      recipient: sel.username,
      text: text,
      timestamp: '${_pad(now.hour)}:${_pad(now.minute)}',
      createdAt: now.millisecondsSinceEpoch,
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
      _showSnack('Nie udało się wysłać wiadomości. Sprawdź połączenie.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }

    // Trigger @mietek if mentioned
    if (text.contains('@mietek') && widget.services.mietek != null) {
      _triggerMietek(optimistic);
    }
  }

  Future<void> _triggerMietek(Message triggeringMessage) async {
    final sel = _selected!;
    final mietek = widget.services.mietek!;
    final weather = widget.services.weatherApi;

    String? weatherContext;
    try {
      final w = await weather.getWeather(
        lat: 50.2649,
        lon: 19.0238,
        city: 'Katowice, Śląsk, Polska',
      );
      weatherContext = '${w.condition}, ${w.temp}°C, ${w.high}°/${w.low}°C';
    } catch (_) {}

    final history = _messages
        .where((m) => m.sender == widget.currentUser.username || m.sender == 'mietek')
        .map((m) => {
              'sender': m.sender,
              'text': m.text,
              'createdAt': m.createdAt,
            })
        .toList();

    String? reply;
    try {
      reply = await mietek.getReply(
        triggerMessage: triggeringMessage.text,
        conversationHistory: history,
        weatherContext: weatherContext,
      );
    } catch (e) {
      reply = 'Kurcze, coś mi się chyba odpaliło źródło mocy... spróbuj później!';
    }

    reply ??= 'Kurcze blade, nie dostaję odpowiedzi... może spróbujesz ponownie?';

    final now = DateTime.now();
    final mietekMsg = Message(
      id: 'mietek-${now.millisecondsSinceEpoch}',
      sender: 'mietek',
      recipient: widget.currentUser.username,
      text: reply,
      timestamp: '${_pad(now.hour)}:${_pad(now.minute)}',
      createdAt: now.millisecondsSinceEpoch,
      isAI: true,
    );

    await widget.services.api.sendMessage(
      sender: 'mietek',
      recipient: sel.username,
      text: reply,
      isAI: true,
    );

    if (mounted) {
      setState(() {
        _messages = [..._messages, mietekMsg];
      });
    }
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final source = await showImageSourcePicker(context);
    if (source == null) return;
    setState(() => _isCompressing = true);
    try {
      final mediaType = await _chooseMediaType();
      if (mediaType == null) return;
      if (mediaType == 'video') {
        final file = await picker.pickVideo(
            source: source, maxDuration: const Duration(minutes: 2));
        if (file == null) return;
        final base64 = await ImageUtils.convertVideoToBase64(file);
        setState(() {
          _attachedBase64 = base64;
          _attachedType = 'video';
        });
      } else {
        final file = await picker.pickImage(source: source, maxWidth: 1000);
        if (file == null) return;
        final base64 = await ImageUtils.compressToBase64(file, maxDimension: 1000);
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ),
    );
  }

  Future<void> _addCustomUser() async {
    final clean = _customUsername.trim().toLowerCase().replaceAll(RegExp(r'^@'), '');
    if (clean.isEmpty) return;
    try {
      final user = await widget.services.api.getOrCreateUser(clean);
      if (mounted) {
        setState(() { _customUsername = ''; _showAddModal = false; });
        _selectPerson(user);
      }
    } catch (_) {
      _showSnack('Nie udało się dodać osoby.');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _deleteMessage(String id) async {
    try {
      setState(() => _messages = _messages.where((m) => m.id != id).toList());
      await widget.services.api.deleteMessage(id);
    } catch (_) {
      _showSnack('Błąd usuwania wiadomości.');
    }
  }

  void _editMessage(Message msg) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PlumaColors.surface,
        title: const Text('Edytuj wiadomość',
            style: TextStyle(color: PlumaColors.onSurface)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: const TextStyle(color: PlumaColors.onSurface, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('anuluj',
                style: TextStyle(color: PlumaColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () async {
              final newText = ctrl.text.trim();
              if (newText.isEmpty || newText == msg.text) {
                Navigator.pop(ctx);
                return;
              }
              Navigator.pop(ctx);
              try {
                await widget.services.api.editMessage(msg.id, newText);
                setState(() {
                  _messages = _messages.map((m) {
                    if (m.id == msg.id) {
                      return Message(
                        id: m.id, sender: m.sender, recipient: m.recipient,
                        text: newText, timestamp: m.timestamp,
                        createdAt: m.createdAt, edited: true,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                        isImage: m.isImage, isVideo: m.isVideo,
                        imageUrl: m.imageUrl, videoUrl: m.videoUrl,
                        status: m.status,
                      );
                    }
                    return m;
                  }).toList();
                });
              } catch (_) {
                _showSnack('Błąd edycji wiadomości.');
              }
            },
            child: const Text('zapisz',
                style: TextStyle(color: PlumaColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showMessageMenu(Message msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PlumaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit, color: PlumaColors.primary),
                title: const Text('Edytuj',
                    style: TextStyle(color: PlumaColors.onSurface)),
                onTap: () { Navigator.pop(ctx); _editMessage(msg); },
              ),
            ListTile(
              leading: Icon(Icons.copy, color: PlumaColors.onSurfaceVariant),
              title: const Text('Kopiuj tekst',
                  style: TextStyle(color: PlumaColors.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: msg.text));
                _showSnack('Skopiowano do schowka.');
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
                title: const Text('Usuń',
                    style: TextStyle(color: Color(0xFFFF6B6B))),
                onTap: () { Navigator.pop(ctx); _deleteMessage(msg.id); },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPeople();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: GlassCard(
                padding: EdgeInsets.zero,
                radius: 28,
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 300, child: _buildPeopleList(filtered)),
                          const VerticalDivider(width: 1, color: Colors.white10),
                          Expanded(child: _buildChat()),
                        ],
                      )
                    : _mobileShowChat
                        ? _buildChat()
                        : _buildPeopleList(filtered),
              ),
            ),
            if (_showAddModal)
              GlassModal(
                onClose: () => setState(() => _showAddModal = false),
                child: _buildAddModal(),
              ),
          ],
        );
      },
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
                onTap: () => setState(() => _showAllUsers = !_showAllUsers),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showAllUsers
                        ? PlumaColors.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showAllUsers
                          ? PlumaColors.primary.withValues(alpha: 0.3)
                          : Colors.white10,
                    ),
                  ),
                  child: Text(
                    _showAllUsers ? 'wszyscy' : 'znajomi',
                    style: TextStyle(
                      color: _showAllUsers
                          ? PlumaColors.primary
                          : PlumaColors.onSurfaceVariant,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showAddModal = true),
                child: const Text(
                  '+ znajdź osobę',
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
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      _showAllUsers
                          ? 'brak użytkowników'
                          : 'wyślij zaproszenie do znajomego',
                      style: TextStyle(
                        color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final u = filtered[i];
                    final isSel = _selected?.username == u.username;
                    return RepaintBoundary(
                      child: ListTile(
                        onTap: () => _selectPerson(u),
                        leading: NeonAvatar(image: u.pfp, online: true, size: 40),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '@${u.username}',
                                style: TextStyle(
                                  color: isSel ? PlumaColors.primary : PlumaColors.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChat() {
    final sel = _selected;
    if (sel == null) {
      return const Center(
        child: Text(
          'wybierz osobę, aby rozpocząć rozmowę',
          style: TextStyle(
            color: PlumaColors.onSurfaceVariant,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _mobileShowChat = false),
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
                        'brak wiadomości. napisz cos do @${sel.username}!',
                        style: const TextStyle(
                          color: PlumaColors.onSurfaceVariant,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Text(
                          'dzisiaj',
                          style: TextStyle(
                            color: PlumaColors.onSurfaceVariant,
                            fontSize: 10,
                            fontFamily: 'monospace',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isMe = m.sender == widget.currentUser.username;
                          return _messageBubble(m, isMe, sel);
                        },
                      ),
                    ),
                  ],
                ),
        ),
        _buildToolbar(color),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
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
                          ? 'załączono plik wideo'
                          : 'załączono obraz',
                      style: TextStyle(
                          color: color, fontSize: 12, fontFamily: 'monospace'),
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _isCompressing ? null : _pickFile,
                      icon: _isCompressing
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: PlumaColors.primary),
                            )
                          : const Icon(Icons.attach_file,
                              color: PlumaColors.onSurfaceVariant),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        style: const TextStyle(
                            color: PlumaColors.onSurface, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _isCompressing
                              ? 'przetwarzanie pliku...'
                              : 'napisz wiadomosc do @${sel.username}...',
                          hintStyle: TextStyle(
                            color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _sending ? null : _send,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send,
                            color: PlumaColors.onPrimary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          _toolbarBtn('B', FontWeight.bold, () => _wrapText('**', '**')),
          _toolbarBtn('I', null, () => _wrapText('_', '_')),
          _toolbarBtn('S', null, () => _wrapText('~~', '~~')),
          _toolbarBtn('<>', null, () => _wrapText('`', '`')),
        ],
      ),
    );
  }

  Widget _toolbarBtn(String label, FontWeight? weight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: PlumaColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: weight ?? FontWeight.normal,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  void _wrapText(String before, String after) {
    final text = _inputCtrl.text;
    final sel = _inputCtrl.selection;
    if (sel.isCollapsed) {
      final start = sel.start;
      _inputCtrl.text = text.substring(0, start) + before + after + text.substring(start);
      _inputCtrl.selection = TextSelection.collapsed(offset: start + before.length);
    } else {
      final selected = text.substring(sel.start, sel.end);
      _inputCtrl.text = text.substring(0, sel.start) + before + selected + after + text.substring(sel.end);
      _inputCtrl.selection = TextSelection(
        baseOffset: sel.start + before.length,
        extentOffset: sel.end + before.length,
      );
    }
  }

  Widget _messageBubble(Message m, bool isMe, UserProfile peer) {
    final color = Theme.of(context).colorScheme.primary;
    final isMietek = m.sender == 'mietek';
    final mietekAvatar = m.isAI
        ? Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A2A3A),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.smart_toy, size: 12, color: Color(0xFFffd86b)),
          )
        : null;

    return RepaintBoundary(
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: const BoxConstraints(maxWidth: 320),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                if (isMietek) ...[mietekAvatar!, const SizedBox(width: 8)] else NeonAvatar(image: peer.pfp, size: 28),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: isMietek ? null : () => _showMessageMenu(m, isMe),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(14, 10, 14, isMietek ? 6 : 12),
                    decoration: BoxDecoration(
                      color: isMietek
                          ? const Color(0xFF1A1A2E).withValues(alpha: 0.6)
                          : isMe
                              ? color.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      border: Border.all(
                        color: isMietek
                            ? color.withValues(alpha: 0.3)
                            : isMe
                                ? color.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMietek)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                color: Color(0xFFffd86b),
                                fontSize: 9,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        if (m.isImage && m.imageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildMessageImage(m.imageUrl!),
                          ),
                        if (m.isVideo && m.videoUrl != null)
                          Container(
                            width: 220, height: 120,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.play_circle, size: 48),
                            ),
                          ),
                        if (m.text.isNotEmpty)
                          _buildFormattedText(m.text),
                        if (m.edited)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '(edytowano)',
                              style: TextStyle(
                                color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.5),
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusIcon(m, isMe),
                            Text(
                              m.timestamp,
                              style: TextStyle(
                                color: isMe
                                    ? color.withValues(alpha: 0.8)
                                    : isMietek
                                        ? const Color(0xFFffd86b).withValues(alpha: 0.7)
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, width: 220, fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 60));
      } catch (_) {
        return const Icon(Icons.broken_image, size: 60);
      }
    }
    return Image.network(url, width: 220, fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 60));
  }

  Widget _buildFormattedText(String text) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: PlumaColors.onSurface, fontSize: 14),
        children: _parseInline(text),
      ),
    );
  }

  List<TextSpan> _parseInline(String text) {
    final spans = <TextSpan>[];
    var i = 0;
    while (i < text.length) {
      if (text[i] == '`') {
        final end = text.indexOf('`', i + 1);
        if (end != -1) {
          spans.add(TextSpan(
            text: text.substring(i + 1, end),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ));
          i = end + 1;
          continue;
        }
      }
      if (i + 1 < text.length && text[i] == '*' && text[i + 1] == '*') {
        final end = _findClosing(text, i + 2, '**');
        if (end != -1) {
          spans.add(TextSpan(
            text: text.substring(i + 2, end),
            style: const TextStyle(fontWeight: FontWeight.bold),
            children: _parseInline(text.substring(i + 2, end)),
          ));
          i = end + 2;
          continue;
        }
      }
      if (i + 1 < text.length && text[i] == '~' && text[i + 1] == '~') {
        final end = _findClosing(text, i + 2, '~~');
        if (end != -1) {
          spans.add(TextSpan(
            text: text.substring(i + 2, end),
            style: const TextStyle(decoration: TextDecoration.lineThrough),
            children: _parseInline(text.substring(i + 2, end)),
          ));
          i = end + 2;
          continue;
        }
      }
      if (text[i] == '_' && (i == 0 || _isWordBoundary(text[i - 1]))) {
        final end = _findClosingUnderscore(text, i + 1);
        if (end != -1 && (end + 1 >= text.length || _isWordBoundary(text[end + 1]))) {
          spans.add(TextSpan(
            text: text.substring(i + 1, end),
            style: const TextStyle(fontStyle: FontStyle.italic),
            children: _parseInline(text.substring(i + 1, end)),
          ));
          i = end + 1;
          continue;
        }
      }
      var j = i + 1;
      while (j < text.length && text[j] != '`' && text[j] != '*' && text[j] != '~' && text[j] != '_') {
        j++;
      }
      spans.add(TextSpan(text: text.substring(i, j)));
      i = j;
    }
    return spans;
  }

  int _findClosing(String text, int start, String marker) {
    return text.indexOf(marker, start);
  }

  int _findClosingUnderscore(String text, int start) {
    for (var i = start; i < text.length; i++) {
      if (text[i] == '_' && (i == 0 || text[i - 1] != '\\')) {
        return i;
      }
    }
    return -1;
  }

  bool _isWordBoundary(String ch) {
    return ch == ' ' || ch == '\n' || ch == '\t' || ch == ',' || ch == '.' ||
        ch == '!' || ch == '?' || ch == ';' || ch == ':' || ch == '(' ||
        ch == ')' || ch == '[' || ch == ']' || ch == '"' || ch == '\'' ||
        ch == '-' || ch == '/';
  }

  Widget _buildStatusIcon(Message m, bool isMe) {
    if (m.sender == 'mietek') return const SizedBox(width: 14);
    if (!isMe) return const SizedBox(width: 14);
    final color = Theme.of(context).colorScheme.primary;
    switch (m.status) {
      case 'read':
        return Icon(Icons.done_all, size: 14, color: color);
      case 'delivered':
        return Icon(Icons.done_all, size: 14, color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.6));
      default:
        return Icon(Icons.done, size: 14, color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.4));
    }
  }

  Widget _buildAddModal() {
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
                  'wybierz osobę z platformy',
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
                      'brak zarejestrowanych osób pasujących do szukania',
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
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                try {
                                  await widget.services.api.sendInvitation(
                                      widget.currentUser.username, u.username);
                                  if (mounted) _showSnack('Wyslano zaproszenie do @${u.username}');
                                } catch (_) {
                                  if (mounted) _showSnack('Błąd wysyłania zaproszenia.');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: PlumaColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: PlumaColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: const Text(
                                  'zaproś',
                                  style: TextStyle(
                                    color: PlumaColors.primary,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'czatuj',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                    fontFamily: 'monospace'),
                              ),
                            ),
                          ],
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
