import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _isGoogleSignInInitialized = false;

  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Stream to listen to auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    if (!kIsWeb) {
      await _googleSignIn.initialize(
        serverClientId: "313526013474-t3hllcl42h8e8um5ah3d1ei1hvq122k7.apps.googleusercontent.com",
      );
    }
    _isGoogleSignInInitialized = true;
  }

  // 1. Sign in with Email and Password
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  // 2. Register with Email and Password
  static Future<User?> registerWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      rethrow;
    }
  }

  static Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web için firebase_auth'un kendi Popup özelliğini kullanıyoruz.
        // Bu sayede web üzerindeki renderButton kısıtlamasını aşıp kendi butonumuzu kullanabiliriz.
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        final UserCredential result = await _auth.signInWithPopup(authProvider);
        return result.user;
      } else {
        // Mobil (Android/iOS) için
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        
        // accessToken null veriyoruz çünkü bu paket versiyonunda idToken yeterli.
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: null, 
          idToken: googleAuth.idToken,
        );

        final UserCredential result = await _auth.signInWithCredential(credential);
        return result.user;
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled.name || e.code == "canceled") {
        return null;
      }
      debugPrint("Google Sign In Error: \${e.code} - \${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("Unknown Auth Error: \$e");
      rethrow;
    }
  }

  // 4. Sign out
  static Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut().catchError((_) => null);
      }
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}
