import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/image_utils.dart';
import '../api/models.dart';
import '../main.dart';
import '../theme/glass_components.dart';
import '../theme/pluma_theme.dart';

class ProfileView extends StatefulWidget {
  final AppServices services;
  final UserProfile currentUser;
  final void Function(UserProfile) onUserUpdated;

  const ProfileView({
    super.key,
    required this.services,
    required this.currentUser,
    required this.onUserUpdated,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late String _bio;
  late String _banner;
  late String _pfp;
  final _bioCtrl = TextEditingController();
  bool _editingBio = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bio = widget.currentUser.bio;
    _banner = widget.currentUser.banner;
    _pfp = widget.currentUser.pfp;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveBio() async {
    _bio = _bioCtrl.text;
    setState(() => _saving = true);
    try {
      await widget.services.api.updateUser(
        widget.currentUser.username,
        bio: _bio,
      );
      widget.onUserUpdated(widget.currentUser.copyWith(bio: _bio));
      setState(() => _editingBio = false);
    } catch (_) {
      setState(() => _error = 'Blad zapisu bio.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBanner() async {
    final source = await showImageSourcePicker(context);
    if (source == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 1600);
    if (file == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final base64 = await ImageUtils.compressToBase64(file, maxDimension: 1600);
      setState(() => _banner = base64);
      await widget.services.api.updateUser(
        widget.currentUser.username,
        banner: base64,
      );
      widget.onUserUpdated(widget.currentUser.copyWith(banner: base64));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPfp() async {
    final source = await showImageSourcePicker(context);
    if (source == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 600);
    if (file == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final base64 = await ImageUtils.compressToBase64(file, maxDimension: 600);
      setState(() => _pfp = base64);
      await widget.services.api.updateUser(
        widget.currentUser.username,
        pfp: base64,
      );
      widget.onUserUpdated(widget.currentUser.copyWith(pfp: base64));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeColor(String hex) async {
    widget.onUserUpdated(widget.currentUser.copyWith(color: hex));
    try {
      await widget.services.api.updateUser(
        widget.currentUser.username,
        color: hex,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final currentColor = PlumaTheme.parseHex(widget.currentUser.color);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 21 / 8,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 120),
                    child: _bannerImage(double.infinity),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          PlumaColors.surface.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: NeonButton(
                    label: _saving ? 'zapisywanie...' : 'zmien tlo z pc',
                    icon: Icons.upload_file,
                    loading: _saving,
                    onPressed: _saving ? null : _pickBanner,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _pickPfp,
                child: NeonAvatar(image: _pfp, size: 96),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${widget.currentUser.username}',
                      style: TextStyle(
                        color: color,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'dolaczyl ${ImageUtils.formatJoinedDate(widget.currentUser.createdAt)}',
                      style: const TextStyle(
                        color: PlumaColors.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              NeonButton(
                label: _editingBio ? 'zapisujac...' : 'edytuj bio',
                onPressed: _editingBio
                    ? null
                    : () {
                        _bioCtrl.text = _bio;
                        setState(() => _editingBio = true);
                      },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: const TextStyle(
                    color: Color(0xFFFF6B6B), fontSize: 12),
              ),
            ),
          GlassCard(
            padding: const EdgeInsets.all(20),
            radius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fingerprint,
                        color: PlumaColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'o mnie',
                      style: TextStyle(
                        color: PlumaColors.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_editingBio) ...[
                  TextField(
                    controller: _bioCtrl,
                    maxLines: 4,
                    style: const TextStyle(
                        color: PlumaColors.onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.4),
                      hintText: 'Napisz cos o sobie...',
                      hintStyle: const TextStyle(
                          color: PlumaColors.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            setState(() => _editingBio = false),
                        child: const Text('anuluj',
                            style: TextStyle(
                                color: PlumaColors.onSurfaceVariant)),
                      ),
                      const SizedBox(width: 8),
                      NeonButton(
                        label: 'zapisz',
                        loading: _saving,
                        onPressed: _saving ? null : _saveBio,
                      ),
                    ],
                  ),
                ] else
                  Text(
                    _bio.isEmpty ? 'i use arch btw' : _bio,
                    style: const TextStyle(
                      color: PlumaColors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      height: 1.6,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.all(24),
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette,
                        color: PlumaColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'personalizacja wygladu',
                      style: TextStyle(
                        color: PlumaColors.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'wybierz swoj unikalny kolor profilu, ktory odmieni interfejs.',
                  style: TextStyle(
                    color: PlumaColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    ...PlumaColors.presets.map((preset) {
                      final presetColor =
                          PlumaTheme.parseHex(preset['color']!);
                      final isActive = currentColor.toARGB32() ==
                          presetColor.toARGB32();
                      return _colorDot(presetColor,
                          preset['label']!, isActive,
                          () => _changeColor(preset['color']!));
                    }),
                    _customColorPicker(currentColor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _bannerImage(double height) {
    if (_banner.startsWith('data:')) {
      return Image.network(
        _banner,
        height: height == double.infinity ? null : height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height == double.infinity ? null : height,
          color: PlumaColors.surfaceBright,
        ),
      );
    }
    return Image.asset(
      _banner,
      height: height == double.infinity ? null : height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: height == double.infinity ? null : height,
        color: PlumaColors.surfaceBright,
      ),
    );
  }

  Widget _colorDot(
      Color c, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: active
                  ? Border.all(
                      color: c.withValues(alpha: 0.6), width: 4)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: PlumaColors.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _customColorPicker(Color currentColor) {
    return GestureDetector(
      onTap: () => _showColorPicker(currentColor),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentColor,
              border: Border.all(color: Colors.white38, width: 2),
            ),
          ),
          const SizedBox(height: 6),
          const Text('wlasny',
              style: TextStyle(
                  color: PlumaColors.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Future<void> _showColorPicker(Color initial) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: PlumaColors.surface,
          title: const Text('Wybierz kolor',
              style: TextStyle(color: PlumaColors.onSurface)),
          content: SizedBox(
            width: 260,
            height: 40,
            child: GridView.count(
              crossAxisCount: 6,
              children: [
                _pickerColor(Colors.red, ctx),
                _pickerColor(Colors.orange, ctx),
                _pickerColor(Colors.yellow, ctx),
                _pickerColor(Colors.green, ctx),
                _pickerColor(Colors.cyan, ctx),
                _pickerColor(Colors.blue, ctx),
                _pickerColor(Colors.purple, ctx),
                _pickerColor(Colors.pink, ctx),
                _pickerColor(Colors.teal, ctx),
                _pickerColor(Colors.lime, ctx),
                _pickerColor(Colors.indigo, ctx),
                _pickerColor(Colors.amber, ctx),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) {
      await _changeColor(PlumaTheme.colorToHex(picked));
    }
  }

  Widget _pickerColor(Color c, BuildContext ctx) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, c),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
