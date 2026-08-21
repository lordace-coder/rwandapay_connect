import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/account.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  Account? _currentAccount;
  String? _loginError;
  bool _loggingIn = false;

  AppUser? get currentUser => _currentUser;
  Account? get currentAccount => _currentAccount;
  String? get loginError => _loginError;
  bool get loggingIn => _loggingIn;
  bool get isLoggedIn => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _loginError = null;
    _loggingIn = true;
    notifyListeners();

    try {
      final user = await SupabaseService.authenticateUser(email, password);
      if (user != null) {
        _currentUser = user;
        _currentAccount = await SupabaseService.getAccountByUserId(user.id);
        _loggingIn = false;
        notifyListeners();
        return true;
      }
      _loginError = 'Invalid email or password';
    } catch (e) {
      _loginError = 'Could not reach the server. Check your connection.';
      debugPrint('Login failed: $e');
    }

    _loggingIn = false;
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    _currentAccount = null;
    _loginError = null;
    notifyListeners();
  }

  Future<void> refreshAccount() async {
    if (_currentUser == null) return;
    try {
      _currentAccount = await SupabaseService.getAccountByUserId(_currentUser!.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh account: $e');
    }
  }
}
