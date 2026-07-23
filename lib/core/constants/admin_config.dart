import 'package:firebase_auth/firebase_auth.dart';

/// Admin gating for catalog-management tools (currently the size-chart entry
/// screen).
///
/// HOW TO SET UP:
///  1. Find your Firebase Auth UID — Firebase Console → Authentication → Users,
///     then copy the "User UID" for your account (st29052026@gmail.com).
///  2. Paste it into [adminUid] below.
///  3. Put the SAME uid in the Firestore rule for `sizeCharts` writes:
///        allow write: if request.auth.uid == "THAT_UID";
///
/// While [adminUid] is empty, all admin-only UI stays hidden from everyone
/// (secure default) — so fill it in to reveal the size-chart tool for yourself.
class AdminConfig {
  /// The store owner's Firebase Auth UID. Empty = admin UI hidden for all.
  static const String adminUid = 'bpvQoMvY1ieTqIultUSmSvmnTuP2';

  /// True only when the signed-in user is the configured admin.
  static bool get isCurrentUserAdmin {
    if (adminUid.isEmpty) return false;
    return FirebaseAuth.instance.currentUser?.uid == adminUid;
  }
}
