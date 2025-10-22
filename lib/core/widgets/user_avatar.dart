import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.displayName,
    this.photoUrl,
    this.radius = 18,
    this.onTap,
  });

  final String? displayName;
  final String? photoUrl;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedPhoto = photoUrl?.trim();
    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.primaryContainer;
    final foregroundColor = theme.colorScheme.onPrimaryContainer;

    Widget avatar;
    if (resolvedPhoto != null && resolvedPhoto.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(resolvedPhoto),
        backgroundColor: Colors.transparent,
      );
    } else {
      final initial = _initial(displayName);
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: Text(
          initial,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: radius,
          ),
        ),
      );
    }

    if (onTap == null) {
      return avatar;
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: avatar,
    );
  }

  String _initial(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'C';
    }
    final trimmed = name.trim();
    final rune = trimmed.runes.first;
    return String.fromCharCode(rune).toUpperCase();
  }
}
