import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
/// - **Error Handling**: Consistent error management with offline support
/// - **Security**: Centralized permission checks
///
/// **Offline Caching Benefits for EventLens:**
///
/// 1. **Event Browsing Without Internet**
///    - Users can view previously loaded events offline
///    - Critical for venues with poor WiFi/cellular coverage
///    - Cached data persists across app restarts
///
/// 2. **Seamless AR Scanning**
///    - Stall data cached after first load
///    - AR marker scans work offline (reads from cache)
///    - No loading delays during event navigation
///
/// 3. **Write Queue for Poor Connectivity**
///    - Favorites, ratings, activity logs queued locally
///    - Auto-syncs when connection restored
///    - Users never lose their interactions
///
/// 4. **Bandwidth Savings**
///    - Only downloads changed data (delta updates)
///    - Reduces mobile data costs for users
///    - Faster app performance (cache reads < 10ms)
///
/// 5. **Large Event Performance**
///    - 500-vendor event cached = instant browsing
///    - No repeated server queries for same data
///    - Battery savings (fewer network operations)
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService() {
    // Enable offline persistence for better UX
    // Firestore caches queries and documents automatically
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Collection references
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _stallsCollection => _firestore.collection('stalls');
  CollectionReference get _userActivityCollection =>
      _firestore.collection('user_activity');

  /// Handles Firestore errors and returns user-friendly error messages.
  ///
  /// Detects:
  /// - Network failures (offline, timeout)
  /// - Permission denied (security rules)
  /// - Missing documents (404)
  /// - General Firestore errors
  String _handleFirestoreError(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Using cached data.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
          return 'Network unavailable. Showing cached data.';
        case 'permission-denied':
          return 'Access denied. Please check your permissions.';
        case 'not-found':
          return 'Requested data not found.';
        case 'deadline-exceeded':
          return 'Request timeout. Please try again.';
        case 'resource-exhausted':
          return 'Too many requests. Please wait a moment.';
        case 'unauthenticated':
          return 'Please log in to continue.';
        default:
          return 'Error: ${error.message ?? "Unknown error"}';
      }
    }

    return 'An unexpected error occurred: $error';
  }

  // ==================== EVENT OPERATIONS ====================

  /// Fetches all active events.
  ///
  /// Returns events sorted by start_date in descending order.
  /// Filters out cancelled events by default.
  ///
  /// **Offline Support:**
  /// - Returns cached data if network unavailable
  /// - Snapshot.metadata.isFromCache indicates cache vs server
  ///
  /// Throws exception with user-friendly message on error.
  Future<List<Map<String, dynamic>>> fetchEvents({
    String? status,
    int limit = 50,
  }) async {
    try {
      Query query = _eventsCollection;

      // Filter by status if provided (simple equality doesn't need index)
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Order by start_date
      query = query.orderBy('start_date', descending: true);

      final snapshot = await query.limit(limit).get();

      // Check if data is from cache (offline mode)
      if (snapshot.metadata.isFromCache) {
        print('📦 Events loaded from cache (offline mode)');
      } else {
        print('🌐 Events loaded from server');
      }

      final events = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['event_id'] = doc.id;
        data['is_cached'] = snapshot.metadata.isFromCache;
        return data;
      }).toList();

      // Filter out cancelled events client-side if no specific status requested
      if (status == null) {
        return events.where((event) => event['status'] != 'cancelled').toList();
      }

      return events;
    } on FirebaseException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('🚨 FirebaseException in fetchEvents: $errorMsg');
      throw Exception(errorMsg);
    } on SocketException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('📡 Network error in fetchEvents: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      print('❌ Unexpected error in fetchEvents: $e');
      throw Exception('Failed to load events. Please try again.');
    }
  }

  /// Fetches a single event by ID.
  ///
  /// Returns null if event doesn't exist.
  /// Throws exception on network or permission errors.
  Future<Map<String, dynamic>?> fetchEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();

      if (!doc.exists) {
        print('📭 Event not found: $eventId');
        return null;
      }

      if (doc.metadata.isFromCache) {
        print('📦 Event $eventId loaded from cache');
      }

      final data = doc.data() as Map<String, dynamic>;
      data['event_id'] = doc.id;
      data['is_cached'] = doc.metadata.isFromCache;
      return data;
    } on FirebaseException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('🚨 FirebaseException in fetchEventById: $errorMsg');
      throw Exception(errorMsg);
    } on SocketException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('📡 Network error in fetchEventById: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      print('❌ Unexpected error in fetchEventById: $e');
      throw Exception('Failed to load event details.');
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
  ///
  /// **Offline Behavior:**
  /// - Write queued locally if offline
  /// - Syncs automatically when connection restored
  /// - Returns temporary ID immediately
  ///
  /// Throws exception on permission denied or other errors.
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
      print('✅ Event created: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('🚨 FirebaseException in addEvent: $errorMsg');

      if (e.code == 'permission-denied') {
        throw Exception(
          'You do not have permission to add events. Admin access required.',
        );
      }
      throw Exception(errorMsg);
    } on SocketException catch (e) {
      print('📡 Network error in addEvent: ${e.message}');
      throw Exception(
        'No internet connection. Event will be saved when online.',
      );
    } catch (e) {
      print('❌ Unexpected error in addEvent: $e');
      throw Exception('Failed to create event. Please try again.');
    }
  }

  /// Updates an existing event (admin only).
  ///
  /// Only updates provided fields. Automatically updates updated_at timestamp.
  ///
  /// **Offline Behavior:**
  /// - Update queued locally if offline
  /// - Syncs when connection restored
  ///
  /// Throws exception on permission denied, missing document, or network errors.
  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      // Add updated timestamp
      updates['updated_at'] = Timestamp.now();

      await _eventsCollection.doc(eventId).update(updates);
      print('✅ Event updated: $eventId');
      return true;
    } on FirebaseException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('🚨 FirebaseException in updateEvent: $errorMsg');

      if (e.code == 'permission-denied') {
        throw Exception(
          'You do not have permission to update events. Admin access required.',
        );
      } else if (e.code == 'not-found') {
        throw Exception('Event not found. It may have been deleted.');
      }
      throw Exception(errorMsg);
    } on SocketException catch (e) {
      print('📡 Network error in updateEvent: ${e.message}');
      throw Exception('No internet connection. Changes will sync when online.');
    } catch (e) {
      print('❌ Unexpected error in updateEvent: $e');
      throw Exception('Failed to update event. Please try again.');
    }
  }

  /// Deletes an event (admin only).
  ///
  /// CAUTION: This is a hard delete. Consider soft delete (status: 'deleted')
  /// for production to maintain referential integrity.
  ///
  /// **Offline Behavior:**
  /// - Delete queued locally if offline
  /// - Syncs when connection restored
  /// - Document removed from cache immediately
  ///
  /// Throws exception on permission denied or network errors.
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
      print('✅ Event deleted: $eventId');
      return true;
    } on FirebaseException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('🚨 FirebaseException in deleteEvent: $errorMsg');

      if (e.code == 'permission-denied') {
        throw Exception(
          'You do not have permission to delete events. Admin access required.',
        );
      } else if (e.code == 'not-found') {
        throw Exception('Event not found. It may have been already deleted.');
      }
      throw Exception(errorMsg);
    } on SocketException catch (e) {
      print('📡 Network error in deleteEvent: ${e.message}');
      throw Exception(
        'No internet connection. Deletion will sync when online.',
      );
    } catch (e) {
      print('❌ Unexpected error in deleteEvent: $e');
      throw Exception('Failed to delete event. Please try again.');
    }
  }

  // ==================== STALL OPERATIONS ====================

  /// Fetches all stalls for a specific event.
  ///
  /// Returns stalls sorted by name alphabetically.
  ///
  /// **Offline Support:**
  /// - Returns cached stalls if previously viewed
  /// - Critical for AR scanning without network
  ///
  /// Throws exception on errors.
  Future<List<Map<String, dynamic>>> fetchStallsByEvent(String eventId) async {
    try {
      final snapshot = await _stallsCollection
          .where('event_id', isEqualTo: eventId)
          .orderBy('name')
          .get();

      if (snapshot.metadata.isFromCache) {
        print('📦 Stalls for $eventId loaded from cache');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['stall_id'] = doc.id;
        data['is_cached'] = snapshot.metadata.isFromCache;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('🚨 FirebaseException in fetchStallsByEvent: $errorMsg');
      throw Exception(errorMsg);
    } on SocketException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('📡 Network error in fetchStallsByEvent: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      print('❌ Unexpected error in fetchStallsByEvent: $e');
      throw Exception('Failed to load stalls. Please try again.');
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
  ///
  /// **Offline Support (CRITICAL for AR):**
  /// - Returns cached stall data if previously scanned
  /// - Enables AR experience without network
  /// - Cache persists between app sessions
  ///
  /// Returns null if no stall matches the marker.
  /// Throws exception on network errors.
  Future<Map<String, dynamic>?> fetchStallByMarkerId(String markerId) async {
    try {
      final snapshot = await _stallsCollection
          .where('marker_id', isEqualTo: markerId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('📭 No stall found for marker: $markerId');
        return null;
      }

      if (snapshot.metadata.isFromCache) {
        print(
          '📦 Stall for marker $markerId loaded from cache (AR offline mode)',
        );
      }

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      data['stall_id'] = snapshot.docs.first.id;
      data['is_cached'] = snapshot.metadata.isFromCache;
      return data;
    } on FirebaseException catch (e) {
      final errorMsg = _handleFirestoreError(e);
      print('🚨 FirebaseException in fetchStallByMarkerId: $errorMsg');
      throw Exception(errorMsg);
    } on SocketException catch (e) {
      print('📡 Network error in fetchStallByMarkerId: ${e.message}');
      throw Exception(
        'AR scanning requires cached data. Please connect to internet once.',
      );
    } catch (e) {
      print('❌ Unexpected error in fetchStallByMarkerId: $e');
      throw Exception('Failed to load stall information.');
    }
  }

  /// Stream stall data by marker_id for real-time AR overlay updates.
  ///
  /// **Real-Time Benefits:**
  /// - Crowd level changes propagate to AR overlay immediately
  /// - Stall status changes (open/closed) update live
  /// - Special offers appear in real-time
  /// - No need to rescan marker to see updates
  Stream<Map<String, dynamic>?> streamStallByMarkerId(String markerId) {
    return _firestore
        .collection('stalls')
        .where('marker_id', isEqualTo: markerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            print('📭 No stall found for marker: $markerId');
            return null;
          }

          final data = snapshot.docs.first.data();
          data['stall_id'] = snapshot.docs.first.id;
          data['is_cached'] = snapshot.metadata.isFromCache;
          data['last_updated'] = DateTime.now().toIso8601String();

          // Log if data came from cache or server
          final source = snapshot.metadata.isFromCache
              ? '💾 cache'
              : '☁️ server';
          print('📡 Stall stream update ($source): ${data['name']}');

          return data;
        })
        .handleError((error) {
          print('⚠️ Stream error for marker $markerId: $error');
          return null;
        });
  }

  /// Stream event data by ID for real-time updates.
  ///
  /// **Use Cases:**
  /// - Event schedule changes propagate to all viewers
  /// - Cancellation announcements appear immediately
  /// - Status updates (ongoing, ended) reflected in real-time
  Stream<Map<String, dynamic>?> streamEventById(String eventId) {
    return _firestore
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            print('📭 Event not found: $eventId');
            return null;
          }

          final data = snapshot.data() as Map<String, dynamic>;
          data['event_id'] = snapshot.id;
          data['is_cached'] = snapshot.metadata.isFromCache;
          data['last_updated'] = DateTime.now().toIso8601String();

          final source = snapshot.metadata.isFromCache
              ? '💾 cache'
              : '☁️ server';
          print('📡 Event stream update ($source): ${data['name']}');

          return data;
        })
        .handleError((error) {
          print('⚠️ Stream error for event $eventId: $error');
          return null;
        });
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
  Future<bool> updateStall(String stallId, Map<String, dynamic> updates) async {
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
  ///
  /// **Offline Support (CRITICAL):**
  /// - Activity queued locally if offline
  /// - Auto-syncs when connection restored
  /// - Users never lose their interactions
  /// - Enables seamless AR scanning offline
  ///
  /// Returns the activity ID (may be temporary if offline).
  /// Silently fails on errors to not interrupt user experience.
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
      print('📊 Activity logged: $activityType');
      return docRef.id;
    } on FirebaseException catch (e) {
      // Don't throw for activity logging - fail silently
      print('⚠️ FirebaseException in logUserActivity: ${e.code}');
      if (e.code == 'unavailable') {
        print('📥 Activity will sync when online');
      }
      return null;
    } on SocketException {
      // Offline - activity will be queued
      print('📥 Activity queued for offline sync: $activityType');
      return null;
    } catch (e) {
      print('⚠️ Failed to log activity (non-critical): $e');
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
          .map(
            (doc) =>
                (doc.data() as Map<String, dynamic>)['stall_id'] as String?,
          )
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
        final activityType =
            (doc.data() as Map<String, dynamic>)['activity_type'];

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

      return {'scans': scans, 'views': views, 'favorites': favorites};
    } catch (e) {
      print('Error fetching stall analytics: $e');
      return {'scans': 0, 'views': 0, 'favorites': 0};
    }
  }
}
