import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GeargoHome extends StatelessWidget {
  const GeargoHome({
    required this.auth,
    required this.user,
    super.key,
  });

  final FirebaseAuth auth;
  final User user;

  Future<void> _signOut(BuildContext context) async {
    try {
      await auth.signOut();
    } on FirebaseAuthException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'Unable to sign out. Please try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geargo'),
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Signed in as ${user.email ?? 'your account'}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
