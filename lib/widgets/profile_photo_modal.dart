import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/supabase_config.dart';
import '../core/utils/image_helper.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

/// Interactive modal sheet to Read, Upload (Create), Update, and Delete
/// a user's profile image stored in Supabase Storage in the 'profile image' folder,
/// while persisting changes to the database.
class ProfilePhotoModal extends StatefulWidget {
  final AppUser user;
  final ValueChanged<AppUser>? onPhotoChanged;

  const ProfilePhotoModal({
    super.key,
    required this.user,
    this.onPhotoChanged,
  });

  static Future<AppUser?> show(
    BuildContext context, {
    required AppUser user,
    ValueChanged<AppUser>? onPhotoChanged,
  }) {
    return showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProfilePhotoModal(
        user: user,
        onPhotoChanged: onPhotoChanged,
      ),
    );
  }

  @override
  State<ProfilePhotoModal> createState() => _ProfilePhotoModalState();
}

class _ProfilePhotoModalState extends State<ProfilePhotoModal> {
  final UserService _userService = UserService();
  late AppUser _currentUser;
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  bool get _hasPhoto =>
      _currentUser.photoUrl != null &&
      _currentUser.photoUrl!.trim().isNotEmpty;

  Future<void> _handlePickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Uploading to Supabase Storage (${SupabaseConfig.profileImageFolder})...';
    });

    try {
      final bytes = await ImageHelper.pickImageBytes(source: source);
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage = null;
          });
        }
        return;
      }

      final updated = await _userService.updateProfilePhoto(
        userId: _currentUser.uid,
        bytes: bytes,
        currentUser: _currentUser,
      );

      if (mounted) {
        setState(() {
          _currentUser = updated;
          _isLoading = false;
          _statusMessage = null;
        });
        widget.onPhotoChanged?.call(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profile photo updated in Supabase Storage and saved to database!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeletePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Remove Profile Photo?'),
        content: const Text(
          'This will delete the image from Supabase Storage and clear your profile avatar in the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting from Supabase Storage...';
    });

    try {
      final updated = await _userService.deleteProfilePhoto(
        userId: _currentUser.uid,
        currentUser: _currentUser,
      );

      if (mounted) {
        setState(() {
          _currentUser = updated;
          _isLoading = false;
          _statusMessage = null;
        });
        widget.onPhotoChanged?.call(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Profile photo deleted from Supabase Storage and cleared in database.'),
            backgroundColor: AppColors.textSecondaryLight,
          ),
        );
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title & Persona Role Badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Image',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Persona: ${_currentUser.role.displayName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_done_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        SupabaseConfig.profileImageFolder,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile Image Preview (CRUD Read)
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _hasPhoto
                          ? EquipmentImageViewer(
                              imageSource: _currentUser.photoUrl!,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0),
                              alignment: Alignment.center,
                              child: Text(
                                _currentUser.initials,
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _statusMessage!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Action Buttons (Upload / Update / Delete)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _handlePickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _handlePickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, size: 18),
                    label: Text(_hasPhoto ? 'Update Photo' : 'Upload Photo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_hasPhoto) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _handleDeletePhoto,
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.error),
                  label: const Text(
                    'Delete Profile Photo',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
