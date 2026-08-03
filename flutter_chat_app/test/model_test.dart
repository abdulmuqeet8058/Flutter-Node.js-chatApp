import 'package:flutter_chat_app/models/group.dart';
import 'package:flutter_chat_app/models/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a group returned by the API', () {
    final group = Group.fromJson({
      'id': 'group-1',
      'name': 'Weekend plans',
      'ownerId': 'user-1',
      'memberIds': ['user-1', 'user-2'],
      'createdAt': '2026-07-30T12:00:00.000Z',
    });

    expect(group.name, 'Weekend plans');
    expect(group.ownerId, 'user-1');
    expect(group.memberIds, ['user-1', 'user-2']);
  });

  test('parses a group message without a direct receiver', () {
    final message = Message.fromJson({
      'id': 'message-1',
      'senderId': 'user-2',
      'groupId': 'group-1',
      'text': 'See you there',
      'createdAt': '2026-07-30T12:30:00.000Z',
    });

    expect(message.groupId, 'group-1');
    expect(message.receiverId, isNull);
    expect(message.text, 'See you there');
  });
}
