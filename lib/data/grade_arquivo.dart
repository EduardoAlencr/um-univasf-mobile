import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'grade_parser.dart';

/// O PDF/imagem da grade que o usuário enviou, guardado como base64 direto
/// no documento do Firestore (sem precisar do Firebase Storage, que hoje
/// exige plano pago mesmo dentro da faixa gratuita) — por isso o limite de
/// tamanho: um documento do Firestore não passa de 1 MiB.
class GradeArquivo {
  const GradeArquivo({
    required this.nomeArquivo,
    required this.mimeType,
    required this.bytes,
    required this.enviadoEm,
    this.parseada,
  });

  final String nomeArquivo;
  final String mimeType;
  final Uint8List bytes;
  final DateTime enviadoEm;

  /// A grade extraída automaticamente do PDF, se o formato foi reconhecido.
  final GradeParseada? parseada;
}

/// ~700KB de arquivo original — sobra margem pro overhead de ~33% do
/// base64 não estourar o limite de 1 MiB do documento.
const limiteBytesGrade = 700 * 1024;

DocumentReference<Map<String, dynamic>> _doc(String uid) => FirebaseFirestore.instance.collection('users').doc(uid);

Future<void> salvarGradeArquivo(
  String uid, {
  required String nomeArquivo,
  required String mimeType,
  required Uint8List bytes,
  GradeParseada? parseada,
}) {
  return _doc(uid).set({
    'hasGrade': true,
    'gradeArquivo': {
      'nomeArquivo': nomeArquivo,
      'mimeType': mimeType,
      'base64': base64Encode(bytes),
      'enviadoEm': Timestamp.now(),
      'parseada': parseada == null ? null : _serializarGradeParseada(parseada),
    },
  }, SetOptions(merge: true));
}

Future<GradeArquivo?> lerGradeArquivo(String uid) async {
  final snap = await _doc(uid).get();
  final dados = snap.data()?['gradeArquivo'] as Map<String, dynamic>?;
  if (dados == null) return null;
  return GradeArquivo(
    nomeArquivo: dados['nomeArquivo'] as String? ?? 'grade',
    mimeType: dados['mimeType'] as String? ?? 'application/pdf',
    bytes: base64Decode(dados['base64'] as String? ?? ''),
    enviadoEm: (dados['enviadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    parseada: _desserializarGradeParseada(dados['parseada'] as Map<String, dynamic>?),
  );
}

Future<void> excluirGradeArquivo(String uid) {
  return _doc(uid).set({
    'hasGrade': false,
    'gradeArquivo': FieldValue.delete(),
  }, SetOptions(merge: true));
}

Map<String, dynamic> _serializarGradeParseada(GradeParseada g) {
  return {
    'curso': g.curso,
    'periodo': g.periodo,
    'turno': g.turno,
    'disciplinas': g.disciplinas.map((chave, d) => MapEntry(chave, {'nome': d.nome, 'sala': d.sala})),
    'grade': g.grade.map((hora, linha) => MapEntry(hora, linha)),
  };
}

GradeParseada? _desserializarGradeParseada(Map<String, dynamic>? dados) {
  if (dados == null) return null;
  final disciplinasRaw = dados['disciplinas'] as Map<String, dynamic>? ?? {};
  final disciplinas = disciplinasRaw.map(
    (chave, valor) {
      final m = valor as Map<String, dynamic>;
      return MapEntry(chave, GradeDisciplina(nome: m['nome'] as String? ?? '', sala: m['sala'] as String? ?? ''));
    },
  );
  final gradeRaw = dados['grade'] as Map<String, dynamic>? ?? {};
  final grade = gradeRaw.map(
    (hora, linha) => MapEntry(hora, (linha as List<dynamic>).map((c) => c as String?).toList()),
  );
  return GradeParseada(
    curso: dados['curso'] as String?,
    periodo: dados['periodo'] as String?,
    turno: dados['turno'] as String?,
    disciplinas: disciplinas,
    grade: grade,
  );
}
