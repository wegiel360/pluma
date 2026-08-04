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
      setState(() => _error = 'Wprowadz prawidlowy pseudonim');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Wprowadz haslo');
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
      setState(() => _error = 'Blad podczas logowania/rejestracji');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _quickLogin(String accountUsername) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _services.api.getOrCreateUser(accountUsername);
      await SavedAccounts.save(user);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RootScreen(user: user)),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = 'Nie udalo sie zalogowac na konto @$accountUsername');
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
                          'liquid glass messenger',
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
                      label: 'Uzytkownik',
                      hint: 'wpisz swoj pseudonim...',
                      controller: _usernameCtrl,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    GlassInput(
                      label: 'Haslo',
                      hint: 'haslo',
                      controller: _passwordCtrl,
                      icon: Icons.lock,
                      obscureText: _obscure,
                      showToggle: true,
                      onToggleVisibility: () => setState(() => _obscure = !_obscure),
                    ),
                    const SizedBox(height: 20),
                    NeonButton(
                      label: _loading
                          ? 'Ladowanie...'
                          : (_registerMode ? 'Zarejestruj sie' : 'Zaloguj sie'),
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _registerMode = !_registerMode),
                      child: Text(
                        _registerMode
                            ? 'Masz juz konto? Zaloguj sie'
                            : 'Nie masz konta? Zarejestruj sie',
                        style: TextStyle(
                          color: PlumaColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const Divider(height: 40, color: Colors.white10),

                    Text(
                      'zapisane konta na tym urzadzeniu',
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
                          return GestureDetector(
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
