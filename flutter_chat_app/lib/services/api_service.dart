import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/group.dart';
import '../models/message.dart';
import '../models/user.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class AuthResult {
  final User user;
  final String token;
  AuthResult({required this.user, required this.token});
}

class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = res.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Unexpected server response.', res.statusCode);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final message = body['message'] as String? ?? 'Request failed.';
    throw ApiException(message, res.statusCode);
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    try {
      final res = await _client.get(_uri(path), headers: _headers(token));
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Cannot reach the server. Is it running at '
        '${AppConfig.baseUrl}?',
      );
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _client.post(
        _uri(path),
        headers: _headers(token),
        body: jsonEncode(body ?? const {}),
      );
      return _decode(res);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Cannot reach the server. Is it running at '
        '${AppConfig.baseUrl}?',
      );
    }
  }

  Future<AuthResult> register(String username, String password) async {
    final body = await _post(
      '/api/auth/register',
      body: {'username': username, 'password': password},
    );
    return AuthResult(
      user: User.fromJson(body['user'] as Map<String, dynamic>),
      token: body['token'] as String,
    );
  }

  Future<AuthResult> login(String username, String password) async {
    final body = await _post(
      '/api/auth/login',
      body: {'username': username, 'password': password},
    );
    return AuthResult(
      user: User.fromJson(body['user'] as Map<String, dynamic>),
      token: body['token'] as String,
    );
  }

  Future<User> me(String token) async {
    final body = await _get('/api/auth/me', token: token);
    return User.fromJson(body['user'] as Map<String, dynamic>);
  }

  Future<List<User>> getUsers(String token) async {
    final body = await _get('/api/chat/users', token: token);
    final list = (body['users'] as List<dynamic>? ?? const []);
    return list.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Message>> getMessages(String token, String otherUserId) async {
    final body = await _get(
      '/api/chat/direct/$otherUserId/messages',
      token: token,
    );
    final list = (body['messages'] as List<dynamic>? ?? const []);
    return list
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Message> sendMessage(
    String token,
    String otherUserId,
    String text,
  ) async {
    final body = await _post(
      '/api/chat/direct/$otherUserId/messages',
      token: token,
      body: {'text': text},
    );
    return Message.fromJson(body['message'] as Map<String, dynamic>);
  }

  Future<List<Group>> getGroups(String token) async {
    final body = await _get('/api/chat/groups', token: token);
    final list = body['groups'] as List<dynamic>? ?? const [];
    return list
        .map((item) => Group.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Group> createGroup(
    String token,
    String name,
    List<String> memberIds,
  ) async {
    final body = await _post(
      '/api/chat/groups',
      token: token,
      body: {'name': name, 'memberIds': memberIds},
    );
    return Group.fromJson(body['group'] as Map<String, dynamic>);
  }

  Future<List<Message>> getGroupMessages(String token, String groupId) async {
    final body = await _get('/api/chat/groups/$groupId/messages', token: token);
    final list = body['messages'] as List<dynamic>? ?? const [];
    return list
        .map((item) => Message.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Message> sendGroupMessage(
    String token,
    String groupId,
    String text,
  ) async {
    final body = await _post(
      '/api/chat/groups/$groupId/messages',
      token: token,
      body: {'text': text},
    );
    return Message.fromJson(body['message'] as Map<String, dynamic>);
  }
}
