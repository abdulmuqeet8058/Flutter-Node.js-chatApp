import 'package:flutter/material.dart';

class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.name, this.size = 46});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        Icons.groups_rounded,
        color: colors.onSecondaryContainer,
        size: size * 0.52,
      ),
    );
  }
}
