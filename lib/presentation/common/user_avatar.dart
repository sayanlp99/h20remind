import 'package:flutter/material.dart';

import '../../domain/models/app_user.dart';

/// Profile photo with an initials fallback.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 16});

  final AppUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final photoUrl = user.photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.tertiaryContainer,
      foregroundColor: colors.onTertiaryContainer,
      foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
      // Fall back to initials if the photo fails to load.
      onForegroundImageError: photoUrl == null ? null : (_, _) {},
      child: Text(
        user.initials,
        style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w500),
      ),
    );
  }
}
