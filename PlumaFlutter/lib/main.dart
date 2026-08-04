import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/models.dart';
import 'api/saved_accounts.dart';
import 'api/users_api.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'theme/pluma_theme.dart';

void main() {
  runApp(const PlumaApp());
}

class PlumaApp extends StatelessWidget {
  const PlumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pluma',
      debugShowCheckedModeBanner: false,
      theme: PlumaTheme.build(PlumaColors.primary),
      home: const LoginScreen(),
    );
  }
}

/// Shared application services passed down to screens.
class AppServices {
  final ApiClient api = ApiClient();
  late final AuthApi auth = AuthApi(api);
  late final UsersApi users = UsersApi(api);

  static const Color defaultAccent = PlumaColors.primary;
}

/// Entry point invoked after successful login.
class RootScreen extends StatefulWidget {
  final UserProfile user;
  const RootScreen({super.key, required this.user});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final AppServices _services = AppServices();
  late UserProfile _currentUser;
  List<UserProfile> _allUsers = [];
  Color _accentColor = PlumaColors.primary;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _syncAccent(_currentUser.color);
    _loadUsers();
  }

  void _syncAccent(String hex) {
    final color = PlumaTheme.parseHex(hex);
    if (color != _accentColor) {
      setState(() => _accentColor = color);
    }
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _services.users.getAllUsers();
      if (mounted) setState(() => _allUsers = users);
    } catch (_) {
      // ignore polling failures
    }
  }

  void _onUserUpdated(UserProfile updated) {
    setState(() {
      _currentUser = updated;
      _syncAccent(updated.color);
    });
    SavedAccounts.save(updated);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pluma',
      debugShowCheckedModeBanner: false,
      theme: PlumaTheme.build(_accentColor),
      home: HomeShell(
        services: _services,
        currentUser: _currentUser,
        allUsers: _allUsers,
        onUserUpdated: _onUserUpdated,
        onLogout: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
        onRefreshUsers: _loadUsers,
      ),
    );
  }
}
