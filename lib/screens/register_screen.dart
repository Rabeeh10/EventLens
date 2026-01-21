import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// User registration screen for creating new accounts.
/// 
/// Collects email, password, and confirmation with validation.
/// Creates Firebase Authentication account on successful submission.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates email format using regex pattern
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  /// Validates password meets security requirements
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    // Optional: Add stronger password requirements
    // if (!value.contains(RegExp(r'[A-Z]'))) {
    //   return 'Password must contain an uppercase letter';
    // }
    
    return null;
  }

  /// Validates password confirmation matches
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Creates new user account with Firebase Authentication
  Future<void> _handleRegister() async {
    // Validate form inputs
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
// Use auth service instead of direct Firebase calls
    final result = await _authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Navigate back to login
        Navigator.of(context).pop();
      } else {
        // Show error message from service
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Registration failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              Theme.of(context).colorScheme.primary.withOpacity(0.6),
              Theme.of(context).colorScheme.tertiary.withOpacity(0.4),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 600 ? 500.0 : constraints.maxWidth * 0.9;
              
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Card(
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Register header with animated icon
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.elasticOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person_add_rounded,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 32),
                                
                                Text(
                                  'Join EventLens',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                
                                Text(
                                  'Create your account to discover events',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: _validateEmail,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.secondary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  validator: _validatePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.secondary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                // Confirm password field
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  validator: _validateConfirmPassword,
                                  onFieldSubmitted: (_) => _handleRegister(),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    hintText: 'Re-enter your password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.secondary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                
                                // Register button
                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      elevation: _isLoading ? 0 : 4,
                                      shadowColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                // Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'or',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                
                                // Login link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.secondary,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
