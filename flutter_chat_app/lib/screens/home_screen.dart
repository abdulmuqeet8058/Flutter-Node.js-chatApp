import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/avatar.dart';
import 'direct_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  StreamSubscription<String>? _errorSubscription;
  String _query = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();

      _errorSubscription = chat.errors.listen((message) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      });

      final token = auth.token;
      final user = auth.user;
      if (token != null && user != null) {
        chat.connect(token: token, myUserId: user.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _errorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out of Ping?'),
        content: const Text('You can sign back in at any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !mounted) return;
    context.read<ChatProvider>().reset();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final users = chat.users.where((user) {
      return user.username.toLowerCase().contains(_query.toLowerCase());
    }).toList();
    final onlineCount = chat.users
        .where((user) => chat.isOnline(user.id))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.forum_rounded,
                size: 21,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 11),
            const Text('Ping', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text('@${auth.user?.username ?? ''}'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 10),
                    Text('Log out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Avatar(
                name: auth.user?.username ?? '',
                radius: 18,
                online: chat.connected,
                showPresence: true,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: chat.loadUsers,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WelcomeCard(
                          username: auth.user?.username ?? '',
                          connected: chat.connected,
                          onlineCount: onlineCount,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Search people',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              'People',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Text(
                              '$onlineCount online',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (chat.loadingUsers && chat.users.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (users.isEmpty)
                          _EmptyPeople(searching: _query.isNotEmpty)
                        else
                          for (final user in users)
                            _PersonCard(
                              user: user,
                              online: chat.isOnline(user.id),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.username,
    required this.connected,
    required this.onlineCount,
  });

  final String username;
  final bool connected;
  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $username',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    onlineCount == 0
                        ? 'Start a conversation with someone below.'
                        : '$onlineCount ${onlineCount == 1 ? 'person is' : 'people are'} around right now.',
                    style: TextStyle(
                      color: colors.onPrimaryContainer.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: connected
                              ? const Color(0xFF238A62)
                              : colors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        connected ? 'Live and connected' : 'Reconnecting…',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.onPrimaryContainer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.waving_hand_rounded,
              size: 42,
              color: colors.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.user, required this.online});

  final User user;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Avatar(
          name: user.username,
          online: online,
          showPresence: true,
        ),
        title: Text(
          user.username,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(online ? 'Available now' : 'Offline'),
        trailing: IconButton.filledTonal(
          tooltip: 'Message ${user.username}',
          onPressed: () => _openChat(context),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
        ),
        onTap: () => _openChat(context),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DirectChatScreen(otherUser: user)),
    );
  }
}

class _EmptyPeople extends StatelessWidget {
  const _EmptyPeople({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(
            searching ? Icons.search_off_rounded : Icons.people_outline_rounded,
            size: 54,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 14),
          Text(
            searching ? 'No matching people' : 'No one else is here yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try a different username.'
                : 'Create another account to start your first conversation.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
