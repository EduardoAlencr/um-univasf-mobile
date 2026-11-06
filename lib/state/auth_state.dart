import 'dart:async';
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
  // Nunca deixa uma chamada ao Firestore ficar pendurada em silêncio (ex.
  // instabilidade de rede, ou — como já aconteceu — a cota diária do
  // projeto esgotada fazendo o SDK tentar de novo sem nunca completar).
  static const _timeoutFirestore = Duration(seconds: 20);

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
      }).timeout(_timeoutFirestore);
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
    await _db.collection('users').doc(user.uid).set({'nome': novoNome}, SetOptions(merge: true)).timeout(_timeoutFirestore);
  }

  /// Só atualiza o estado local, pra UI reagir na hora sem esperar outra
  /// ida ao Firestore — `gradeArquivo` (gravado/apagado por
  /// `salvarGradeArquivo`/`excluirGradeArquivo`) é a única fonte de
  /// verdade real; não existe mais um campo `hasGrade` separado pra
  /// manter sincronizado (era exatamente isso que podia dessincronizar:
  /// duas escritas pro mesmo fato, cada uma podendo falhar/atrasar
  /// independente da outra).
  void setHasGrade(bool value) {
    _hasGrade = value;
    notifyListeners();
  }

  /// Apaga de verdade os dados pessoais do usuário: a subcoleção de
  /// lembretes do calendário pessoal (Firestore não apaga subcoleções em
  /// cascata ao apagar o documento pai, então cada item precisa ser
  /// removido individualmente), o documento `users/{uid}` (grade enviada,
  /// nome, curso, período) e, por fim, a própria conta no Firebase Auth.
  ///
  /// A exclusão da conta pode falhar com `requires-recent-login` (exigência
  /// de segurança do Firebase para ações sensíveis) — nesse caso os dados já
  /// foram apagados, mas a conta em si permanece até o usuário entrar de
  /// novo e tentar excluir outra vez. Retorna uma mensagem que descreve
  /// exatamente o que aconteceu, pra UI nunca prometer mais do que o que
  /// realmente foi feito.
  Future<String> excluirDadosEConta() async {
    final user = _auth.currentUser;
    if (user == null) return 'Nenhuma conta ativa.';
    final uid = user.uid;

    try {
      final lembretes = await _db
          .collection('users')
          .doc(uid)
          .collection('calendarioPessoal')
          .get()
          .timeout(_timeoutFirestore);
      final batch = _db.batch();
      for (final doc in lembretes.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_db.collection('users').doc(uid));
      await batch.commit().timeout(_timeoutFirestore);
    } catch (e) {
      // Nunca deixa a chamada travar/falhar em silêncio — sem isso, uma
      // falha aqui (ex. timeout por instabilidade do Firestore) não dava
      // nenhum retorno pra UI, parecendo que o botão simplesmente não fez
      // nada (nem excluiu, nem deslogou, nem avisou).
      return e is TimeoutException
          ? 'Não foi possível excluir seus dados agora (conexão instável). Nada foi apagado — tente de novo em instantes.'
          : 'Não foi possível excluir seus dados agora. Nada foi apagado — tente de novo em instantes.';
    }

    try {
      await user.delete().timeout(_timeoutFirestore);
      return 'Seus dados e sua conta foram excluídos.';
    } on FirebaseAuthException catch (e) {
      await _auth.signOut();
      if (e.code == 'requires-recent-login') {
        return 'Seus dados foram excluídos. Por segurança, entre novamente e repita a exclusão pra remover também a conta.';
      }
      return 'Seus dados foram excluídos, mas não foi possível excluir a conta agora (${e.code}).';
    } catch (e) {
      // Dados já foram apagados nesse ponto (passou do bloco acima) — só a
      // exclusão da conta em si que não terminou a tempo.
      await _auth.signOut();
      return 'Seus dados foram excluídos, mas não foi possível excluir a conta agora (conexão instável). Entre novamente e repita a exclusão.';
    }
  }

  /// Deduz se há grade enviada direto da presença de `gradeArquivo` no
  /// documento — não lê mais um campo `hasGrade` separado (ver comentário
  /// em `setHasGrade`).
  Future<bool> _lerHasGrade(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get().timeout(_timeoutFirestore);
      final temGrade = doc.data()?['gradeArquivo'] != null;
      if (kDebugMode) debugPrint('[auth_state] _lerHasGrade($uid) -> gradeArquivo presente: $temGrade');
      return temGrade;
    } catch (_) {
      return false;
    }
  }
}
