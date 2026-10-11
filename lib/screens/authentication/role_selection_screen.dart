import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';

/// Screen presented to users registering / authenticating for the first time
/// (e.g., via Google OAuth 2.0) to select their primary platform role:
/// Renter, Gear Owner, Commercial Shop, or Administrator.
class RoleSelectionScreen extends StatefulWidget {
  final User? user;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final UserRole? initialRole;
  final ValueChanged<UserRole>? onRoleSelected;
  final AuthService? authService;

  const RoleSelectionScreen({
    super.key,
    this.user,
    this.displayName,
    this.email,
    this.photoUrl,
    this.initialRole,
    this.onRoleSelected,
    this.authService,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late UserRole _selectedRole;
  AuthService get _authService => widget.authService ?? AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? UserRole.renter;
  }

  Future<void> _handleConfirmRole() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.user != null) {
        await _authService.completeRegistration(
          user: widget.user!,
          role: _selectedRole,
        );
      }

      if (mounted && widget.onRoleSelected != null) {
        widget.onRoleSelected!(_selectedRole);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getAuthErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Switch Account?'),
        content: const Text(
          'Do you want to sign out and choose a different Google account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AuthService.getAuthErrorMessage(e)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String tag,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
  }) {
    final isSelected = _selectedRole == role;

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title role: $description',
      child: InkWell(
        onTap: _isLoading
            ? null
            : () {
                setState(() {
                  _selectedRole = role;
                  _errorMessage = null;
                });
              },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: isDark ? 0.18 : 0.08)
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : accentColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isSelected ? Colors.white : accentColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accentColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = widget.displayName ??
        (widget.user?.displayName?.trim().isNotEmpty == true
            ? widget.user!.displayName!.trim()
            : 'Welcome to GearGo');
    final email = widget.email ?? widget.user?.email ?? '';
    final photoUrl = widget.photoUrl ?? widget.user?.photoURL;

    final initials = displayName.isNotEmpty && displayName != 'Welcome to GearGo'
        ? displayName[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'G');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _handleSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User identity & Google OAuth badge
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.g_mobiledata_rounded,
                              color: AppColors.googleRed,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),

                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'First time here! Choose how you want to interact with GearGo to set up your workspace.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.deepNavy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 1. Renter
                  _buildRoleCard(
                    role: UserRole.renter,
                    title: 'Renter',
                    tag: 'Rent Equipment',
                    subtitle: 'Borrow sports gear, cameras, & vehicles',
                    description:
                        'Browse verified listings from owners & shops, book with flexible dates, instant security deposit protection, and pickup easily.',
                    icon: Icons.sports_rounded,
                    accentColor: AppColors.primary,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  // 2. Gear Owner
                  _buildRoleCard(
                    role: UserRole.owner,
                    title: 'Gear Owner',
                    tag: 'Lend & Earn',
                    subtitle: 'List your equipment & earn passive income',
                    description:
                        'Monetize outdoor and recreational equipment. Control calendar availability, customize rental rates, and safely lend to verified users.',
                    icon: Icons.storefront_rounded,
                    accentColor: AppColors.orange,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  // 3. Commercial Shop
                  _buildRoleCard(
                    role: UserRole.commercialShop,
                    title: 'Commercial Shop',
                    tag: 'Fleet & Inventory',
                    subtitle: 'Manage commercial rental operations',
                    description:
                        'Designed for gear rental stores and rental businesses. Bulk inventory catalog, commercial insurance coverage, and fleet logistics.',
                    icon: Icons.warehouse_outlined,
                    accentColor: const Color(0xFF6366F1),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  // 4. Administrator
                  _buildRoleCard(
                    role: UserRole.admin,
                    title: 'Administrator',
                    tag: 'Platform Ops',
                    subtitle: 'Marketplace supervision & governance',
                    description:
                        'Supervisory tools for reviewing seller identities, resolving member rental disputes, auditing equipment listings, and releasing holds.',
                    icon: Icons.admin_panel_settings_outlined,
                    accentColor: const Color(0xFF123B5D),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // Confirm button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleConfirmRole,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Continue as ${_selectedRole.displayName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
