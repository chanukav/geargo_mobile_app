import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/image_helper.dart';
import '../../../models/owner_profile.dart';

/// Reusable avatar circle displaying owner photo or initials fallback.
class ProfileAvatarWidget extends StatelessWidget {
  final OwnerProfile? profile;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const ProfileAvatarWidget({
    super.key,
    required this.profile,
    this.radius = 44,
    this.onTap,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = profile?.profileImage.trim().isNotEmpty == true;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.blue.withValues(alpha: 0.15),
            child: ClipOval(
              child: hasImage
                  ? EquipmentImageViewer(
                      imageSource: profile!.profileImage,
                      width: radius * 2,
                      height: radius * 2,
                      fallbackIcon: Icons.person_rounded,
                    )
                  : _buildInitials(),
            ),
          ),
          if (showEditBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: radius * 0.65,
                height: radius * 0.65,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: radius * 0.32,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitials() {
    final initials = profile?.initials ?? '?';
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: AppColors.blue.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.55,
          fontWeight: FontWeight.bold,
          color: AppColors.blue,
        ),
      ),
    );
  }
}
