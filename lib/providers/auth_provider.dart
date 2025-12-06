import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
    // Load user hiện tại nếu đã đăng nhập
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      if (_authService.currentUser != null) {
        _user = await _authService.getUserData(_authService.currentUser!.id);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading current user: $e');
      // Nếu lỗi, vẫn set user từ auth data
      if (_authService.currentUser != null) {
        _user = UserModel(
          uid: _authService.currentUser!.id,
          email: _authService.currentUser!.email ?? '',
          displayName: _authService.currentUser!.userMetadata?['display_name'] ?? 
                      _authService.currentUser!.email?.split('@')[0] ?? 'User',
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((AuthState state) async {
      try {
        if (state.session?.user != null) {
          _user = await _authService.getUserData(state.session!.user.id);
          // Nếu getUserData trả về null, tạo user model từ auth data
          if (_user == null) {
            _user = UserModel(
              uid: state.session!.user.id,
              email: state.session!.user.email ?? '',
              displayName: state.session!.user.userMetadata?['display_name'] ?? 
                          state.session!.user.email?.split('@')[0] ?? 'User',
              createdAt: DateTime.now(),
            );
          }
        } else {
          _user = null;
        }
        notifyListeners();
      } catch (e) {
        print('Error in auth state change: $e');
        // Nếu có lỗi nhưng vẫn có session, tạo user model từ auth data
        if (state.session?.user != null) {
          _user = UserModel(
            uid: state.session!.user.id,
            email: state.session!.user.email ?? '',
            displayName: state.session!.user.userMetadata?['display_name'] ?? 
                        state.session!.user.email?.split('@')[0] ?? 'User',
            createdAt: DateTime.now(),
          );
          notifyListeners();
        } else {
          _user = null;
          notifyListeners();
        }
      }
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_authService.currentUser != null) {
      _user = await _authService.getUserData(_authService.currentUser!.id);
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}





