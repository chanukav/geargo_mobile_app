import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

// Re-export validators for backward compatibility and test suite
export '../../core/utils/validators.dart' show validateEmail, validatePassword;

/// Authenticate controller widget that toggles between [LoginScreen] and [RegisterScreen].
class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  bool _showSignIn = true;

  void _toggleView() {
    setState(() {
      _showSignIn = !_showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showSignIn
          ? LoginScreen(
              key: const ValueKey('login_screen'),
              onToggleView: _toggleView,
            )
          : RegisterScreen(
              key: const ValueKey('register_screen'),
              onToggleView: _toggleView,
            ),
    );
  }
}
