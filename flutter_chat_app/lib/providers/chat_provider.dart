import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/group.dart';
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
  List<Group> _groups = [];
  final Set<String> _onlineIds = {};
  final Map<String, List<Message>> _directConversations = {};
  final Map<String, List<Message>> _groupConversations = {};
  final StreamController<String> _errors = StreamController<String>.broadcast();

  bool _connected = false;
  bool _hasConnectedOnce = false;
  bool _loadingUsers = false;
  bool _loadingGroups = false;

  String get myUserId => _myUserId ?? '';
  List<User> get users =>
      _users.where((user) => user.id != _myUserId).toList(growable: false);
  List<Group> get groups => List.unmodifiable(_groups);
  bool get connected => _connected;
  bool get loadingUsers => _loadingUsers;
  bool get loadingGroups => _loadingGroups;
  Stream<String> get errors => _errors.stream;

  bool isOnline(String userId) => _onlineIds.contains(userId);

  String usernameFor(String userId) {
    if (userId == _myUserId) return 'You';
    for (final user in _users) {
      if (user.id == userId) return user.username;
    }
    return 'Unknown user';
  }

  int onlineMembers(Group group) {
    return group.memberIds.where(_onlineIds.contains).length;
  }

  List<Message> messagesWith(String userId) =>
      List.unmodifiable(_directConversations[userId] ?? const []);

  List<Message> messagesForGroup(String groupId) =>
      List.unmodifiable(_groupConversations[groupId] ?? const []);

  Future<void> connect({
    required String token,
    required String myUserId,
  }) async {
    _token = token;
    _myUserId = myUserId;

    _socket
      ..onConnect = () {
        _connected = true;
        if (_hasConnectedOnce) {
          unawaited(Future.wait([loadUsers(), loadGroups()]));
        }
        _hasConnectedOnce = true;
        notifyListeners();
      }
      ..onDisconnect = () {
        _connected = false;
        notifyListeners();
      }
      ..onPresenceChanged = _updatePresence
      ..onDirectMessage = _addDirectMessage
      ..onGroupMessage = _addGroupMessage
      ..onGroupCreated = _upsertGroup
      ..onError = _errors.add
      ..connect(token);

    await Future.wait([loadUsers(), loadGroups()]);
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

  Future<void> loadGroups() async {
    final token = _token;
    if (token == null) return;

    _loadingGroups = true;
    notifyListeners();

    try {
      final loaded = await _api.getGroups(token);
      final byId = {
        for (final group in [..._groups, ...loaded]) group.id: group,
      };
      _groups = byId.values.toList();
    } on ApiException catch (error) {
      _errors.add(error.message);
    } finally {
      _loadingGroups = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String otherUserId) async {
    final token = _token;
    if (token == null) return;

    try {
      final history = await _api.getMessages(token, otherUserId);
      _directConversations[otherUserId] = _mergeMessages(
        history,
        _directConversations[otherUserId] ?? const [],
      );
      notifyListeners();
    } on ApiException catch (error) {
      _errors.add(error.message);
    }
  }

  Future<void> loadGroupMessages(String groupId) async {
    final token = _token;
    if (token == null) return;

    try {
      final history = await _api.getGroupMessages(token, groupId);
      _groupConversations[groupId] = _mergeMessages(
        history,
        _groupConversations[groupId] ?? const [],
      );
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
      _addDirectMessage(await _api.sendMessage(token, otherUserId, message));
    } on ApiException catch (error) {
      _errors.add(error.message);
    }
  }

  Future<void> sendGroupMessage(String groupId, String text) async {
    final message = text.trim();
    if (message.isEmpty) return;

    if (_connected) {
      _socket.sendGroupMessage(groupId, message);
      return;
    }

    final token = _token;
    if (token == null) return;

    try {
      _addGroupMessage(await _api.sendGroupMessage(token, groupId, message));
    } on ApiException catch (error) {
      _errors.add(error.message);
    }
  }

  Future<Group?> createGroup(String name, List<String> memberIds) async {
    final token = _token;
    if (token == null) return null;

    try {
      final group = await _api.createGroup(token, name.trim(), memberIds);
      _upsertGroup(group);
      return group;
    } on ApiException catch (error) {
      _errors.add(error.message);
      return null;
    }
  }

  void _updatePresence(List<String> ids) {
    _onlineIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  void _addDirectMessage(Message message) {
    final otherUserId = message.senderId == _myUserId
        ? message.receiverId
        : message.senderId;
    if (otherUserId == null) return;

    final messages = _directConversations.putIfAbsent(otherUserId, () => []);
    if (messages.any((item) => item.id == message.id)) return;

    messages.add(message);
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    notifyListeners();
  }

  void _addGroupMessage(Message message) {
    final groupId = message.groupId;
    if (groupId == null) return;

    final messages = _groupConversations.putIfAbsent(groupId, () => []);
    if (messages.any((item) => item.id == message.id)) return;

    messages.add(message);
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    notifyListeners();
  }

  void _upsertGroup(Group group) {
    final index = _groups.indexWhere((item) => item.id == group.id);
    if (index == -1) {
      _groups = [group, ..._groups];
    } else {
      _groups[index] = group;
    }
    notifyListeners();
  }

  List<Message> _mergeMessages(List<Message> first, List<Message> second) {
    final byId = {
      for (final message in [...first, ...second]) message.id: message,
    };
    return byId.values.toList()..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  void reset() {
    _socket.disconnect();
    _token = null;
    _myUserId = null;
    _users = [];
    _groups = [];
    _onlineIds.clear();
    _directConversations.clear();
    _groupConversations.clear();
    _connected = false;
    _hasConnectedOnce = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _errors.close();
    super.dispose();
  }
}
