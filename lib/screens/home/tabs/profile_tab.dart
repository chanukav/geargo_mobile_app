import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/app_user.dart';
import '../widgets/account_details_card.dart';
import 'home_tab.dart';

/// Simple empty-state tab (Bookings / Messages).
class EmptyTab extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyTab({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Icon(icon, size: 52, color: AppColors.primary),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium Profile Management Screen matching the Roamly / GearGo design.
class ProfileTab extends StatefulWidget {
  final User user;
  final VoidCallback onSignOut;

  const ProfileTab({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _bookingUpdates = true;
  bool _offersNearYou = false;
  final Set<String> _selectedActivities = {'Hiking', 'Cycling', 'Camping'};

  void _showPersonalInformationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review your verified credentials and authentication settings.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 18),
              AccountDetailsCard(user: widget.user),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.support_agent_rounded, color: AppColors.secondary),
            SizedBox(width: 10),
            Text('GearGo Support', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Need assistance with gear handovers, safety guidelines, or deposit refunds? Our 24/7 adventure support team is here to help.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support agent contacted. We will respond in a few minutes.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications are up to date.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUser = AppUser.fromFirebase(widget.user);
    final displayName = appUser.displayName?.trim().isNotEmpty == true
        ? appUser.displayName!
        : 'Maya Chen';
    final userInitials = appUser.initials;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // 1. Top Header Bar
          _buildTopBar(),
          const SizedBox(height: 18),

          // 2. Main Profile Hero Card (Cover + Avatar + Stats)
          _buildHeroCard(displayName, userInitials, appUser.photoUrl),
          const SizedBox(height: 18),

          // 3. Profile Readiness Progress Card
          _buildReadinessCard(),
          const SizedBox(height: 22),

          // 4. Account & Trust Section
          _buildSectionHeader(
            title: 'Account & trust',
            actionText: 'Manage',
            onAction: _showPersonalInformationSheet,
          ),
          const SizedBox(height: 10),
          _buildCard(
            children: [
              _buildListTile(
                icon: Icons.person_outline_rounded,
                title: 'Personal information',
                subtitle: 'Name, email, phone and emergency contact',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryLight,
                ),
                onTap: _showPersonalInformationSheet,
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _buildListTile(
                icon: Icons.verified_user_outlined,
                title: 'Identity verification',
                subtitle: 'Government ID and selfie confirmed',
                trailing: _buildBadge(
                  text: 'Verified',
                  textColor: const Color(0xFF137333),
                  bgColor: const Color(0xFFE6F4EA),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Your identity has already been verified.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 5. Payments Section
          _buildSectionHeader(
            title: 'Payments',
            actionText: 'Add new',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add payment method sheet')),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildCard(
            children: [
              _buildListTile(
                icon: Icons.credit_card_rounded,
                title: 'Visa •••• 4821',
                subtitle: 'Default payment method · Expires 09/28',
                trailing: _buildBadge(
                  text: 'Default',
                  textColor: const Color(0xFF137333),
                  bgColor: const Color(0xFFE6F4EA),
                ),
                onTap: () {},
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _buildListTile(
                icon: Icons.account_balance_outlined,
                title: 'Payout account',
                subtitle: 'Coast Capital •••• 0916',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondaryLight,
                ),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 6. Rental Preferences Section
          _buildSectionHeader(
            title: 'Rental preferences',
            actionText: 'Edit',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit preferences dialog')),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildRentalPreferencesCard(),
          const SizedBox(height: 22),

          // 7. Notifications Section
          _buildSectionHeader(title: 'Notifications'),
          const SizedBox(height: 10),
          _buildCard(
            children: [
              _buildSwitchTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Booking updates',
                subtitle: 'Requests, handovers and returns',
                value: _bookingUpdates,
                onChanged: (v) => setState(() => _bookingUpdates = v),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              _buildSwitchTile(
                icon: Icons.local_offer_outlined,
                title: 'Offers near you',
                subtitle: 'Price drops and new local gear',
                value: _offersNearYou,
                onChanged: (v) => setState(() => _offersNearYou = v),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // 8. Help for Every Adventure Banner
          _buildHelpBanner(),
          const SizedBox(height: 24),

          // 9. Sign Out Button
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
              label: const Text(
                'Sign out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFF9D2D2), width: 1.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 1,
                shadowColor: Colors.black.withValues(alpha: 0.04),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 10. Footer Info
          const Center(
            child: Text(
              'GearGo 4.8.2 · Privacy · Terms',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMutedLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: kNavy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.landscape_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GEARGO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Your profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kNavy,
                height: 1.1,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Notification bell with badge dot
        _buildCircularIconButton(
          icon: Icons.notifications_none_rounded,
          showBadge: true,
          onTap: _showNotificationSettings,
        ),
        const SizedBox(width: 10),
        // Settings button
        _buildCircularIconButton(
          icon: Icons.settings_outlined,
          onTap: _showPersonalInformationSheet,
        ),
      ],
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    bool showBadge = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: kNavy),
            if (showBadge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(String name, String initials, String? photoUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Trail Member badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/profile_banner.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1E3A5F), Color(0xFF0F2A4A)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Trail member badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'TRAIL MEMBER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Avatar & User Info Row (Avatar overlapping banner)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: const Color(0xFFE2E8F0),
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name & Subtitle
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: kNavy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Vancouver, BC · Member since 2022',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Edit Button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: _showPersonalInformationSheet,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Row with 3 Columns
                Transform.translate(
                  offset: const Offset(0, -12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        _buildStatColumn(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFFB400),
                          title: '4.9',
                          subtitle: '32 reviews',
                        ),
                        _buildStatDivider(),
                        _buildStatColumn(
                          icon: Icons.verified_outlined,
                          iconColor: AppColors.primary,
                          title: 'Verified',
                          subtitle: 'Trusted renter',
                        ),
                        _buildStatDivider(),
                        _buildStatColumn(
                          icon: Icons.hiking_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: '18',
                          subtitle: 'Trips completed',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: kNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.borderLight,
    );
  }

  Widget _buildReadinessCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2A4A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2A4A).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your profile is almost trail-ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '85%',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Add an emergency contact to reach 100%',
            style: TextStyle(
              color: Color(0xFFB0C4DE),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.85,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: kNavy,
          ),
        ),
        if (actionText != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                actionText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: kNavy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: kNavy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRentalPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAVORITE ACTIVITIES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActivityChip('Hiking', Icons.hiking_rounded),
              _buildActivityChip('Cycling', Icons.directions_bike_rounded),
              _buildActivityChip('Camping', Icons.terrain_rounded),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.borderLight),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pickup radius',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '15 km',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Preferred handover',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Weekends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChip(String label, IconData icon) {
    final selected = _selectedActivities.contains(label);
    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedActivities.remove(label);
          } else {
            _selectedActivities.add(label);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : kNavy,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : kNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F243A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help for every adventure',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Safety guidance and support, whenever you need it.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _showHelpDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 36),
              elevation: 4,
              shadowColor: AppColors.secondary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Get help',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
