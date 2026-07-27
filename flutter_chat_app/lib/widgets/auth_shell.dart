import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _DecorativeCircle(
                size: 220,
                color: colors.primaryContainer.withValues(alpha: 0.55),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -90,
              child: _DecorativeCircle(
                size: 250,
                color: colors.secondaryContainer.withValues(alpha: 0.4),
              ),
            ),
            if (showBackButton)
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.28),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.forum_rounded,
                          color: colors.onPrimary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Ping',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 28),
                              child,
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
