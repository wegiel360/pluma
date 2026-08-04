import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class SavedAccounts {
  static const _key = 'pluma_saved_accounts';

  static Future<List<UserProfile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => UserProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final filtered =
        current.where((u) => u.username.toLowerCase() != user.username.toLowerCase()).toList();
    filtered.insert(0, user);
    await prefs.setString(_key, jsonEncode(filtered.map((u) => u.toJson()).toList()));
  }

  static Future<void> remove(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final filtered = current
        .where((u) => u.username.toLowerCase() != username.toLowerCase())
        .toList();
    await prefs.setString(_key, jsonEncode(filtered.map((u) => u.toJson()).toList()));
  }
}
