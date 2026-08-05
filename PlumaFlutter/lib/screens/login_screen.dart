import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/saved_accounts.dart';
import '../theme/glass_components.dart';
import '../theme/pluma_theme.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AppServices _services = AppServices();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _registerMode = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  List<UserProfile> _savedAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final accounts = await SavedAccounts.load();
    if (mounted) setState(() => _savedAccounts = accounts);
  }

  String _clean(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'^@'), '');

  Future<void> _submit() async {
    final username = _clean(_usernameCtrl.text);
    final password = _passwordCtrl.text;
    if (username.isEmpty) {
      setState(() => _error = 'Wprowadź prawidłowy pseudonim');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Wprowadź hasło');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _registerMode
          ? await _services.api.register(username, password)
          : await _services.api.login(username, password);
      await SavedAccounts.save(user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RootScreen(user: user)),
        (route) => false,
      );
    } on Exception catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } catch (e) {
      setState(() => _error = 'Błąd podczas logowania/rejestracji');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickLogin(String accountUsername) async {
    final passwordCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PlumaColors.surface,
        title: Text('Logowanie @$accountUsername',
            style: const TextStyle(color: PlumaColors.onSurface)),
        content: TextField(
          controller: passwordCtrl,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: PlumaColors.onSurface),
          decoration: const InputDecoration(
            hintText: 'Hasło',
            hintStyle: TextStyle(color: PlumaColors.onSurfaceVariant),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj',
                style: TextStyle(color: PlumaColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zaloguj',
                style: TextStyle(color: PlumaColors.primary)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final password = passwordCtrl.text;
    if (password.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _services.api.login(accountUsername, password);
      await SavedAccounts.save(user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RootScreen(user: user)),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = 'Nie udało się zalogować na konto @$accountUsername');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeSaved(String username) async {
    await SavedAccounts.remove(username);
    await _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: BlissBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                padding: const EdgeInsets.all(28),
                radius: 28,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Image.asset(
                          'assets/logo-kogut-250x250.png',
                          height: 80,
                          width: 80,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'pluma',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: color,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'komunikator z wyglądem Płynny Żel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PlumaColors.errorContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: PlumaColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    GlassInput(
                      label: 'Użytkownik',
                      hint: 'wpisz swój pseudonim...',
                      controller: _usernameCtrl,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    GlassInput(
                      label: 'Hasło',
                      hint: 'hasło',
                      controller: _passwordCtrl,
                      icon: Icons.lock,
                      obscureText: _obscure,
                      showToggle: true,
                      onToggleVisibility: () => setState(() => _obscure = !_obscure),
                    ),
                    const SizedBox(height: 20),
                    NeonButton(
                      label: _loading
                          ? 'Ładowanie...'
                          : (_registerMode ? 'Zarejestruj się' : 'Zaloguj się'),
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _registerMode = !_registerMode),
                      child: Text(
                        _registerMode
                            ? 'Masz już konto? Zaloguj się'
                            : 'Nie masz konta? Zarejestruj się',
                        style: TextStyle(
                          color: PlumaColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const Divider(height: 40, color: Colors.white10),

                    Text(
                      'zapisane konta na tym urządzeniu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_savedAccounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'brak zapisanych kont',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _savedAccounts.map((acc) {
                          return RepaintBoundary(
                            child: GestureDetector(
                              onTap: () => _quickLogin(acc.username),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NeonAvatar(image: acc.pfp, size: 28),
                                    const SizedBox(width: 8),
                                    Text(
                                      '@${acc.username}',
                                      style: const TextStyle(
                                        color: PlumaColors.onSurface,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _removeSaved(acc.username),
                                      child: const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: PlumaColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
