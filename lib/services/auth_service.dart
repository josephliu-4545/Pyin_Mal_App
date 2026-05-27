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
        // Update display name in Firebase Auth
        await user.updateDisplayName(displayName);
        
        // Create user profile in Firestore
        final profile = UserProfile(
          id: user.uid,
          email: email,
          displayName: displayName,
          points: 0,
        );
        
        await _db.createUserProfile(profile);
        return profile;
      }
      return null;
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
    } catch (e) {
      print('Sign In Error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
