import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';

/// Admin dashboard screen for EventLens administrators.
/// 
/// Provides administrative controls for:
/// - Event management (create, edit, delete all events)
/// - Stall management (vendor booths, exhibitor spaces)
/// - Media upload (event images, promotional content)
/// 
/// Access restricted to users with role: 'admin'
/// Isolated from regular user flow for security and UX optimization.
/// 
/// **Security Implementation:**
/// - Route-level authorization check on widget initialization
/// - Verifies current user has 'admin' role in Firestore
/// - Redirects unauthorized users with error message
/// 
/// **Defense in Depth:**
/// This UI-level check is ONE layer of security. Complete protection requires:
/// 1. UI Route Guards (implemented here) - prevents accidental access
/// 2. Backend API Validation - validates admin role before any operation
/// 3. Firestore Security Rules - ultimate enforcement at database level
/// 
/// **Why UI Checks Are Insufficient:**
/// - Client-side code can be bypassed/modified by determined attackers
/// - Users can directly call Firebase APIs from browser console
/// - Mobile apps can be decompiled and reverse-engineered
/// - UI checks provide UX convenience, NOT security
/// 
/// **Required Firestore Rules Example:**
/// ```
/// match /events/{eventId} {
///   allow write: if request.auth != null && 
///                get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
/// }
/// ```
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  bool _isCheckingAuth = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }

  /// Verifies the current user has admin role.
  /// 
  /// This is a route guard that checks authorization before rendering
  /// admin content. Unauthorized users are redirected to HomeScreen.
  Future<void> _verifyAdminAccess() async {
    final isAdmin = await _authService.isAdmin();
    
    if (!mounted) return;
    
    if (!isAdmin) {
      // User is not an admin - show error and redirect
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '⚠️ Unauthorized Access: Admin privileges required',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Redirect to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
      return;
    }
    
    // User is authorized
    setState(() {
      _isAuthorized = true;
      _isCheckingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while verifying authorization
    if (_isCheckingAuth) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // This should never render for unauthorized users due to redirect,
    // but we add a defensive check anyway
    if (!_isAuthorized) {
      return const Scaffold(
        body: Center(
          child: Text('Unauthorized'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
            
            return Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Admin header
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          'Admin Dashboard',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        
                        Text(
                          'Manage platform content and configuration',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        
                        // Admin action cards
                        _AdminActionCard(
                          icon: Icons.event,
                          title: 'Manage Events',
                          subtitle: 'Create, edit, and delete events across the platform',
                          color: Colors.blue,
                          onTap: () {
                            // TODO: Navigate to event management screen
                            _showComingSoon(context, 'Event Management');
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _AdminActionCard(
                          icon: Icons.store,
                          title: 'Manage Stalls',
                          subtitle: 'Configure vendor booths and exhibitor spaces',
                          color: Colors.orange,
                          onTap: () {
                            // TODO: Navigate to stall management screen
                            _showComingSoon(context, 'Stall Management');
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _AdminActionCard(
                          icon: Icons.cloud_upload,
                          title: 'Upload Media',
                          subtitle: 'Upload event images, banners, and promotional content',
                          color: Colors.green,
                          onTap: () {
                            // TODO: Navigate to media upload screen
                            _showComingSoon(context, 'Media Upload');
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Quick access to user interface
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.home),
                          label: const Text('View User Interface'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Handles admin logout and navigates to home screen
  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    final result = await authService.logout();
    
    if (context.mounted) {
      if (result.success) {
        // Navigate to home screen after logout
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        // Show error if logout fails
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Logout failed'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Shows coming soon dialog for unimplemented features
  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature feature is under development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Reusable admin action card widget.
/// 
/// Displays icon, title, subtitle, and handles tap actions
/// for admin dashboard features.
class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              
              // Arrow indicator
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
