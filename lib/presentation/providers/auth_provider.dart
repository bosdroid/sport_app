import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository) {
    _loadUserFromSession();
  }

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<void> _loadUserFromSession() async {
    _user = await _repository.loadUserFromSession();
    notifyListeners();
  }

  Future<void> loginWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _repository.loginWithEmail(email, password);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail(String username, String email, String password) async {
    _setLoading(true);
    try {
      _user = await _repository.signUpWithEmail(username, email, password);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithGoogle() async {
    _setLoading(true);
    try {
      _user = await _repository.loginWithGoogle();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithApple() async {
    _setLoading(true);
    try {
      _user = await _repository.loginWithApple();
    } finally {
      _setLoading(false);
    }
  }


  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }

  String? validateUsernameInput(String username) {
    return _repository.validateUsernameInput(username);
  }

  String getErrorMessage(Object e) {
    return _repository.getErrorMessage(e);
  }

  String getAppleLoginErrorMessage(Object e) {
    return _repository.getAppleLoginErrorMessage(e);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
