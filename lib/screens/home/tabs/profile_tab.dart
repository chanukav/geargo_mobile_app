import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../services/app_settings_service.dart';
import '../widgets/account_details_card.dart';
import '../widgets/appearance_language_sheet.dart';
import '../../renter/rental_requests_list_screen.dart';
import '../../renter/saved_equipment_screen.dart';
import '../../../member4/hub_screen.dart';
import '../../../member4/repository.dart';
import '../../../member4/widgets.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : kNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium Profile Management Screen matching the Roamly / GearGo design,
/// equipped with multi-language support (English, Sinhala, Tamil) and
/// theme switching (Light / Dark / Auto).
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final titleColor = isDark ? AppColors.textPrimaryDark : kNavy;
    final settings = AppSettingsService.instance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                settings.tr('personal_info'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                settings.tr('personal_info_sub'),
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                child: Text(settings.tr('close')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    final settings = AppSettingsService.instance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: AppColors.secondary),
            const SizedBox(width: 10),
            Text(settings.tr('help_adventure_title'),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text(
          settings.tr('help_adventure_sub'),
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(settings.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(settings.tr('contact_support')),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: Text(settings.tr('get_help')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final appUser = AppUser.fromFirebase(widget.user);
        final displayName = appUser.displayName?.trim().isNotEmpty == true
            ? appUser.displayName!
            : 'Maya Chen';
        final userInitials = appUser.initials;

        final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
        final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
        final titleColor = isDark ? AppColors.textPrimaryDark : kNavy;
        final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // 1. Top Header Bar
              _buildTopBar(settings, isDark, titleColor, borderColor),
              const SizedBox(height: 18),

              // 2. Main Profile Hero Card (Cover + Avatar + Stats)
              _buildHeroCard(
                settings: settings,
                name: displayName,
                initials: userInitials,
                photoUrl: appUser.photoUrl,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                titleColor: titleColor,
                subColor: subColor,
              ),
              const SizedBox(height: 18),

              // 3. Profile Readiness Progress Card
              _buildReadinessCard(settings),
              const SizedBox(height: 22),

              // 4. Appearance & Language Section (Theme + Sinhala / Tamil / English)
              _buildAppearanceAndLanguageCard(
                settings: settings,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                titleColor: titleColor,
                subColor: subColor,
              ),
              const SizedBox(height: 22),

              // 5. Account & Trust Section
              _buildSectionHeader(
                title: settings.tr('account_trust'),
                actionText: settings.tr('manage'),
                titleColor: titleColor,
                onAction: _showPersonalInformationSheet,
              ),
              const SizedBox(height: 10),
              _buildCard(
                cardBg: cardBg,
                borderColor: borderColor,
                isDark: isDark,
                children: [
                  _buildListTile(
                    icon: Icons.person_outline_rounded,
                    title: settings.tr('personal_info'),
                    subtitle: settings.tr('personal_info_sub'),
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: subColor,
                    ),
                    onTap: _showPersonalInformationSheet,
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildListTile(
                    icon: Icons.verified_user_outlined,
                    title: settings.tr('identity_verification'),
                    subtitle: settings.tr('identity_verification_sub'),
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    trailing: _buildBadge(
                      text: settings.tr('verified'),
                      textColor: const Color(0xFF137333),
                      bgColor: const Color(0xFFE6F4EA),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(settings.tr('identity_verification_sub')),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Renter Activity & Bookings Section
              _buildSectionHeader(
                title: 'Renter Activity & Gear',
                titleColor: titleColor,
              ),
              const SizedBox(height: 10),
              _buildCard(
                cardBg: cardBg,
                borderColor: borderColor,
                isDark: isDark,
                children: [
                  _buildListTile(
                    icon: Icons.calendar_month_rounded,
                    title: 'My Rental Requests',
                    subtitle: 'Track reservations, reschedule dates & cancellations',
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RentalRequestsListScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildListTile(
                    icon: Icons.favorite_rounded,
                    title: 'Saved / Favourite Equipment',
                    subtitle: 'Wishlist collections, personal memos & quick rent',
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                         MaterialPageRoute(
                          builder: (_) => const SavedEquipmentScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildListTile(
                    icon: Icons.sports_outlined,
                    title: 'Equipment Handovers & Messages',
                    subtitle: 'Coordinate sports gear pickup, condition checks and returns',
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => openMember4(
                      context,
                      Member4Hub(repo: FirebaseMember4Repository()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 6. Payments Section
              _buildSectionHeader(
                title: settings.tr('payments'),
                actionText: settings.tr('add_new'),
                titleColor: titleColor,
                onAction: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(settings.tr('payments'))),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildCard(
                cardBg: cardBg,
                borderColor: borderColor,
                isDark: isDark,
                children: [
                  _buildListTile(
                    icon: Icons.credit_card_rounded,
                    title: 'Visa •••• 4821',
                    subtitle: settings.tr('default_payment_sub'),
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    trailing: _buildBadge(
                      text: settings.tr('default_badge'),
                      textColor: const Color(0xFF137333),
                      bgColor: const Color(0xFFE6F4EA),
                    ),
                    onTap: () {},
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildListTile(
                    icon: Icons.account_balance_outlined,
                    title: settings.tr('payout_account'),
                    subtitle: 'Coast Capital •••• 0916',
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: subColor,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 7. Rental Preferences Section
              _buildSectionHeader(
                title: settings.tr('rental_preferences'),
                actionText: settings.tr('edit'),
                titleColor: titleColor,
                onAction: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(settings.tr('rental_preferences'))),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildRentalPreferencesCard(
                settings: settings,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                titleColor: titleColor,
                subColor: subColor,
              ),
              const SizedBox(height: 22),

              // 8. Notifications Section
              _buildSectionHeader(
                title: settings.tr('notifications'),
                titleColor: titleColor,
              ),
              const SizedBox(height: 10),
              _buildCard(
                cardBg: cardBg,
                borderColor: borderColor,
                isDark: isDark,
                children: [
                  _buildSwitchTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: settings.tr('booking_updates'),
                    subtitle: settings.tr('booking_updates_sub'),
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    value: _bookingUpdates,
                    onChanged: (v) => setState(() => _bookingUpdates = v),
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildSwitchTile(
                    icon: Icons.local_offer_outlined,
                    title: settings.tr('offers_near_you'),
                    subtitle: settings.tr('offers_near_you_sub'),
                    titleColor: titleColor,
                    subColor: subColor,
                    isDark: isDark,
                    value: _offersNearYou,
                    onChanged: (v) => setState(() => _offersNearYou = v),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 9. Help for Every Adventure Banner
              _buildHelpBanner(settings),
              const SizedBox(height: 24),

              // 10. Sign Out Button
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: widget.onSignOut,
                  icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                  label: Text(
                    settings.tr('sign_out'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF5B2121) : const Color(0xFFF9D2D2),
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 11. Footer Info
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
      },
    );
  }

  // --- UI Components ---

  Widget _buildTopBar(
    AppSettingsService settings,
    bool isDark,
    Color titleColor,
    Color borderColor,
  ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : kNavy,
            borderRadius: BorderRadius.circular(12),
            border: isDark ? Border.all(color: borderColor) : null,
          ),
          child: const Icon(
            Icons.landscape_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GEARGO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.primary,
              ),
            ),
            Text(
              settings.tr('your_profile'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: titleColor,
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
          isDark: isDark,
          borderColor: borderColor,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(settings.tr('notifications'))),
            );
          },
        ),
        const SizedBox(width: 10),
        // Settings button opens Appearance & Language sheet
        _buildCircularIconButton(
          icon: Icons.settings_outlined,
          isDark: isDark,
          borderColor: borderColor,
          onTap: () => AppearanceLanguageSheet.show(context),
        ),
      ],
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    bool showBadge = false,
    required bool isDark,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.textPrimaryDark : kNavy,
            ),
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

  Widget _buildHeroCard({
    required AppSettingsService settings,
    required String name,
    required String initials,
    required String? photoUrl,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        settings.tr('trail_member'),
                        style: const TextStyle(
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
                          border: Border.all(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            width: 3.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                        color: titleColor,
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
                              Text(
                                'Vancouver, BC · ${settings.tr('member_since')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subColor,
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
                              color: AppColors.primary.withValues(alpha: 0.12),
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
                      color: isDark ? const Color(0xFF0F172A) : kBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        _buildStatColumn(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFFFB400),
                          title: '4.9',
                          subtitle: '32 ${settings.tr('reviews')}',
                          titleColor: titleColor,
                          subColor: subColor,
                        ),
                        _buildStatDivider(borderColor),
                        _buildStatColumn(
                          icon: Icons.verified_outlined,
                          iconColor: AppColors.primary,
                          title: settings.tr('verified'),
                          subtitle: settings.tr('trusted_renter'),
                          titleColor: titleColor,
                          subColor: subColor,
                        ),
                        _buildStatDivider(borderColor),
                        _buildStatColumn(
                          icon: Icons.hiking_rounded,
                          iconColor: const Color(0xFF0284C7),
                          title: '18',
                          subtitle: settings.tr('trips_completed'),
                          titleColor: titleColor,
                          subColor: subColor,
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
    required Color titleColor,
    required Color subColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: subColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(Color borderColor) {
    return Container(
      width: 1,
      height: 28,
      color: borderColor,
    );
  }

  Widget _buildReadinessCard(AppSettingsService settings) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  settings.tr('profile_ready_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
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
          Text(
            settings.tr('profile_ready_sub'),
            style: const TextStyle(
              color: Color(0xFFB0C4DE),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.85,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  /// Interactive Appearance & Language Card directly accessible on Profile
  Widget _buildAppearanceAndLanguageCard({
    required AppSettingsService settings,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
  }) {
    final currentTheme = settings.themeMode;
    final currentLang = settings.languageCode;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.palette_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.tr('preferences_display'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    Text(
                      'Dark Mode & Language selector',
                      style: TextStyle(fontSize: 11.5, color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Theme Mode Segmented Controller
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                settings.tr('theme_mode'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                _buildThemeTab(
                  label: settings.tr('theme_light'),
                  icon: Icons.wb_sunny_rounded,
                  selected: currentTheme == ThemeMode.light,
                  isDark: isDark,
                  onTap: () => settings.setThemeMode(ThemeMode.light),
                ),
                _buildThemeTab(
                  label: settings.tr('theme_dark'),
                  icon: Icons.dark_mode_rounded,
                  selected: currentTheme == ThemeMode.dark,
                  isDark: isDark,
                  onTap: () => settings.setThemeMode(ThemeMode.dark),
                ),
                _buildThemeTab(
                  label: settings.tr('theme_system'),
                  icon: Icons.brightness_auto_rounded,
                  selected: currentTheme == ThemeMode.system,
                  isDark: isDark,
                  onTap: () => settings.setThemeMode(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 16),

          // 2. Language Selector Pills (English / Sinhala / Tamil)
          Text(
            settings.tr('language'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildLanguageTab(
                code: 'en',
                flag: '🇬🇧',
                name: 'English',
                selected: currentLang == 'en',
                isDark: isDark,
                borderColor: borderColor,
                onTap: () => settings.setLanguage('en'),
              ),
              const SizedBox(width: 8),
              _buildLanguageTab(
                code: 'si',
                flag: '🇱🇰',
                name: 'සිංහල',
                selected: currentLang == 'si',
                isDark: isDark,
                borderColor: borderColor,
                onTap: () => settings.setLanguage('si'),
              ),
              const SizedBox(width: 8),
              _buildLanguageTab(
                code: 'ta',
                flag: '🇱🇰',
                name: 'தமிழ்',
                selected: currentLang == 'ta',
                isDark: isDark,
                borderColor: borderColor,
                onTap: () => settings.setLanguage('ta'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTab({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.surfaceDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? AppColors.primary
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTab({
    required String code,
    required String flag,
    required String name,
    required bool selected,
    required bool isDark,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : borderColor,
              width: selected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 3),
              Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? AppColors.textPrimaryDark : kNavy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    required Color titleColor,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: titleColor,
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

  Widget _buildCard({
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
    required Color titleColor,
    required Color subColor,
    required bool isDark,
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
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: isDark ? Colors.white : kNavy),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: subColor,
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
    required Color titleColor,
    required Color subColor,
    required bool isDark,
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
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: isDark ? Colors.white : kNavy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: subColor,
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

  Widget _buildRentalPreferencesCard({
    required AppSettingsService settings,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color titleColor,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.tr('favorite_activities'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: subColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActivityChip(
                label: settings.tr('activity_hiking'),
                keyName: 'Hiking',
                icon: Icons.hiking_rounded,
                isDark: isDark,
              ),
              _buildActivityChip(
                label: settings.tr('activity_cycling'),
                keyName: 'Cycling',
                icon: Icons.directions_bike_rounded,
                isDark: isDark,
              ),
              _buildActivityChip(
                label: settings.tr('activity_camping'),
                keyName: 'Camping',
                icon: Icons.terrain_rounded,
                isDark: isDark,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: borderColor),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.tr('pickup_radius'),
                    style: TextStyle(
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '15 km',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    settings.tr('preferred_handover'),
                    style: TextStyle(
                      fontSize: 12,
                      color: subColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.tr('weekends'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
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

  Widget _buildActivityChip({
    required String label,
    required String keyName,
    required IconData icon,
    required bool isDark,
  }) {
    final selected = _selectedActivities.contains(keyName);
    return InkWell(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedActivities.remove(keyName);
          } else {
            _selectedActivities.add(keyName);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
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
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.textPrimaryDark : kNavy),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.primary
                    : (isDark ? AppColors.textPrimaryDark : kNavy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpBanner(AppSettingsService settings) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F243A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.tr('help_adventure_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  settings.tr('help_adventure_sub'),
                  style: const TextStyle(
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
            child: Text(
              settings.tr('get_help'),
              style: const TextStyle(
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
