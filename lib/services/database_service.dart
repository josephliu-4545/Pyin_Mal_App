import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pyin_mal_app/models/user_profile.dart';

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

      List<String> viewedItems = viewsSnap.docs.map((d) => d.data()['productId'] as String).toList();
      List<String> recentSearches = searchesSnap.docs.map((d) => d.data()['query'] as String).toList();

      String context = "";
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
