import 'package:cloud_firestore/cloud_firestore.dart';

/// Um lembrete/evento pessoal do usuário, salvo em
/// `users/{uid}/calendarioPessoal/{id}` — visível apenas para quem criou
/// (garantido pelas regras de segurança do Firestore, não só pela UI).
class EventoPessoal {
  const EventoPessoal({required this.id, required this.titulo, required this.data});

  final String id;
  final String titulo;
  final DateTime data;
}

CollectionReference<Map<String, dynamic>> _colecao(String uid) =>
    FirebaseFirestore.instance.collection('users').doc(uid).collection('calendarioPessoal');

Stream<List<EventoPessoal>> streamEventosPessoais(String uid) {
  return _colecao(uid).orderBy('data').snapshots().map(
        (snap) => snap.docs.map((doc) {
          final data = doc.data();
          return EventoPessoal(
            id: doc.id,
            titulo: data['titulo'] as String? ?? '',
            data: (data['data'] as Timestamp).toDate(),
          );
        }).toList(),
      );
}

Future<void> adicionarEventoPessoal(String uid, {required String titulo, required DateTime data}) {
  return _colecao(uid).add({'titulo': titulo, 'data': Timestamp.fromDate(data)});
}

Future<void> removerEventoPessoal(String uid, String id) {
  return _colecao(uid).doc(id).delete();
}
