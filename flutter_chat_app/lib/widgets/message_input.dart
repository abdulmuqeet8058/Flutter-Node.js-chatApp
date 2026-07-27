import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({super.key, required this.onSend});

  final void Function(String text) onSend;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) setState(() => _canSend = canSend);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Write a message…',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              tooltip: 'Send',
              onPressed: _canSend ? _send : null,
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
