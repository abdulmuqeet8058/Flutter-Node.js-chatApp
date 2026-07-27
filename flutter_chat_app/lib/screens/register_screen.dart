import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.error ?? 'Could not create your account.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthProvider>().busy;

    return AuthShell(
      title: 'Create your account',
      subtitle: 'Choose a name and start a conversation.',
      showBackButton: true,
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
                  return 'Choose a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _hidePassword,
              onFieldSubmitted: (_) => _register(),
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'Use at least 4 characters',
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
                if (value == null || value.length < 4) {
                  return 'Password must be at least 4 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: busy ? null : _register,
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
