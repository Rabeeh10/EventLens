import 'package:flutter/material.dart';

/// Admin dashboard screen for EventLens administrators.
/// 
/// Provides administrative controls for:
/// - Event management (create, edit, delete all events)
/// - User management (view users, change roles)
/// - Analytics and reporting
/// - System configuration
/// 
/// Access restricted to users with role: 'admin'
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: 16),
              Text(
                'Manage events, users, and system configuration',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Admin action cards (placeholder)
              _AdminActionCard(
                icon: Icons.event,
                title: 'Event Management',
                subtitle: 'Create, edit, and manage all events',
                onTap: () {
                  // TODO: Navigate to event management
                },
              ),
              const SizedBox(height: 16),
              
              _AdminActionCard(
                icon: Icons.people,
                title: 'User Management',
                subtitle: 'View users and manage roles',
                onTap: () {
                  // TODO: Navigate to user management
                },
              ),
              const SizedBox(height: 16),
              
              _AdminActionCard(
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'View platform statistics',
                onTap: () {
                  // TODO: Navigate to analytics
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
