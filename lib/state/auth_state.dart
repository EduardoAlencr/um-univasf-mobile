import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado de sessão do usuário. Login/cadastro usam o Firebase Auth de
/// verdade (persistência entre aberturas já vem de graça do SDK); só a
/// flag "não mostrar novamente" da tela de boas-vindas continua puramente
/// local (shared_preferences), por não ter relação nenhuma com a conta.
class AuthState extends ChangeNotifier {
  static const _keyWelcomeDismissed = 'welcomeDismissed';

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? _user;
  bool _hasGrade = false;
  bool _ready = false;
  bool _welcomeDismissed = false;

  bool get loggedIn => _user != null;
  User? get user => _user;
  bool get hasGrade => _hasGrade;
  bool get ready => _ready;
  bool get welcomeDismissed => _welcomeDismissed;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _welcomeDismissed = prefs.getBool(_keyWelcomeDismissed) ?? false;

    _auth.authStateChanges().listen((user) async {
      _user = user;
      _hasGrade = user == null ? false : await _lerHasGrade(user.uid);
      notifyListeners();
    });

    _user = _auth.currentUser;
    if (_user != null) {
      _hasGrade = await _lerHasGrade(_user!.uid);
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> dismissWelcome() async {
    _welcomeDismissed = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWelcomeDismissed, true);
  }

  /// Lança [FirebaseAuthException] em caso de falha (e-mail/senha inválidos,
  /// usuário não encontrado, etc.) — a tela de login trata e mostra a
  /// mensagem certa pro usuário.
  Future<void> login(String email, String senha) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: senha);
  }

  /// Cria a conta e um documento de perfil em `users/{uid}` com os dados
  /// informados (nome, curso, período) — separado do Firebase Auth, que só
  /// guarda e-mail/senha/displayName.
  Future<void> cadastrar({
    required String email,
    required String senha,
    required String nome,
    required String curso,
    required String periodo,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: senha);
    await credencial.user?.updateDisplayName(nome);
    final uid = credencial.user?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).set({
        'nome': nome,
        'email': email.trim(),
        'curso': curso,
        'periodo': periodo,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Atualiza o nome do usuário (Firebase Auth + Firestore) e notifica a UI
  /// na hora, sem precisar reabrir o app.
  Future<void> atualizarNome(String novoNome) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(novoNome);
    await user.reload();
    _user = _auth.currentUser;
    notifyListeners();
    await _db.collection('users').doc(user.uid).set({'nome': novoNome}, SetOptions(merge: true));
  }

  Future<void> setHasGrade(bool value) async {
    _hasGrade = value;
    notifyListeners();
    final uid = _user?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({'hasGrade': value}, SetOptions(merge: true));
  }

  Future<bool> _lerHasGrade(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['hasGrade'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}
