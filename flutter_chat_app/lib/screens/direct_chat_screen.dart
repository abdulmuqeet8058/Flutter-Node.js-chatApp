import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/message.dart';
import '../models/user.dart';
import '../providers/chat_provider.dart';
import '../widgets/avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({super.key, required this.otherUser});

  final User otherUser;

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _scrollController = ScrollController();
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.otherUser.id);
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

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final messages = chat.messagesWith(widget.otherUser.id);
    final online = chat.isOnline(widget.otherUser.id);

    if (_messageCount != messages.length) {
      _messageCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(
              name: widget.otherUser.username,
              online: online,
              showPresence: true,
              radius: 19,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.username,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  online ? 'Online now' : 'Offline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: online
                        ? const Color(0xFF238A62)
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                ? _EmptyConversation(username: widget.otherUser.username)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return Column(
                        children: [
                          if (_startsNewDay(messages, index))
                            _DateLabel(date: message.sentAt),
                          MessageBubble(
                            message: message,
                            isMine: message.isMine(chat.myUserId),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          MessageInput(
            onSend: (text) {
              context.read<ChatProvider>().sendMessage(
                widget.otherUser.id,
                text,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final value = DateTime(date.year, date.month, date.day);
    final label = value == today
        ? 'Today'
        : DateFormat('MMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(name: username, radius: 34),
            const SizedBox(height: 16),
            Text(
              'Start a chat with $username',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Send a message to begin the conversation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
