import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore service layer for EventLens.
/// 
/// Isolates all Firestore database operations from the UI layer.
/// Provides clean, testable methods for CRUD operations on events,
/// stalls, and user activity tracking.
/// 
/// Benefits of isolation:
/// - **Testability**: Mock database calls without real Firestore
/// - **Maintainability**: Database schema changes stay in one place
/// - **Reusability**: Same methods across multiple screens
/// - **Error Handling**: Consistent error management
/// - **Security**: Centralized permission checks
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _stallsCollection => _firestore.collection('stalls');
  CollectionReference get _userActivityCollection => _firestore.collection('user_activity');

  // ==================== EVENT OPERATIONS ====================

  /// Fetches all active events.
  /// 
  /// Returns events sorted by start_date in descending order.
  /// Filters out cancelled events by default.
  /// 
  /// Returns empty list if no events found or on error.
  Future<List<Map<String, dynamic>>> fetchEvents({
    String? status,
    int limit = 50,
  }) async {
    try {
      Query query = _eventsCollection.orderBy('start_date', descending: true);

      // Filter by status if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      } else {
        // Default: exclude cancelled events
        query = query.where('status', isNotEqualTo: 'cancelled');
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['event_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  /// Fetches a single event by ID.
  /// 
  /// Returns null if event doesn't exist or on error.
  Future<Map<String, dynamic>?> fetchEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['event_id'] = doc.id;
      return data;
    } catch (e) {
      print('Error fetching event: $e');
      return null;
    }
  }

  /// Searches events by name or category.
  /// 
  /// Performs case-insensitive partial matching on name field.
  Future<List<Map<String, dynamic>>> searchEvents(String query) async {
    try {
      if (query.isEmpty) {
        return fetchEvents();
      }

      // Firestore doesn't support full-text search natively
      // This fetches all events and filters client-side
      // For production, consider Algolia or Elasticsearch
      final allEvents = await fetchEvents();
      
      final searchLower = query.toLowerCase();
      return allEvents.where((event) {
        final name = (event['name'] ?? '').toString().toLowerCase();
        final category = (event['category'] ?? '').toString().toLowerCase();
        return name.contains(searchLower) || category.contains(searchLower);
      }).toList();
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  /// Adds a new event (admin only).
  /// 
  /// Automatically adds created_at and updated_at timestamps.
  /// Returns the newly created event ID, or null on failure.
  Future<String?> addEvent({
    required String name,
    required String description,
    required Map<String, dynamic> location,
    required Timestamp startDate,
    required Timestamp endDate,
    required String category,
    String? imageUrl,
    String? organizer,
    String status = 'upcoming',
  }) async {
    try {
      final now = Timestamp.now();
      
      final eventData = {
        'name': name,
        'description': description,
        'location': location,
        'start_date': startDate,
        'end_date': endDate,
        'category': category,
        'image_url': imageUrl ?? '',
        'organizer': organizer ?? '',
        'status': status,
        'created_at': now,
        'updated_at': now,
      };

      final docRef = await _eventsCollection.add(eventData);
      return docRef.id;
    } catch (e) {
      print('Error adding event: $e');
      return null;
    }
  }

  /// Updates an existing event (admin only).
  /// 
  /// Only updates provided fields. Automatically updates updated_at timestamp.
  /// Returns true on success, false on failure.
  Future<bool> updateEvent(
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    try {
      // Add updated timestamp
      updates['updated_at'] = Timestamp.now();

      await _eventsCollection.doc(eventId).update(updates);
      return true;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    }
  }

  /// Deletes an event (admin only).
  /// 
  /// CAUTION: This is a hard delete. Consider soft delete (status: 'deleted')
  /// for production to maintain referential integrity.
  /// Returns true on success, false on failure.
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // ==================== STALL OPERATIONS ====================

  /// Fetches all stalls for a specific event.
  /// 
  /// Returns stalls sorted by name alphabetically.
  Future<List<Map<String, dynamic>>> fetchStallsByEvent(String eventId) async {
    try {
      final snapshot = await _stallsCollection
          .where('event_id', isEqualTo: eventId)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['stall_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching stalls: $e');
      return [];
    }
  }

  /// Fetches a single stall by ID.
  /// 
  /// Returns null if stall doesn't exist or on error.
  Future<Map<String, dynamic>?> fetchStallById(String stallId) async {
    try {
      final doc = await _stallsCollection.doc(stallId).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['stall_id'] = doc.id;
      return data;
    } catch (e) {
      print('Error fetching stall: $e');
      return null;
    }
  }

  /// Fetches a stall by AR marker ID.
  /// 
  /// Used when user scans an AR marker to retrieve stall information.
  /// Returns null if no stall matches the marker or on error.
  Future<Map<String, dynamic>?> fetchStallByMarkerId(String markerId) async {
    try {
      final snapshot = await _stallsCollection
          .where('marker_id', isEqualTo: markerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      data['stall_id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      print('Error fetching stall by marker: $e');
      return null;
    }
  }

  /// Searches stalls within an event by name or category.
  Future<List<Map<String, dynamic>>> searchStalls(
    String eventId,
    String query,
  ) async {
    try {
      if (query.isEmpty) {
        return fetchStallsByEvent(eventId);
      }

      final allStalls = await fetchStallsByEvent(eventId);
      
      final searchLower = query.toLowerCase();
      return allStalls.where((stall) {
        final name = (stall['name'] ?? '').toString().toLowerCase();
        final category = (stall['category'] ?? '').toString().toLowerCase();
        return name.contains(searchLower) || category.contains(searchLower);
      }).toList();
    } catch (e) {
      print('Error searching stalls: $e');
      return [];
    }
  }

  /// Adds a new stall (admin only).
  /// 
  /// Automatically adds created_at and updated_at timestamps.
  /// Initializes view_count and rating to 0.
  /// Returns the newly created stall ID, or null on failure.
  Future<String?> addStall({
    required String eventId,
    required String name,
    required String description,
    required String category,
    required String markerId,
    required Map<String, dynamic> location,
    Map<String, dynamic>? contactInfo,
    List<String>? images,
    List<String>? offers,
    String? qrCodeUrl,
    String? arModelUrl,
  }) async {
    try {
      final now = Timestamp.now();
      
      final stallData = {
        'event_id': eventId,
        'name': name,
        'description': description,
        'category': category,
        'marker_id': markerId,
        'location': location,
        'contact_info': contactInfo ?? {},
        'images': images ?? [],
        'offers': offers ?? [],
        'qr_code_url': qrCodeUrl ?? '',
        'ar_model_url': arModelUrl ?? '',
        'rating': 0.0,
        'view_count': 0,
        'created_at': now,
        'updated_at': now,
      };

      final docRef = await _stallsCollection.add(stallData);
      return docRef.id;
    } catch (e) {
      print('Error adding stall: $e');
      return null;
    }
  }

  /// Updates an existing stall (admin only).
  /// 
  /// Only updates provided fields. Automatically updates updated_at timestamp.
  /// Returns true on success, false on failure.
  Future<bool> updateStall(
    String stallId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = Timestamp.now();

      await _stallsCollection.doc(stallId).update(updates);
      return true;
    } catch (e) {
      print('Error updating stall: $e');
      return false;
    }
  }

  /// Deletes a stall (admin only).
  /// 
  /// Returns true on success, false on failure.
  Future<bool> deleteStall(String stallId) async {
    try {
      await _stallsCollection.doc(stallId).delete();
      return true;
    } catch (e) {
      print('Error deleting stall: $e');
      return false;
    }
  }

  /// Increments the view count for a stall.
  /// 
  /// Called when a user views stall details.
  Future<void> incrementStallViewCount(String stallId) async {
    try {
      await _stallsCollection.doc(stallId).update({
        'view_count': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // ==================== USER ACTIVITY TRACKING ====================

  /// Logs a user activity (view, scan, favorite, etc.).
  /// 
  /// Used for analytics and AI-powered recommendations.
  /// Returns the activity ID, or null on failure.
  Future<String?> logUserActivity({
    required String userId,
    required String activityType,
    String? eventId,
    String? stallId,
    String? markerId,
    double? ratingValue,
    Map<String, dynamic>? location,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activityData = {
        'user_id': userId,
        'activity_type': activityType,
        'event_id': eventId,
        'stall_id': stallId,
        'marker_id': markerId,
        'rating_value': ratingValue,
        'location': location,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.now(),
      };

      // Remove null values to keep documents clean
      activityData.removeWhere((key, value) => value == null);

      final docRef = await _userActivityCollection.add(activityData);
      return docRef.id;
    } catch (e) {
      print('Error logging user activity: $e');
      return null;
    }
  }

  /// Fetches user activity history.
  /// 
  /// Returns activities sorted by timestamp (most recent first).
  Future<List<Map<String, dynamic>>> fetchUserActivity(
    String userId, {
    String? activityType,
    int limit = 50,
  }) async {
    try {
      Query query = _userActivityCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (activityType != null) {
        query = query.where('activity_type', isEqualTo: activityType);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['activity_id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching user activity: $e');
      return [];
    }
  }

  /// Gets user's favorite stalls (marked as favorite).
  Future<List<String>> getUserFavoriteStalls(String userId) async {
    try {
      final snapshot = await _userActivityCollection
          .where('user_id', isEqualTo: userId)
          .where('activity_type', isEqualTo: 'favorite')
          .get();

      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['stall_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();
    } catch (e) {
      print('Error fetching favorite stalls: $e');
      return [];
    }
  }

  /// Gets analytics for a specific stall.
  /// 
  /// Returns total scans, views, and favorites for the stall.
  Future<Map<String, int>> getStallAnalytics(String stallId) async {
    try {
      final snapshot = await _userActivityCollection
          .where('stall_id', isEqualTo: stallId)
          .get();

      int scans = 0;
      int views = 0;
      int favorites = 0;

      for (var doc in snapshot.docs) {
        final activityType = (doc.data() as Map<String, dynamic>)['activity_type'];
        
        switch (activityType) {
          case 'scan':
            scans++;
            break;
          case 'view':
            views++;
            break;
          case 'favorite':
            favorites++;
            break;
        }
      }

      return {
        'scans': scans,
        'views': views,
        'favorites': favorites,
      };
    } catch (e) {
      print('Error fetching stall analytics: $e');
      return {'scans': 0, 'views': 0, 'favorites': 0};
    }
  }
}
