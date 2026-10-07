import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../member4/hub_screen.dart';
import '../../member4/repository.dart';
import '../../member4/widgets.dart';
import 'widgets/account_details_card.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/user_profile_header.dart';

/// Sample production-grade Home Screen for GearGo.
class HomeScreen extends StatelessWidget {
  final User user;
  final FirebaseAuth? auth;

  const HomeScreen({super.key, required this.user, this.auth});

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of GearGo?'),
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

    if (confirmed == true) {
      try {
        await AuthService().signOut();
      } catch (error) {
        if (context.mounted) {
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
    final appUser = AppUser.fromFirebase(user);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text('GearGo', style: TextStyle(fontWeight: FontWeight.bold)),
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
              // User Profile Banner
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

              // Guest Mode Notice if Anonymous
              if (appUser.isAnonymous) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
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
                const SizedBox(height: 16),
              ],

              // Authentication Metadata Card
              AccountDetailsCard(user: user),
              const SizedBox(height: 20),

              // GearGo Sample Quick Actions
              Text(
                'Explore GearGo Services',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
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

              // Primary Logout Button
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
    );
  }
}

/// Backwards compatibility alias for [HomeScreen].
typedef GeargoHome = HomeScreen;
