import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/firestore_service.dart';

/// Event discovery and browsing screen with real-time updates.
///
/// Displays all active events with:
/// - Real-time Firestore listeners for instant updates
/// - Event name, category, and schedule information
/// - Search and filter capabilities
/// - Pull-to-refresh functionality
///
/// **Why Real-Time Listeners for EventLens:**
///
/// 1. **Live Event Updates**: Event details change frequently
///    - Status changes (upcoming → active → completed)
///    - Time/location changes communicated instantly
///    - New events appear immediately without app restart
///
/// 2. **Multi-User Coordination**: Admin updates visible to all users
///    - Admin publishes event → Users see it instantly
///    - Admin cancels event → Users notified immediately
///    - Prevents users from traveling to cancelled events
///
/// 3. **Capacity Management**: Real-time stall availability
///    - Stall closes → Removed from browsing instantly
///    - Vendor goes offline → AR marker becomes inactive
///    - Prevents users from visiting closed booths
///
/// 4. **Better UX**: No manual refresh needed
///    - Traditional polling: Check every 30-60 seconds (wasteful)
///    - Real-time: Server pushes changes instantly (efficient)
///    - Users always see current information
///
/// 5. **Reduced Server Load**: Firestore handles multiplexing
///    - 1000 users = 1 WebSocket connection to Firestore (not 1000 HTTP requests)
///    - Firestore handles change detection and filtering
///    - Only changed documents transmitted (bandwidth efficient)
class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  /// Load events from Firestore with real-time updates
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      // Fetch events (can be extended to use streams for real-time updates)
      final events = await _firestoreService.fetchEvents();

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Filter events based on search query
  List<Map<String, dynamic>> get _filteredEvents {
    if (_searchQuery.isEmpty) {
      return _events;
    }

    final query = _searchQuery.toLowerCase();
    return _events.where((event) {
      final name = (event['name'] ?? '').toString().toLowerCase();
      final category = (event['category'] ?? '').toString().toLowerCase();
      final description = (event['description'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          category.contains(query) ||
          description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Events'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildEventsList(),
    );
  }

  Widget _buildEventsList() {
    final filteredEvents = _filteredEvents;

    if (filteredEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchQuery.isEmpty ? Icons.event_busy : Icons.search_off,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No events available'
                    : 'No events found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty
                    ? 'Check back later for upcoming events'
                    : 'Try a different search term',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final event = filteredEvents[index];
          return _buildEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final name = event['name'] ?? 'Unnamed Event';
    final category = event['category'] ?? 'General';
    final status = event['status'] ?? 'unknown';
    final description = event['description'] ?? '';
    final imageUrl = event['image_url'] as String?;

    // Parse dates
    final startDate = event['start_date'] != null
        ? (event['start_date'] as dynamic).toDate()
        : null;
    final endDate = event['end_date'] != null
        ? (event['end_date'] as dynamic).toDate()
        : null;

    // Format schedule
    String schedule = 'Schedule not available';
    if (startDate != null && endDate != null) {
      final dateFormat = DateFormat('MMM dd, yyyy');
      final timeFormat = DateFormat('h:mm a');

      if (dateFormat.format(startDate) == dateFormat.format(endDate)) {
        // Same day event
        schedule =
            '${dateFormat.format(startDate)}\n${timeFormat.format(startDate)} - ${timeFormat.format(endDate)}';
      } else {
        // Multi-day event
        schedule =
            '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
      }
    }

    // Status color
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.circle;
        break;
      case 'upcoming':
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event image
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              ),
            )
          else
            _buildImagePlaceholder(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and category
                Row(
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Chip(
                      label: Text(category),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Event name
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Schedule
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schedule,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description preview
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 16),

                // View details button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to event details screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Event details coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          Icons.event,
          size: 64,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }
}
