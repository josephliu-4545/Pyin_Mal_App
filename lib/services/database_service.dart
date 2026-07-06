import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pyin_mal_app/models/user_profile.dart';
import 'package:pyin_mal_app/models/wardrobe_item.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Get current user ID
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── User Profile ────────────────────────────────────────────────────────────

  Future<void> createUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.id).set(profile.toMap());
  }

  Stream<UserProfile?> getUserProfile() {
    if (_uid == null) return Stream.value(null);
    return _db.collection('users').doc(_uid).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return UserProfile.fromMap(snap.data()!, snap.id);
      }
      return null;
    });
  }

  Future<void> updateUserPoints(int pointsToAdd) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'points': FieldValue.increment(pointsToAdd),
    });
  }

  Future<void> updateUserPreferences(List<String> preferences) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).update({
      'preferences': preferences,
    });
  }

  /// Save the body info + style preferences collected during profile setup.
  /// Uses set(merge) so it works whether or not the user doc already exists.
  Future<void> saveProfileSetup(Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set(
      {
        ...data,
        'profileCompleted': true,
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── User-guide tour ──────────────────────────────────────────────────────
  /// True if the user has already seen (or doesn't need) the guided tour.
  /// Absent flag → treated as completed, so only accounts explicitly marked
  /// pending (new registrations) auto-run the tour.
  Future<bool> isGuideCompleted() async {
    if (_uid == null) return true;
    final snap = await _db.collection('users').doc(_uid).get();
    return (snap.data()?['guideCompleted'] as bool?) ?? true;
  }

  /// Mark a freshly registered account so the tour runs once on first home view.
  Future<void> markGuidePending() async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set(
        {'guideCompleted': false}, SetOptions(merge: true));
  }

  /// Remember that the tour has been seen so it never auto-runs again.
  Future<void> markGuideCompleted() async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set(
        {'guideCompleted': true}, SetOptions(merge: true));
  }

  /// One-shot read of the raw user doc (profile-setup stats, measurements…).
  Future<Map<String, dynamic>?> getUserData() async {
    if (_uid == null) return null;
    final snap = await _db.collection('users').doc(_uid).get();
    return snap.data();
  }

  /// Persist the latest Bodygram scan result on the user doc.
  Future<void> saveBodyMeasurements(Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set(
      {
        'bodyMeasurements': data,
        'bodyMeasuredAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ── Digital wardrobe ─────────────────────────────────────────────────────────

  /// Adds an item to the current user's wardrobe. Returns the new doc id, or
  /// null if there's no signed-in user.
  Future<String?> addWardrobeItem(WardrobeItem item) async {
    if (_uid == null) return null;
    final ref = await _db
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .add(item.toMap());
    return ref.id;
  }

  /// Live stream of the current user's wardrobe, newest first.
  Stream<List<WardrobeItem>> streamWardrobe() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WardrobeItem.fromMap(d.data(), d.id))
            .toList());
  }

  /// Marks a wardrobe item as worn (e.g. when tagged in an OOTD post or used
  /// in a try-on) — increments the wear count and stamps the last-worn date.
  Future<void> markWardrobeItemWorn(String itemId) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .doc(itemId)
        .update({
      'timesWorn': FieldValue.increment(1),
      'lastWornAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteWardrobeItem(String itemId) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .doc(itemId)
        .delete();
  }

  // ── Tracking ───────────────────────────────────────────────────────────────

  Future<void> trackProductView(String productId) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('views').add({
      'productId': productId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> trackSearch(String query) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('searches').add({
      'query': query,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPurchase(String productId, double priceInMmk) async {
    if (_uid == null) return;
    
    // 1 point per 100 MMK spent
    final pointsEarned = (priceInMmk / 100).floor();

    // Run as a batch so both operations happen together
    final batch = _db.batch();
    
    // Add to purchases
    final purchaseRef = _db.collection('users').doc(_uid).collection('purchases').doc();
    batch.set(purchaseRef, {
      'productId': productId,
      'price': priceInMmk,
      'pointsEarned': pointsEarned,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update user's points
    final userRef = _db.collection('users').doc(_uid);
    batch.update(userRef, {
      'points': FieldValue.increment(pointsEarned),
    });

    await batch.commit();
  }

  // Fetch recent history for Gemini context
  Future<String> getRecentHistoryContext() async {
    if (_uid == null) return "";

    try {
      final viewsSnap = await _db.collection('users').doc(_uid)
          .collection('views')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      
      final searchesSnap = await _db.collection('users').doc(_uid)
          .collection('searches')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      final purchasesSnap = await _db.collection('users').doc(_uid)
          .collection('purchases')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      List<String> viewedItems = viewsSnap.docs.map((d) => d.data()['productId'] as String).toList();
      List<String> recentSearches = searchesSnap.docs.map((d) => d.data()['query'] as String).toList();
      List<String> recentPurchases = purchasesSnap.docs.map((d) => d.data()['productId'] as String).toList();

      // Fetch user profile to get survey preferences
      final userDoc = await _db.collection('users').doc(_uid).get();
      List<String> surveyPreferences = [];
      if (userDoc.exists && userDoc.data() != null) {
        surveyPreferences = List<String>.from(userDoc.data()!['preferences'] ?? []);
      }

      String context = "";
      if (surveyPreferences.isNotEmpty) {
        context += "User's stated style preferences (from onboarding survey): ${surveyPreferences.join(', ')}.\n";
      }
      if (recentPurchases.isNotEmpty) {
        context += "User recently bought product IDs: ${recentPurchases.join(', ')}.\n";
      }
      if (viewedItems.isNotEmpty) {
        context += "User recently viewed product IDs: ${viewedItems.join(', ')}.\n";
      }
      if (recentSearches.isNotEmpty) {
        context += "User recently searched for: ${recentSearches.join(', ')}.\n";
      }
      
      return context;
    } catch (e) {
      print('Error getting history context: $e');
      return "";
    }
  }
}
