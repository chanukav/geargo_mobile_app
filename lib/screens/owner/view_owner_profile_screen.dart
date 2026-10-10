import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/owner_profile.dart';
import '../../services/owner_profile_service.dart';
import 'owner_profile_form_screen.dart';
import 'widgets/deactivate_profile_dialog.dart';
import 'widgets/profile_avatar_widget.dart';

/// READ screen: Displays a rich view of the owner's profile.
/// Provides quick access to Edit and Delete/Deactivate actions.
class ViewOwnerProfileScreen extends StatefulWidget {
  final String userId;
  final String? userEmail;

  const ViewOwnerProfileScreen({
    super.key,
    required this.userId,
    this.userEmail,
  });

  @override
  State<ViewOwnerProfileScreen> createState() => _ViewOwnerProfileScreenState();
}

class _ViewOwnerProfileScreenState extends State<ViewOwnerProfileScreen> {
  final _service = OwnerProfileService();
  bool _isProcessing = false;

  // ─── Navigation Helpers ────────────────────────────────────────────────────

  Future<void> _navigateToEdit(OwnerProfile profile) async {
    final updated = await Navigator.of(context).push<OwnerProfile>(
      MaterialPageRoute(
        builder: (_) => OwnerProfileFormScreen(
          userId: widget.userId,
          userEmail: widget.userEmail,
          profile: profile,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() {}); // stream will refresh
    }
  }

  Future<void> _navigateToCreate() async {
    final created = await Navigator.of(context).push<OwnerProfile>(
      MaterialPageRoute(
        builder: (_) => OwnerProfileFormScreen(
          userId: widget.userId,
          userEmail: widget.userEmail,
        ),
      ),
    );
    if (created != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _handleDeactivateOrDelete(OwnerProfile profile) async {
    final choice = await DeactivateProfileDialog.show(context, profile);
    if (choice == null || choice == DeactivateProfileChoice.cancel) return;

    setState(() => _isProcessing = true);
    try {
      if (choice == DeactivateProfileChoice.deactivate) {
        await _service.deactivateProfile(profile.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Profile deactivated. You can reactivate it anytime.',
              ),
              backgroundColor: AppColors.warning,
            ),
          );
          setState(() {});
        }
      } else if (choice == DeactivateProfileChoice.delete) {
        await _service.deleteProfile(profile.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile permanently deleted.'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.of(context).pop(true); // signal upstream
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReactivate(OwnerProfile profile) async {
    setState(() => _isProcessing = true);
    try {
      await _service.reactivateProfile(profile.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile reactivated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {});
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: StreamBuilder<OwnerProfile?>(
        stream: _service.profileStream(widget.userId),
        builder: (context, snapshot) {
          final profile = snapshot.data;

          return CustomScrollView(
            slivers: [
              // ── SliverAppBar Header ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.deepNavy,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.deepNavy,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  if (profile != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'Edit profile',
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.blue,
                        ),
                        onPressed:
                            _isProcessing ? null : () => _navigateToEdit(profile),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroHeader(profile),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: snapshot.connectionState == ConnectionState.waiting &&
                        profile == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                            color: AppColors.blue,
                          ),
                        ),
                      )
                    : profile == null
                        ? _buildEmptyState()
                        : _buildProfileBody(profile),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(OwnerProfile? profile) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepNavy, Color(0xFF1A5080)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 48), // below appbar buttons
            ProfileAvatarWidget(
              profile: profile,
              radius: 44,
              showEditBadge: false,
            ),
            const SizedBox(height: 10),
            Text(
              profile?.name.isNotEmpty == true
                  ? profile!.name
                  : 'Your Profile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (profile?.businessName.isNotEmpty == true)
              Text(
                profile!.businessName,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB8D4F0),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.orange,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Profile Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your owner profile so renters can learn about you and your gear.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _navigateToCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Profile'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBody(OwnerProfile profile) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status Banner ──────────────────────────────────────────────
          if (!profile.isActive)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    color: AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Profile Deactivated — not visible to renters.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleReactivate(profile),
                    child: const Text(
                      'Reactivate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Completeness Prompt ────────────────────────────────────────
          if (!profile.isComplete && profile.isActive)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Complete your profile to build trust with renters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _navigateToEdit(profile),
                    child: const Text('Complete'),
                  ),
                ],
              ),
            ),

          // ── Personal Info Card ─────────────────────────────────────────
          _infoCard(
            title: 'Personal Information',
            icon: Icons.person_outline_rounded,
            children: [
              _infoRow(Icons.badge_outlined, 'Name',
                  profile.name.isNotEmpty ? profile.name : '—'),
              _infoRow(Icons.email_outlined, 'Email',
                  widget.userEmail ?? '—'),
              _infoRow(Icons.phone_outlined, 'Phone',
                  profile.phone.isNotEmpty ? profile.phone : '—'),
              _infoRow(Icons.location_on_outlined, 'Address',
                  profile.address.isNotEmpty ? profile.address : '—'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Business Details Card ──────────────────────────────────────
          _infoCard(
            title: 'Business Details',
            icon: Icons.storefront_outlined,
            children: [
              _infoRow(
                Icons.business_outlined,
                'Business Name',
                profile.businessName.isNotEmpty ? profile.businessName : '—',
              ),
              _infoRow(
                Icons.language_outlined,
                'Website',
                profile.website.isNotEmpty ? profile.website : '—',
              ),
              if (profile.bio.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.bio,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.deepNavy,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Account Metadata Card ──────────────────────────────────────
          _infoCard(
            title: 'Account Information',
            icon: Icons.manage_accounts_outlined,
            children: [
              _infoRow(Icons.fingerprint_rounded, 'User ID', profile.userId),
              _infoRow(
                Icons.verified_outlined,
                'Verified',
                profile.isVerified ? 'Yes — GearGo Verified' : 'Not verified',
                valueColor:
                    profile.isVerified ? AppColors.success : AppColors.textSecondaryLight,
              ),
              _infoRow(
                Icons.radio_button_checked_rounded,
                'Status',
                profile.isActive ? 'Active' : 'Deactivated',
                valueColor:
                    profile.isActive ? AppColors.success : AppColors.error,
              ),
              _infoRow(
                Icons.calendar_today_outlined,
                'Member Since',
                dateFormat.format(profile.createdAt),
              ),
              _infoRow(
                Icons.update_rounded,
                'Last Updated',
                dateFormat.format(profile.updatedAt),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Action Buttons ─────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _isProcessing ? null : () => _navigateToEdit(profile),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Edit Profile'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _handleDeactivateOrDelete(profile),
            icon: const Icon(Icons.person_off_outlined, size: 18),
            label: const Text('Deactivate / Delete Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.blue),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMutedLight),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.deepNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
