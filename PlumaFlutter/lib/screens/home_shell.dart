import 'package:flutter/material.dart';

import '../api/models.dart';
import '../main.dart';
import '../theme/glass_components.dart';
import '../theme/pluma_theme.dart';
import 'dashboard_view.dart';
import 'invitations_view.dart';
import 'messaging_view.dart';
import 'profile_view.dart';

enum TabType { pulpit, osoby, zaproszenia, profil }

class HomeShell extends StatefulWidget {
  final AppServices services;
  final UserProfile currentUser;
  final List<UserProfile> allUsers;
  final void Function(UserProfile) onUserUpdated;
  final VoidCallback onLogout;

  const HomeShell({
    super.key,
    required this.services,
    required this.currentUser,
    required this.allUsers,
    required this.onUserUpdated,
    required this.onLogout,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  TabType _activeTab = TabType.pulpit;
  late UserProfile _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser != widget.currentUser) {
      _currentUser = widget.currentUser;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return BlissBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 768;
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Row(
                  children: [
                    if (isDesktop)
                      _buildDesktopRail(context, color)
                    else
                      const SizedBox.shrink(),
                    Expanded(child: _buildContent()),
                  ],
                ),
                if (!isDesktop)
                  _buildBottomBar(context, color),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeTab) {
      case TabType.pulpit:
        return DashboardView(services: widget.services);
      case TabType.osoby:
        return MessagingView(
          services: widget.services,
          currentUser: _currentUser,
          allUsers: widget.allUsers,
        );
      case TabType.zaproszenia:
        return InvitationsView(
          services: widget.services,
          currentUser: _currentUser,
          allUsers: widget.allUsers,
        );
      case TabType.profil:
        return ProfileView(
          services: widget.services,
          currentUser: _currentUser,
          onUserUpdated: widget.onUserUpdated,
        );
    }
  }

  Widget _buildDesktopRail(BuildContext context, Color color) {
    return Container(
      width: 72,
      color: PlumaColors.surface.withValues(alpha: 0.45),
      child: Column(
        children: [
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => setState(() => _activeTab = TabType.pulpit),
            child: Image.asset(
              'assets/logo-kogut-100x100.png',
              width: 40,
              height: 40,
            ),
          ),
          const SizedBox(height: 32),
          _railItem(context, TabType.pulpit, Icons.dashboard, 'pulpit'),
          _railItem(context, TabType.osoby, Icons.group, 'osoby'),
          _railItem(context, TabType.zaproszenia, Icons.person_add, 'zaproszenia'),
          _railItem(context, TabType.profil, Icons.person, 'profil'),
          const Spacer(),
          _avatarButton(context),
          const SizedBox(height: 12),
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Wyloguj sie',
            icon: const Icon(Icons.logout, color: PlumaColors.onSurfaceVariant),
            iconSize: 18,
            color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _railItem(BuildContext context, TabType tab, IconData icon, String label) {
    final active = _activeTab == tab;
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: () => setState(() => _activeTab = tab),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color.withValues(alpha: 0.1) : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: active ? color : PlumaColors.onSurfaceVariant,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarButton(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _activeTab = TabType.profil),
      child: NeonAvatar(
        image: _currentUser.pfp,
        size: 40,
        accent: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Color color) {
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: PlumaColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomItem(TabType.pulpit, Icons.dashboard),
            _bottomItem(TabType.osoby, Icons.group),
            _bottomItem(TabType.zaproszenia, Icons.person_add),
            _bottomItem(TabType.profil, Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _bottomItem(TabType tab, IconData icon) {
    final active = _activeTab == tab;
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        width: 48,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? color.withValues(alpha: 0.1) : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: active ? color : PlumaColors.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}
