import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/social_sign_in_button.dart';

/// Sample production-grade Register UI for GearGo.
class RegisterScreen extends StatefulWidget {
  final VoidCallback onToggleView;

  const RegisterScreen({
    super.key,
    required this.onToggleView,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  UserRole _selectedRole = UserRole.renter;
  bool _isLoading = false;
  bool _isGuestLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
        role: _selectedRole,
      );
      // Once registered, Wrapper will automatically route to HomeScreen.
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

  Widget _personaTile({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final selected = _selectedRole == role;
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isGuestLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInAnonymously();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthService.getAuthErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGuestLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnyLoading = _isLoading || _isGuestLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/logo_full.jpg',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join GearGo to start renting and sharing sports gear.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _errorMessage = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Registration Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Persona / Account Role Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _personaTile(
                                      role: UserRole.renter,
                                      title: 'Renter',
                                      subtitle: 'Book gear',
                                      icon: Icons.sports_rounded,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _personaTile(
                                      role: UserRole.owner,
                                      title: 'Gear Owner',
                                      subtitle: 'List & lend',
                                      icon: Icons.storefront_rounded,
                                      color: AppColors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _personaTile(
                                      role: UserRole.commercialShop,
                                      title: 'Commercial Shop',
                                      subtitle: 'Batch inventory',
                                      icon: Icons.warehouse_outlined,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _personaTile(
                                      role: UserRole.admin,
                                      title: 'Administrator',
                                      subtitle: 'Platform ops',
                                      icon: Icons.admin_panel_settings_outlined,
                                      color: const Color(0xFF123B5D),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _nameController,
                          labelText: 'Full Name',
                          hintText: 'John Doe',
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: validateName,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'name@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Minimum 6 characters',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: validatePassword,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          hintText: 'Re-enter your password',
                          prefixIcon: Icons.lock_reset_rounded,
                          isPassword: true,
                          textInputAction: TextInputAction.done,
                          validator: (val) =>
                              validateConfirmPassword(val, _passwordController.text),
                          onFieldSubmitted: (_) =>
                              isAnyLoading ? null : _handleRegister(),
                        ),
                        const SizedBox(height: 24),

                        // Create Account Primary Button
                        ElevatedButton(
                          onPressed: isAnyLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Guest Sign-in Option
                  SocialSignInButton.guest(
                    onPressed: isAnyLoading ? null : _handleGuestSignIn,
                    isLoading: _isGuestLoading,
                  ),

                  const SizedBox(height: 28),

                  // Footer: Switch to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      GestureDetector(
                        onTap: isAnyLoading ? null : widget.onToggleView,
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
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
