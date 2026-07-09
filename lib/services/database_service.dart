import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pyin_mal_app/models/user_profile.dart';
import 'package:pyin_mal_app/models/wardrobe_item.dart';
import 'package:pyin_mal_app/models/outfit_post.dart';
import 'package:pyin_mal_app/models/body_measurements.dart';

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

  /// One-shot fetch of the current user's wardrobe — used to populate the
  /// "what are you wearing" tag picker when posting an OOTD.
  Future<List<WardrobeItem>> getWardrobeItemsOnce() async {
    if (_uid == null) return [];
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('wardrobe')
        .orderBy('addedAt', descending: true)
        .get();
    return snap.docs.map((d) => WardrobeItem.fromMap(d.data(), d.id)).toList();
  }

  // ── Outfit of the day / community feed ──────────────────────────────────────

  /// Posts an OOTD photo to the global community feed, tagging which
  /// wardrobe items are being worn, and marks each tagged item as worn.
  Future<String?> createOutfitPost({
    required String imageUrl,
    String? caption,
    List<String> wardrobeItemIds = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final post = OutfitPost(
      id: '',
      userId: user.uid,
      username: user.displayName ?? user.email?.split('@').first ?? 'User',
      avatarUrl: user.photoURL,
      imageUrl: imageUrl,
      caption: caption,
      wardrobeItemIds: wardrobeItemIds,
      createdAt: DateTime.now(),
    );

    final ref = await _db.collection('outfitPosts').add(post.toMap());
    for (final itemId in wardrobeItemIds) {
      await markWardrobeItemWorn(itemId);
    }
    return ref.id;
  }

  /// Live stream of the global OOTD feed, newest first.
  Stream<List<OutfitPost>> streamFeed({int limit = 100}) {
    return _db
        .collection('outfitPosts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OutfitPost.fromMap(d.data(), d.id)).toList());
  }

  /// Whether the current user has liked [postId].
  Future<bool> isLikedByMe(String postId) async {
    if (_uid == null) return false;
    final snap = await _db
        .collection('outfitPosts')
        .doc(postId)
        .collection('likes')
        .doc(_uid)
        .get();
    return snap.exists;
  }

  /// Likes/unlikes a post for the current user, keeping the denormalized
  /// `likeCount` on the post doc in sync via a transaction so concurrent
  /// likes can't race each other or double-count the same user.
  Future<bool> toggleLike(String postId) async {
    if (_uid == null) return false;
    final postRef = _db.collection('outfitPosts').doc(postId);
    final likeRef = postRef.collection('likes').doc(_uid);

    return _db.runTransaction<bool>((tx) async {
      final likeSnap = await tx.get(likeRef);
      final nowLiked = !likeSnap.exists;
      if (nowLiked) {
        tx.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        tx.update(postRef, {'likeCount': FieldValue.increment(1)});
      } else {
        tx.delete(likeRef);
        tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
      }
      return nowLiked;
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

  /// Live stream of the user's purchases, newest first (for Order History).
  Stream<List<Map<String, dynamic>>> streamPurchases() {
    if (_uid == null) return Stream.value(const []);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('purchases')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
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

      // Fetch user profile: sign-up survey (body basics + style) and the
      // latest Bodygram scan, so the stylist can size and style accurately.
      final userDoc = await _db.collection('users').doc(_uid).get();
      final data = userDoc.data() ?? <String, dynamic>{};
      final surveyPreferences = List<String>.from(data['preferences'] ?? []);

      String context = "";

      // Body basics collected at sign-up (gender, age, height, weight, tone).
      final basics = <String>[];
      if (data['gender'] != null) basics.add('gender ${data['gender']}');
      if (data['age'] != null) basics.add('age ${data['age']}');
      if (data['heightCm'] != null) basics.add('height ${data['heightCm']}cm');
      if (data['weightKg'] != null) basics.add('weight ${data['weightKg']}kg');
      if (data['skinTone'] != null) basics.add('${data['skinTone']} skin tone');
      if (basics.isNotEmpty) {
        context += "User body basics: ${basics.join(', ')}.\n";
      }

      // Style survey (outfit types, style vibe, fit, favourite colours).
      final outfitTypes = List<String>.from(data['outfitTypes'] ?? []);
      if (outfitTypes.isNotEmpty) {
        context += "Outfit types they wear: ${outfitTypes.join(', ')}.\n";
      }
      final styles = List<String>.from(data['styles'] ?? []);
      if (styles.isNotEmpty) {
        context += "Style vibe: ${styles.join(', ')}.\n";
      }
      if (data['fit'] != null) {
        context += "Preferred fit: ${data['fit']}.\n";
      }
      final palette = List<String>.from(data['preferredColors'] ?? []);
      if (palette.isNotEmpty) {
        context += "Favourite colours (hex): ${palette.join(', ')}.\n";
      }

      // Real body measurements from the latest Bodygram scan, in cm — the
      // ground truth for size recommendations.
      final bm = data['bodyMeasurements'];
      if (bm is Map) {
        final measurements =
            BodyMeasurements.fromMap(Map<String, dynamic>.from(bm));
        final parts = <String>[];
        for (final name in const ['bustGirth', 'waistGirth', 'hipGirth']) {
          final cm = measurements.cm(name);
          if (cm != null) {
            parts.add(
                '${name.replaceAll('Girth', '')} ${cm.toStringAsFixed(0)}cm');
          }
        }
        if (parts.isNotEmpty) {
          context +=
              "Bodygram body measurements: ${parts.join(', ')}. Use these to recommend the correct clothing size.\n";
        }
      }

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
