import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/message.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({ApiService? api, SocketService? socket})
    : _api = api ?? ApiService(),
      _socket = socket ?? SocketService();

  final ApiService _api;
  final SocketService _socket;

  String? _token;
  String? _myUserId;
  List<User> _users = [];
  final Set<String> _onlineIds = {};
  final Map<String, List<Message>> _conversations = {};
  final StreamController<String> _errors = StreamController<String>.broadcast();

  bool _connected = false;
  bool _loadingUsers = false;

  String get myUserId => _myUserId ?? '';
  List<User> get users =>
      _users.where((user) => user.id != _myUserId).toList(growable: false);
  bool get connected => _connected;
  bool get loadingUsers => _loadingUsers;
  Stream<String> get errors => _errors.stream;

  bool isOnline(String userId) => _onlineIds.contains(userId);

  List<Message> messagesWith(String userId) =>
      List.unmodifiable(_conversations[userId] ?? const []);

  Future<void> connect({
    required String token,
    required String myUserId,
  }) async {
    _token = token;
    _myUserId = myUserId;

    _socket
      ..onConnect = () {
        _connected = true;
        notifyListeners();
      }
      ..onDisconnect = () {
        _connected = false;
        notifyListeners();
      }
      ..onPresenceChanged = _updatePresence
      ..onMessage = _addMessage
      ..onError = _errors.add
      ..connect(token);

    await loadUsers();
  }

  Future<void> loadUsers() async {
    final token = _token;
    if (token == null) return;

    _loadingUsers = true;
    notifyListeners();

    try {
      _users = await _api.getUsers(token);
      _onlineIds
        ..clear()
        ..addAll(_users.where((user) => user.online).map((user) => user.id));
    } on ApiException catch (error) {
      _errors.add(error.message);
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String otherUserId) async {
    final token = _token;
    if (token == null) return;

    try {
      final history = await _api.getMessages(token, otherUserId);
      final current = _conversations[otherUserId] ?? const <Message>[];
      final byId = {
        for (final message in [...history, ...current]) message.id: message,
      };
      final messages = byId.values.toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      _conversations[otherUserId] = messages;
      notifyListeners();
    } on ApiException catch (error) {
      _errors.add(error.message);
    }
  }

  Future<void> sendMessage(String otherUserId, String text) async {
    final message = text.trim();
    if (message.isEmpty) return;

    if (_connected) {
      _socket.sendMessage(otherUserId, message);
      return;
    }

    final token = _token;
    if (token == null) return;

    try {
      _addMessage(await _api.sendMessage(token, otherUserId, message));
    } on ApiException catch (error) {
      _errors.add(error.message);
    }
  }

  void _updatePresence(List<String> ids) {
    _onlineIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  void _addMessage(Message message) {
    final otherUserId = message.senderId == _myUserId
        ? message.receiverId
        : message.senderId;
    final messages = _conversations.putIfAbsent(otherUserId, () => []);

    if (messages.any((item) => item.id == message.id)) return;
    messages.add(message);
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    notifyListeners();
  }

  void reset() {
    _socket.disconnect();
    _token = null;
    _myUserId = null;
    _users = [];
    _onlineIds.clear();
    _conversations.clear();
    _connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _errors.close();
    super.dispose();
  }
}
