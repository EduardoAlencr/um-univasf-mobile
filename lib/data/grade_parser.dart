import 'dart:typed_data';
import 'package:pdfrx/pdfrx.dart';

/// Uma disciplina identificada na tabela "Disciplinas Solicitadas" do PDF
/// do SIG@ — nome e sala(s), indexada pela chave `CCMPxxxx-TURMA`.
class GradeDisciplina {
  const GradeDisciplina({required this.nome, required this.sala});
  final String nome;
  final String sala;
}

/// Resultado da extração real da grade a partir do PDF exportado pelo
/// SIG@ (`Consultas → Grade de Horário`). Nunca é inventado: se o PDF não
/// tiver o formato esperado, [parsearGradePdf] retorna `null`.
class GradeParseada {
  const GradeParseada({
    this.curso,
    this.periodo,
    this.turno,
    required this.disciplinas,
    required this.grade,
  });

  final String? curso;
  final String? periodo;
  final String? turno;

  /// Chave `CCMPxxxx-TURMA` -> disciplina.
  final Map<String, GradeDisciplina> disciplinas;

  /// Rótulo de horário (`"07:00"`, `"08:00"`, ...) -> lista de 6 posições
  /// (Segunda..Sábado) com a chave da disciplina naquele horário, ou nulo.
  final Map<String, List<String?>> grade;

  static const diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

  bool get temAulas => grade.values.any((linha) => linha.any((c) => c != null));
}

final _regexAula = RegExp(r'CCMP\d{4}\s*-\s*\S+');
final _regexHora = RegExp(r'\b\d{2}:00:');
final _regexDisciplinaLinha = RegExp(
  r'CCMP(\d{4})\s+(.+?)\s+([A-Z0-9]{1,3})\s*-\s*(.+?)\s+(CONFIRMADA|CANCELADA|PENDENTE|AGUARDANDO[\s\S]{0,20}?)\b',
  dotAll: true,
);

/// Extrai a grade de horários de um PDF do SIG@ (bytes já em memória).
/// Retorna `null` se o arquivo não tiver a estrutura esperada — nesse
/// caso o app deve só guardar/exibir o arquivo original, sem inventar
/// disciplinas ou horários.
Future<GradeParseada?> parsearGradePdf(Uint8List bytes) async {
  PdfDocument? doc;
  try {
    doc = await PdfDocument.openData(bytes, sourceName: 'grade.pdf');
    if (doc.pages.isEmpty) return null;
    final pagina = doc.pages.first;
    final texto = await pagina.loadStructuredText();

    // 1) cabeçalho dos dias -> posição X de cada coluna.
    final posDias = <String, double>{};
    for (final dia in GradeParseada.diasSemana) {
      final ocorrencias = await texto.allMatches(RegExp('\\b$dia\\b')).toList();
      if (ocorrencias.isEmpty) continue;
      posDias[dia] = ocorrencias.first.bounds.left;
    }
    if (posDias.length < 6) return null; // não é o formato esperado

    // 2) rótulos de horário -> posição Y de cada linha.
    final ocorrenciasHora = await texto.allMatches(_regexHora).toList();
    final posHoras = <String, double>{};
    for (final m in ocorrenciasHora) {
      final rotulo = m.text.substring(0, 5); // "07:00"
      posHoras.putIfAbsent(rotulo, () => m.bounds.top);
    }
    if (posHoras.isEmpty) return null;
    final horasOrdenadas = posHoras.keys.toList()
      ..sort((a, b) => posHoras[b]!.compareTo(posHoras[a]!)); // maior Y = topo da página

    // 3) blocos de aula -> encaixados por (dia mais próximo em X, hora mais
    // próxima em Y, olhando de cima pra baixo).
    final grade = <String, List<String?>>{
      for (final h in horasOrdenadas) h: List<String?>.filled(6, null),
    };

    final ocorrenciasAula = await texto.allMatches(_regexAula).toList();
    for (final m in ocorrenciasAula) {
      final chave = _normalizarChave(m.text);
      if (chave == null) continue;

      final cx = m.bounds.left;
      String? diaMaisProximo;
      double? menorDist;
      for (final dia in GradeParseada.diasSemana) {
        final px = posDias[dia];
        if (px == null) continue;
        final dist = (cx - px).abs();
        if (menorDist == null || dist < menorDist) {
          menorDist = dist;
          diaMaisProximo = dia;
        }
      }
      if (diaMaisProximo == null) continue;
      final indiceDia = GradeParseada.diasSemana.indexOf(diaMaisProximo);

      final cy = m.bounds.top;
      String? horaEscolhida;
      for (final h in horasOrdenadas) {
        if (posHoras[h]! >= cy - 1) {
          horaEscolhida = h;
        } else {
          break;
        }
      }
      horaEscolhida ??= horasOrdenadas.last;

      grade[horaEscolhida]![indiceDia] = chave;
    }

    // 4) tabela "Disciplinas Solicitadas" -> nome/sala por chave.
    final textoCompleto = texto.fullText;
    final inicio = textoCompleto.indexOf('Disciplinas Solicitadas');
    final fim = textoCompleto.indexOf('Equivalências Internas do Perfil');
    final blocoDisciplinas = inicio == -1
        ? textoCompleto
        : textoCompleto.substring(inicio, fim == -1 ? textoCompleto.length : fim);

    final disciplinas = <String, GradeDisciplina>{};
    for (final m in _regexDisciplinaLinha.allMatches(blocoDisciplinas)) {
      final codigo = 'CCMP${m.group(1)}';
      final nome = _limparEspacos(m.group(2)!);
      final turma = m.group(3)!;
      final sala = _limparEspacos(m.group(4)!);
      disciplinas['$codigo-$turma'] = GradeDisciplina(nome: nome, sala: sala);
    }
    if (disciplinas.isEmpty) return null;

    return GradeParseada(
      curso: _extrairCampo(textoCompleto, 'Curso:'),
      periodo: _extrairCampo(textoCompleto, 'Período:'),
      turno: _extrairCampo(textoCompleto, 'Turno:'),
      disciplinas: disciplinas,
      grade: grade,
    );
  } catch (_) {
    return null;
  } finally {
    await doc?.dispose();
  }
}

String? _normalizarChave(String texto) {
  final m = RegExp(r'(CCMP\d{4})\s*-\s*(\S+)').firstMatch(texto);
  if (m == null) return null;
  return '${m.group(1)}-${m.group(2)}';
}

String _limparEspacos(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

String? _extrairCampo(String texto, String rotulo) {
  final i = texto.indexOf(rotulo);
  if (i == -1) return null;
  final resto = texto.substring(i + rotulo.length);
  final linha = resto.split('\n').first.trim();
  return linha.isEmpty ? null : linha;
}
