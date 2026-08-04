import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_api.dart';
import 'messages_api.dart';
import 'users_api.dart';
import 'weather_api.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  static const String _envBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  String get baseUrl => _envBase;

  late final AuthApi authApi = AuthApi(this);
  late final UsersApi usersApi = UsersApi(this);
  late final MessagesApi messagesApi = MessagesApi(this);
  late final WeatherApi weatherApi = WeatherApi(this);

  Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$_envBase$path');
    http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 12));
    } on SocketException {
      throw const ApiException('Brak połączenia z serwerem. Sprawdź backend.');
    } catch (e) {
      throw ApiException('Błąd połączenia: $e');
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_envBase$path');
    http.Response res;
    try {
      res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw const ApiException('Brak połączenia z serwerem. Sprawdź backend.');
    } catch (e) {
      throw ApiException('Błąd połączenia: $e');
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$_envBase$path');
    http.Response res;
    try {
      res = await http.delete(uri).timeout(const Duration(seconds: 12));
    } on SocketException {
      throw const ApiException('Brak połączenia z serwerem.');
    } catch (e) {
      throw ApiException('Błąd połączenia: $e');
    }
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Nieprawidłowa odpowiedź serwera.');
    }
    if (body['status'] != 'success') {
      final msg = body['message']?.toString() ?? 'Błąd serwera.';
      throw ApiException(msg);
    }
    return body;
  }
}
