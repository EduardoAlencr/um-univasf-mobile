import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado de sessão do usuário, persistido localmente (shared_preferences)
/// para que login e envio da grade sobrevivam ao fechar o app.
class AuthState extends ChangeNotifier {
  static const _keyLoggedIn = 'loggedIn';
  static const _keyHasGrade = 'hasGrade';
  static const _keyWelcomeDismissed = 'welcomeDismissed';

  bool _loggedIn = false;
  bool _hasGrade = false;
  bool _ready = false;
  bool _welcomeDismissed = false;

  bool get loggedIn => _loggedIn;
  bool get hasGrade => _hasGrade;
  bool get ready => _ready;
  bool get welcomeDismissed => _welcomeDismissed;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _hasGrade = _loggedIn && (prefs.getBool(_keyHasGrade) ?? false);
    _welcomeDismissed = prefs.getBool(_keyWelcomeDismissed) ?? false;
    _ready = true;
    notifyListeners();
  }

  Future<void> dismissWelcome() async {
    _welcomeDismissed = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWelcomeDismissed, true);
  }

  Future<void> login() async {
    _loggedIn = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
  }

  Future<void> logout() async {
    _loggedIn = false;
    _hasGrade = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
    await prefs.setBool(_keyHasGrade, false);
  }

  Future<void> setHasGrade(bool value) async {
    _hasGrade = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasGrade, value);
  }
}
