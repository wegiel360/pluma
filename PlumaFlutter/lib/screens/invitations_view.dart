import 'dart:async';

import 'package:flutter/material.dart';

import '../api/models.dart';
import '../main.dart';
import '../theme/glass_components.dart';
import '../theme/pluma_theme.dart';

class InvitationsView extends StatefulWidget {
  final AppServices services;
  final UserProfile currentUser;
  final List<UserProfile> allUsers;

  const InvitationsView({
    super.key,
    required this.services,
    required this.currentUser,
    required this.allUsers,
  });

  @override
  State<InvitationsView> createState() => _InvitationsViewState();
}

class _InvitationsViewState extends State<InvitationsView> {
  List<Invitation> _invitations = [];
  bool _loading = true;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final inv = await widget.services.api
          .getIncomingInvitations(widget.currentUser.username);
      if (mounted) setState(() { _invitations = inv; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(String invitationId, bool accept) async {
    try {
      await widget.services.api.respondToInvitation(invitationId, accept);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Blad odpowiedzi na zaproszenie.')),
      );
    }
  }

  UserProfile? _findUser(String username) {
    try {
      return widget.allUsers.firstWhere((u) => u.username == username);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        radius: 28,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add, color: PlumaColors.primary, size: 24),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'zaproszenia',
                    style: TextStyle(
                      color: PlumaColors.onSurfaceVariant,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Text(
                  '${_invitations.length} oczekujace',
                  style: TextStyle(
                    color: PlumaColors.primary.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _invitations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mail_outline,
                                  color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.3),
                                  size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                'brak nowych zaproszen',
                                style: TextStyle(
                                  color: PlumaColors.onSurfaceVariant,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'wyslij zaproszenie do znajomego z zakladki osoby',
                                style: TextStyle(
                                  color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _invitations.length,
                          itemBuilder: (context, i) {
                            final inv = _invitations[i];
                            final fromUser = _findUser(inv.from);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  NeonAvatar(
                                    image: fromUser?.pfp,
                                    size: 44,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '@${inv.from}',
                                          style: const TextStyle(
                                            color: PlumaColors.onSurface,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'chce byc Twoim znajomym',
                                          style: TextStyle(
                                            color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.7),
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _respond(inv.id, true),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: PlumaColors.primary.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: PlumaColors.primary.withValues(alpha: 0.3)),
                                          ),
                                          child: const Text(
                                            'akceptuj',
                                            style: TextStyle(
                                              color: PlumaColors.primary,
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _respond(inv.id, false),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.white10),
                                          ),
                                          child: Text(
                                            'odrzuc',
                                            style: TextStyle(
                                              color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.7),
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
