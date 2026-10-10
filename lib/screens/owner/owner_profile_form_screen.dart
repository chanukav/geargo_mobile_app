import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_helper.dart';
import '../../models/owner_profile.dart';
import '../../services/owner_profile_service.dart';
import 'widgets/image_picker_sheet.dart';

/// Dual-mode form screen for creating or editing an owner profile (CRUD 02).
///
/// - Create mode  : no existing [profile] supplied.
/// - Edit / Update: supply the current [profile].
class OwnerProfileFormScreen extends StatefulWidget {
  final String userId;
  final String? userEmail;
  final OwnerProfile? profile; // null = Create mode

  const OwnerProfileFormScreen({
    super.key,
    required this.userId,
    this.userEmail,
    this.profile,
  });

  @override
  State<OwnerProfileFormScreen> createState() => _OwnerProfileFormScreenState();
}

class _OwnerProfileFormScreenState extends State<OwnerProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = OwnerProfileService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _businessCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _websiteCtrl;

  late String _profileImage;
  bool _isSaving = false;

  bool get _isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _businessCtrl = TextEditingController(text: p?.businessName ?? '');
    _bioCtrl = TextEditingController(text: p?.bio ?? '');
    _websiteCtrl = TextEditingController(text: p?.website ?? '');
    _profileImage = p?.profileImage ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _businessCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _openImagePicker() {
    ImagePickerSheet.show(
      context,
      onImageSelected: (img) => setState(() => _profileImage = img),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final draft = OwnerProfile(
        id: widget.profile?.id ?? widget.userId,
        userId: widget.userId,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        profileImage: _profileImage.trim(),
        businessName: _businessCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        isVerified: widget.profile?.isVerified ?? false,
        isActive: widget.profile?.isActive ?? true,
        createdAt: widget.profile?.createdAt ?? now,
        updatedAt: now,
      );

      final saved = _isEditing
          ? await _service.updateProfile(draft)
          : await _service.createProfile(draft);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Profile updated successfully!'
                  : 'Owner profile created!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Profile' : 'Create Profile',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Profile Photo Picker ──────────────────────────────────
                _buildPhotoSection(),
                const SizedBox(height: 24),

                // ── Personal Info Section ─────────────────────────────────
                _sectionHeader(
                  icon: Icons.person_outline_rounded,
                  label: 'Personal Information',
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _nameCtrl,
                  label: 'Full Name *',
                  hint: 'e.g. Alex Johnson',
                  icon: Icons.badge_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (v.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _phoneCtrl,
                  label: 'Phone Number',
                  hint: 'e.g. +1 (303) 555-0192',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _addressCtrl,
                  label: 'Address',
                  hint: 'e.g. 123 Main St, Denver, CO 80202',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // ── Business Details Section ──────────────────────────────
                _sectionHeader(
                  icon: Icons.storefront_outlined,
                  label: 'Business Details',
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _businessCtrl,
                  label: 'Business / Shop Name',
                  hint: 'e.g. Peak Gear Rentals',
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _websiteCtrl,
                  label: 'Website',
                  hint: 'e.g. https://peakgearrentals.com',
                  icon: Icons.language_outlined,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _bioCtrl,
                  label: 'About / Bio',
                  hint:
                      'Tell renters about your gear, specialisations, or service area...',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 28),

                // ── Save CTA ─────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : (_isEditing ? 'Save Changes' : 'Create Profile'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Section Widgets ───────────────────────────────────────────────────────

  Widget _buildPhotoSection() {
    final hasImage = _profileImage.trim().isNotEmpty;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar circle / image preview
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: hasImage
                      ? EquipmentImageViewer(
                          imageSource: _profileImage,
                          width: 110,
                          height: 110,
                          fallbackIcon: Icons.person_rounded,
                        )
                      : Container(
                          color: AppColors.blue.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.blue.withValues(alpha: 0.5),
                            size: 56,
                          ),
                        ),
                ),
              ),
              // Camera edit badge
              Positioned(
                right: 4,
                bottom: 4,
                child: GestureDetector(
                  onTap: _openImagePicker,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _openImagePicker,
            icon: const Icon(Icons.upload_rounded, size: 16),
            label: Text(hasImage ? 'Change Photo' : 'Upload Profile Photo'),
            style: TextButton.styleFrom(foregroundColor: AppColors.blue),
          ),
          if (hasImage)
            TextButton(
              onPressed: () => setState(() => _profileImage = ''),
              child: const Text(
                'Remove Photo',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader({required IconData icon, required String label}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.blue),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: AppColors.textSecondaryLight)
                : null,
          ),
        ),
      ],
    );
  }
}
