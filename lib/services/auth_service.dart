import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Stream ───────────────────────────────────────────────────────────────

  /// Auth state stream — emits User? whenever login/logout happens.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user (null if not logged in).
  static User? get currentUser => _auth.currentUser;

  // ─── Sign Up ──────────────────────────────────────────────────────────────

  /// Creates a Firebase Auth user and saves their profile to Firestore.
  /// City is null until they pick one on CitySelectionScreen.
  static Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = UserModel(
      uid: cred.user!.uid,
      name: name.trim(),
      email: email.trim(),
      role: 'patient',
      city: null,
      createdAt: Timestamp.now(),
    );

    await _db.collection('users').doc(user.uid).set(user.toMap());

    // Update display name in Firebase Auth too
    await cred.user!.updateDisplayName(name.trim());
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── Firestore User Data ──────────────────────────────────────────────────

  /// Fetch the full UserModel from Firestore for the given uid.
  static Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Save / update the user's selected city in Firestore.
  static Future<void> updateCity(String uid, String city) async {
    await _db.collection('users').doc(uid).update({'city': city});
  }
}