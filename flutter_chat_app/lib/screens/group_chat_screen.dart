import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/group.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/date_label.dart';
import '../widgets/group_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key, required this.group});

  final Group group;

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _scrollController = ScrollController();
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadGroupMessages(widget.group.id);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  bool _startsNewDay(List<Message> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].sentAt;
    final previous = messages[index - 1].sentAt;
    return current.year != previous.year ||
        current.month != previous.month ||
        current.day != previous.day;
  }

  void _showMembers(ChatProvider chat) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                '${widget.group.memberIds.length} members',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final memberId in widget.group.memberIds)
              ListTile(
                leading: Avatar(
                  name: chat.usernameFor(memberId),
                  online: chat.isOnline(memberId),
                  showPresence: true,
                  radius: 20,
                ),
                title: Text(chat.usernameFor(memberId)),
                subtitle: Text(chat.isOnline(memberId) ? 'Online' : 'Offline'),
                trailing: memberId == widget.group.ownerId
                    ? const Chip(label: Text('Owner'))
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final messages = chat.messagesForGroup(widget.group.id);
    final onlineCount = chat.onlineMembers(widget.group);

    if (_messageCount != messages.length) {
      _messageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            GroupAvatar(name: widget.group.name, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$onlineCount online · ${widget.group.memberIds.length} members',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Group members',
            onPressed: () => _showMembers(chat),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!chat.connected)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(
                'Realtime connection lost. Messages will use the network fallback.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? _EmptyGroup(groupName: widget.group.name)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final mine = message.isMine(chat.myUserId);

                      return Column(
                        children: [
                          if (_startsNewDay(messages, index))
                            DateLabel(date: message.sentAt),
                          MessageBubble(
                            message: message,
                            isMine: mine,
                            senderName: mine
                                ? null
                                : chat.usernameFor(message.senderId),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          MessageInput(
            onSend: (text) {
              context.read<ChatProvider>().sendGroupMessage(
                widget.group.id,
                text,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyGroup extends StatelessWidget {
  const _EmptyGroup({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GroupAvatar(name: groupName, size: 68),
            const SizedBox(height: 16),
            Text(
              'Start the $groupName conversation',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Messages sent here are shared with every group member.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
