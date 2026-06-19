// lib/data/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserType userType,
    String preferredLanguage = 'en',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user!.updateDisplayName(fullName);

      final user = UserModel(
        uid: credential.user!.uid,
        email: email,
        phone: phone,
        fullName: fullName,
        userType: userType,
        preferredLanguage: preferredLanguage,
        createdAt: DateTime.now(),
        availableForGeneralLabor: userType == UserType.worker ? true : null,
        skills: userType == UserType.worker ? [] : null,
        portfolioImages: userType == UserType.worker ? [] : null,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getUserById(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update(user.toMap());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password': return 'Password must be at least 6 characters.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'invalid-email': return 'Please enter a valid email address.';
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password. Please try again.';
      case 'too-many-requests': return 'Too many attempts. Please try again later.';
      default: return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
