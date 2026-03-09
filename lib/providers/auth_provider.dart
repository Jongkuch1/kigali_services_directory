import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserProfileModel? _userProfile;
  String? _errorMessage;

  bool _emailNotVerified = false;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserProfileModel? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get emailNotVerified => _emailNotVerified;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated &&
      (_firebaseUser?.emailVerified ?? false);

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userProfile = null;
    } else {
      await user.reload();
      _firebaseUser = _authService.currentUser;
      if (_firebaseUser!.emailVerified) {
        _userProfile = await _authService.getUserProfile(user.uid);
        _status = AuthStatus.authenticated;
        _emailNotVerified = false;
      } else {
        _status = AuthStatus.unauthenticated;
        _emailNotVerified = true;
      }
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.signUp(email: email, password: password, name: name);
      _emailNotVerified = true;
      _status = AuthStatus.unauthenticated;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _firebaseErrorMessage(e.code);
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _emailNotVerified = false;
    notifyListeners();
    try {
      final credential =
          await _authService.signIn(email: email, password: password);
      await credential.user?.reload();
      if (!(credential.user?.emailVerified ?? false)) {
        _emailNotVerified = true;
        _status = AuthStatus.unauthenticated;
        _errorMessage =
            'Please verify your email before signing in. Check your inbox.';
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _firebaseErrorMessage(e.code);
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _emailNotVerified = false;
    _errorMessage = null;
  }

  Future<void> resendVerificationEmail() async {
    await _authService.resendVerificationEmail();
  }

  Future<void> forgotPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> updateUserName(String newName) async {
    if (_firebaseUser == null) return;
    await _authService.updateUserName(_firebaseUser!.uid, newName);
    _userProfile = UserProfileModel(
      uid: _userProfile!.uid,
      name: newName,
      email: _userProfile!.email,
      createdAt: _userProfile!.createdAt,
    );
    notifyListeners();
  }

  Future<void> checkEmailVerified() async {
    await _authService.reloadUser();
    _firebaseUser = _authService.currentUser;
    if (_firebaseUser?.emailVerified == true) {
      _userProfile = await _authService.getUserProfile(_firebaseUser!.uid);
      _emailNotVerified = false;
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Authentication error: $code';
    }
  }
}
