import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Send email verification
    await credential.user?.sendEmailVerification();

    // Create user profile in Firestore
    await _db.collection('users').doc(credential.user!.uid).set(
          UserProfileModel(
            uid: credential.user!.uid,
            name: name,
            email: email,
            createdAt: DateTime.now(),
          ).toFirestore(),
        );

    return credential;
  }

  // Sign in with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reload current user (to check email verification status)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update display name in Firestore users collection
  Future<void> updateUserName(String uid, String newName) async {
    await _db.collection('users').doc(uid).update({'name': newName});
  }

  // Fetch user profile from Firestore
  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfileModel.fromFirestore(doc);
    }
    return null;
  }
}
