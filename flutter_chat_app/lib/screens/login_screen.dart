import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not log in.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Sign in and pick up where you left off.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _hidePassword = !_hidePassword);
                  },
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: busy ? null : _login,
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log in'),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('New to Ping?'),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
