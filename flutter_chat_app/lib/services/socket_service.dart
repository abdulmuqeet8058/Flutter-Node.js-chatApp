import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../models/group.dart';
import '../models/message.dart';

class SocketService {
  io.Socket? _socket;

  void Function(List<String> userIds)? onPresenceChanged;
  void Function(Message message)? onDirectMessage;
  void Function(Message message)? onGroupMessage;
  void Function(Group group)? onGroupCreated;
  void Function(String message)? onError;
  void Function()? onConnect;
  void Function()? onDisconnect;

  void connect(String token) {
    disconnect();

    final socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    socket.onConnect((_) => onConnect?.call());
    socket.onDisconnect((_) => onDisconnect?.call());
    socket.onConnectError((_) => onError?.call('Could not connect to chat.'));

    socket.on('users:online', (data) {
      final ids = (data as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .toList();
      onPresenceChanged?.call(ids);
    });

    socket.on('direct:message', (data) {
      if (data is Map) {
        onDirectMessage?.call(
          Message.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    });

    socket.on('group:message', (data) {
      if (data is Map) {
        onGroupMessage?.call(Message.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    socket.on('group:created', (data) {
      if (data is Map) {
        onGroupCreated?.call(Group.fromJson(Map<String, dynamic>.from(data)));
      }
    });

    socket.on('chat:error', (data) {
      final message = data is Map ? data['message']?.toString() : null;
      onError?.call(message ?? 'Something went wrong in the chat.');
    });

    _socket = socket;
    socket.connect();
  }

  void sendMessage(String receiverId, String text) {
    _socket?.emit('direct:send', {'receiverId': receiverId, 'text': text});
  }

  void sendGroupMessage(String groupId, String text) {
    _socket?.emit('group:send', {'groupId': groupId, 'text': text});
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
