import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../widgets/avatar.dart';
import 'group_chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a group name.');
      return;
    }
    if (_selectedUserIds.isEmpty) {
      _showMessage('Choose at least one group member.');
      return;
    }

    setState(() => _submitting = true);
    final group = await context.read<ChatProvider>().createGroup(
      name,
      _selectedUserIds.toList(),
    );
    if (!mounted) return;

    setState(() => _submitting = false);
    if (group == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GroupChatScreen(group: group)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New group'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _submitting ? null : _createGroup,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                  child: TextField(
                    controller: _nameController,
                    maxLength: 80,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Group name',
                      hintText: 'Weekend plans',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Add people',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text('${_selectedUserIds.length} selected'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: chat.users.isEmpty
                      ? const Center(
                          child: Text('No other users are available yet.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: chat.users.length,
                          itemBuilder: (context, index) {
                            final user = chat.users[index];
                            final selected = _selectedUserIds.contains(user.id);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: CheckboxListTile(
                                value: selected,
                                secondary: Avatar(
                                  name: user.username,
                                  online: chat.isOnline(user.id),
                                  showPresence: true,
                                  radius: 20,
                                ),
                                title: Text(user.username),
                                subtitle: Text(
                                  chat.isOnline(user.id) ? 'Online' : 'Offline',
                                ),
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedUserIds.add(user.id);
                                    } else {
                                      _selectedUserIds.remove(user.id);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
