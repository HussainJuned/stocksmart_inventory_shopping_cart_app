import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isGuest = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null || _isGuest;
  bool get isGuest => _isGuest;

  FirebaseAuth? get _auth {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance;
  }

  AuthProvider() {
    if (Firebase.apps.isNotEmpty) {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      });
    }
  }

  Future<void> signIn(String email, String password) async {
    if (_auth == null) {
      throw Exception(
        "Firebase not initialized. configure it or use Guest Mode.",
      );
    }
    try {
      await _auth!.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String restaurantName) async {
    if (_auth == null) {
      throw Exception(
        "Firebase not initialized. configure it or use Guest Mode.",
      );
    }

    // Wipe any existing local data left behind by other users or guest mode 
    // when a new account is registered to ensure a fresh start.
    // Done BEFORE creating the user to avoid race condition with authStateChanges
    await HiveService().clearAll();

    try {
      final userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update the user's profile with the restaurant name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(restaurantName);
        // Refresh the user object locally
        await userCredential.user!.reload();
        _user = _auth!.currentUser;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRestaurantName(String newName) async {
    if (_user != null) {
      await _user!.updateDisplayName(newName);
      await _user!.reload();
      _user = _auth!.currentUser;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isGuest) {
      _isGuest = false;
      await HiveService().clearAll();
      notifyListeners();
      return;
    }
    await HiveService().clearAll();
    await _auth?.signOut();
  }

  void loginAsGuest() {
    _isGuest = true;
    notifyListeners();
  }
}
