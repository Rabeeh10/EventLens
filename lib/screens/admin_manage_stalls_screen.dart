import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'admin_add_stall_screen.dart';
import 'admin_edit_stall_screen.dart';
import 'admin_edit_stall_screen.dart';

/// Admin screen for managing stalls within an event.
/// 
/// Displays all stalls for a selected event with options to:
/// - Add new stalls
/// - Edit existing stalls
/// - Delete stalls (with confirmation)
/// - View stall details including AR marker info
class AdminManageStallsScreen extends StatefulWidget {
  final String eventId;
  final String eventName;

  const AdminManageStallsScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

  @override
  State<AdminManageStallsScreen> createState() => _AdminManageStallsScreenState();
}

class _AdminManageStallsScreenState extends State<AdminManageStallsScreen> {
  final _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _stalls = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStalls();
  }

  /// Loads all stalls for the current event
  Future<void> _loadStalls() async {
    setState(() => _isLoading = true);
    
    final stalls = await _firestoreService.fetchStallsByEvent(widget.eventId);
    
    if (mounted) {
      setState(() {
        _stalls = stalls;
        _isLoading = false;
      });
    }
  }

  /// Filters stalls based on search query
  List<Map<String, dynamic>> get _filteredStalls {
    if (_searchQuery.isEmpty) {
      return _stalls;
    }
    
    final query = _searchQuery.toLowerCase();
    return _stalls.where((stall) {
      final name = (stall['name'] ?? '').toString().toLowerCase();
      final category = (stall['category'] ?? '').toString().toLowerCase();
      final markerId = (stall['marker_id'] ?? '').toString().toLowerCase();
      return name.contains(query) || category.contains(query) || markerId.contains(query);
    }).toList();
  }

  /// Handles stall deletion with confirmation
  Future<void> _handleDelete(String stallId, String stallName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stall'),
        content: Text(
          'Are you sure you want to delete "$stallName"?\n\n'
          'This will remove the stall and its AR marker from the event.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting stall...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final success = await _firestoreService.deleteStall(stallId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ "$stallName" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadStalls();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete stall'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Navigates to edit screen
  Future<void> _navigateToEdit(Map<String, dynamic> stall) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditStallScreen(stall: stall),
      ),
    );

    if (result == true) {
      _loadStalls();
    }
  }

  /// Navigates to add screen
  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddStallScreen(
          eventId: widget.eventId,
          eventName: widget.eventName,
        ),
      ),
    );

    if (result == true) {
      _loadStalls();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Stalls'),
            Text(
              widget.eventName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search stalls or marker IDs...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stalls.isEmpty
              ? _buildEmptyState()
              : _buildStallsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Stall'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No stalls yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add stalls to this event',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Stall'),
          ),
        ],
      ),
    );
  }

  Widget _buildStallsList() {
    final stalls = _filteredStalls;

    if (stalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text('No stalls found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStalls,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stalls.length,
        itemBuilder: (context, index) => _buildStallCard(stalls[index]),
      ),
    );
  }

  Widget _buildStallCard(Map<String, dynamic> stall) {
    final stallId = stall['stall_id'] as String;
    final name = stall['name'] ?? 'Unnamed Stall';
    final category = stall['category'] ?? 'N/A';
    final markerId = stall['marker_id'] ?? 'No marker';
    final viewCount = stall['view_count'] ?? 0;
    final rating = (stall['rating'] ?? 0.0).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.store,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(category),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Marker ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 20,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Marker ID: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    markerId,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Stats
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('$viewCount views'),
                const SizedBox(width: 16),
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(rating.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if (stall['description'] != null)
              Text(
                stall['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _navigateToEdit(stall),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleDelete(stallId, name),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
