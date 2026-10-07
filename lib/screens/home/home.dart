import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/app_settings_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/search_tab.dart';

/// Main shell for GearGo: bottom navigation with Home, Search, Bookings,
/// Messages and Profile tabs.
class HomeScreen extends StatefulWidget {
  final User user;
  final FirebaseAuth? auth;

  const HomeScreen({
    super.key,
    required this.user,
    this.auth,
  });

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
      const EmptyTab(
        icon: Icons.calendar_month_rounded,
        title: 'No bookings yet',
        subtitle: 'Rent gear from people near you and your bookings will show up here.',
      ),
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
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: List.generate(navItems.length, (i) {
                final sel = i == _index;
                final it = navItems[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
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
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backwards compatibility alias for [HomeScreen].
typedef GeargoHome = HomeScreen;
