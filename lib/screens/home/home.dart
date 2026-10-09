import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../member4/hub_screen.dart';
import '../../member4/repository.dart';
import '../../member4/widgets.dart';
import '../../models/app_user.dart';
import '../../services/app_settings_service.dart';
import '../../services/auth_service.dart';
import '../renter/rental_requests_list_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/search_tab.dart';
import 'widgets/account_details_card.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/user_profile_header.dart';


/// Main shell for GearGo: bottom navigation with Home, Search, Bookings,
/// Messages and Profile tabs.
class HomeScreen extends StatefulWidget {
  final User user;
  final FirebaseAuth? auth;

  const HomeScreen({super.key, required this.user, this.auth});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Future<void> _handleSignOut() async {
    final settings = AppSettingsService.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(settings.tr('sign_out_confirm_title')),
        content: Text(settings.tr('sign_out_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(settings.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(settings.tr('sign_out')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService().signOut();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AuthService.getAuthErrorMessage(error)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsService.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appUser = AppUser.fromFirebase(widget.user);
    final firstName = appUser.displayTitle.split(' ').first;

    final navItems = [
      (Icons.home_rounded, Icons.home_outlined, settings.tr('nav_home')),
      (Icons.search_rounded, Icons.search_rounded, settings.tr('nav_search')),
      (Icons.calendar_month_rounded, Icons.calendar_today_outlined, settings.tr('nav_bookings')),
      (Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, settings.tr('nav_messages')),
      (Icons.person_rounded, Icons.person_outline_rounded, settings.tr('nav_profile')),
    ];

    final tabs = <Widget>[
      HomeTab(name: firstName, onSearchTap: () => setState(() => _index = 1)),
      const SearchTab(),
      RentalRequestsListScreen(onExploreTap: () => setState(() => _index = 1)),
      const EmptyTab(
        icon: Icons.chat_bubble_rounded,
        title: 'No messages',
        subtitle: 'Chat with owners to arrange pickups once you book gear.',
      ),
      ProfileTab(user: widget.user, onSignOut: _handleSignOut),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey(_index), child: tabs[_index]),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 0.8,
            ),
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.sports_score_rounded),
              SizedBox(width: 10),
              Text('GearGo', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _handleSignOut(context),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UserProfileHeader(user: appUser),
                const SizedBox(height: 16),
                QuickActionCard(
                  title: 'Equipment Handovers & Messages',
                  subtitle: 'Coordinate sports gear pickup, condition checks and returns',
                  icon: Icons.sports_outlined,
                  iconColor: AppColors.primary,
                  onTap: () => openMember4(
                    context,
                    Member4Hub(repo: FirebaseMember4Repository()),
                  ),
                ),
                const SizedBox(height: 16),
                if (appUser.isAnonymous) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.warning,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Guest Account Active',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sign up or link an email account anytime to save your reservations and trip history permanently.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                AccountDetailsCard(user: user),
                const SizedBox(height: 20),

                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              sel ? it.$1 : it.$2,
                              size: 26,
                              color: sel
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            it.$3,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight:
                                  sel ? FontWeight.w800 : FontWeight.w500,
                              color: sel
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  'Explore GearGo Services',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                QuickActionCard(
                  title: 'Available Fleet',
                  subtitle: '18 vehicles ready for rental near your location',
                  icon: Icons.car_rental_rounded,
                  iconColor: AppColors.primary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fleet explorer: 18 vehicles nearby.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                QuickActionCard(
                  title: 'My Bookings',
                  subtitle: 'No active reservations. Plan your next drive!',
                  icon: Icons.calendar_month_rounded,
                  iconColor: AppColors.secondary,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You currently have no active bookings.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                QuickActionCard(
                  title: 'Roadside Assistance',
                  subtitle: '24/7 dedicated support & emergency recovery',
                  icon: Icons.support_agent_rounded,
                  iconColor: AppColors.success,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Roadside hotline: 1-800-GEARGO-HELP'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _handleSignOut(context),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

          ),
        ),
      ),
    );
  }
}

/// Backwards compatibility alias for [HomeScreen].
typedef GeargoHome = HomeScreen;
