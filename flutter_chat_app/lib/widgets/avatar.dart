import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.online = false,
    this.showPresence = false,
    this.radius = 22,
  });

  final String name;
  final bool online;
  final bool showPresence;
  final double radius;

  String get _initial {
    final value = name.trim();
    return value.isEmpty ? '?' : value.characters.first.toUpperCase();
  }

  Color _backgroundColor() {
    const colors = [
      Color(0xFF5957D5),
      Color(0xFF00897B),
      Color(0xFFE07A5F),
      Color(0xFF3D7EA6),
      Color(0xFF9C5CA8),
    ];
    final code = name.isEmpty ? 0 : name.codeUnitAt(0);
    return colors[code % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: radius * 2,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: _backgroundColor(),
            child: Text(
              _initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showPresence)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.55,
                height: radius * 0.55,
                decoration: BoxDecoration(
                  color: online
                      ? const Color(0xFF33B679)
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
