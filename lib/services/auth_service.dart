import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _db = DatabaseService();

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserProfile?> registerWithEmail(String email, String password, String displayName) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      final User? user = result.user;
      if (user != null) {
        final profile = UserProfile(
          id: user.uid,
          email: email,
          displayName: displayName,
          points: 0,
        );
        // The account is created at this point — profile/name writes are
        // best-effort and must not make registration look like a failure.
        try {
          await user.updateDisplayName(displayName);
          await _db.createUserProfile(profile);
          // New account → run the guided tour once on first home view.
          await _db.markGuidePending();
        } catch (e) {
          print('Post-registration profile setup error: $e');
        }
        return profile;
      }
      return null;
    } on FirebaseAuthException {
      rethrow; // Let the UI show the real reason (email in use, weak password…)
    } catch (e) {
      print('Registration Error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow; // Let the UI show the real reason
    } catch (e) {
      print('Sign In Error: $e');
      return null;
    }
  }

  // Send a password reset email. Returns null on success, or an error message.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address looks invalid.';
        case 'user-not-found':
          return 'No account found with that email.';
        default:
          return e.message ?? 'Could not send reset email.';
      }
    } catch (e) {
      return 'Could not send reset email.';
    }
  }

  // ── Social sign-in via Firebase OAuth providers ────────────────────────────
  // Works on web (popup) and mobile (native OAuth flow) without extra packages.
  // Requires the provider to be enabled in the Firebase console.
  Future<User?> _signInWithProvider(AuthProvider Function() build,
      {required String fallbackProviderId}) async {
    try {
      final UserCredential result;
      if (kIsWeb) {
        result = await _auth.signInWithPopup(build());
      } else {
        result = await _auth.signInWithProvider(build());
      }
      final user = result.user;
      if (user != null) {
        // Create a profile if this is their first sign-in.
        await _db.createUserProfile(UserProfile(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'Fashionista',
          points: 0,
        ));
      }
      return user;
    } catch (e) {
      print('$fallbackProviderId sign-in error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() =>
      _signInWithProvider(() => GoogleAuthProvider(),
          fallbackProviderId: 'google.com');

  Future<User?> signInWithFacebook() =>
      _signInWithProvider(() => FacebookAuthProvider(),
          fallbackProviderId: 'facebook.com');

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
