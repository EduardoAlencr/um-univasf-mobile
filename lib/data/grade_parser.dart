import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

void _log(String msg) {
  if (kDebugMode) debugPrint('[grade_parser] $msg');
}

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

final _regexAula = RegExp(r'[A-Z]{4}\d{4}\s*-\s*\S+');
final _regexHora = RegExp(r'\b\d{2}:00:');
final _regexCodigoDisciplina = RegExp(r'[A-Z]{4}\d{4}');
// Só o "resto" da linha de uma disciplina (nome/turma/sala/situação), já
// sem o código — usado numa janela pequena (até o próximo código ou fim do
// bloco), nunca no bloco inteiro. Isso evita duas coisas que a versão
// antiga (uma regex só, com `dotAll` cobrindo o bloco inteiro) causava em
// PDFs reais onde o nome da sala quebra em várias linhas antes do código:
// disciplinas sendo engolidas pela entrada vizinha, e — o risco mais sério
// — o motor de regex testar um número enorme de combinações de onde cada
// grupo lazy começa/termina dentro de um texto grande, podendo travar o
// app por muito tempo numa grade real mais "bagunçada".
final _regexRestoDisciplina = RegExp(
  r'^\s*(.+?)\s+([A-Z0-9]{1,3})\s*-\s*(.*?)\s*(CONFIRMADA|CANCELADA|PENDENTE|AGUARDANDO.{0,20}?)\b',
  dotAll: true,
);

/// Extrai a grade de horários de um PDF do SIG@ (bytes já em memória).
/// Retorna `null` se o arquivo não tiver a estrutura esperada — nesse
/// caso o app deve só guardar/exibir o arquivo original, sem inventar
/// disciplinas ou horários.
/// Verifica rapidamente se o PDF tem algum texto extraível, sem tentar
/// montar a grade — usado só pra diferenciar, numa falha de [parsearGradePdf],
/// "este PDF é uma imagem/captura de tela" (zero texto, sem OCR não dá pra
/// ler) de "o PDF tem texto, mas não bate com o formato esperado da Grade
/// de Horário do SIG@" — mensagens de erro bem diferentes pro usuário.
Future<bool> pdfTemTextoExtraivel(Uint8List bytes) async {
  try {
    final doc = await PdfDocument.openData(bytes, sourceName: 'grade.pdf');
    if (doc.pages.isEmpty) return false;
    final texto = await doc.pages.first.loadStructuredText();
    return texto.fullText.trim().length > 30;
  } catch (_) {
    return false;
  }
}

Future<GradeParseada?> parsearGradePdf(Uint8List bytes) async {
  PdfDocument? doc;
  try {
    _log('abrindo PDF (${bytes.length} bytes)...');
    doc = await PdfDocument.openData(bytes, sourceName: 'grade.pdf');
    _log('PDF aberto, ${doc.pages.length} página(s)');
    if (doc.pages.isEmpty) return null;
    final pagina = doc.pages.first;
    _log('carregando texto estruturado da página...');
    final texto = await pagina.loadStructuredText();
    _log('texto estruturado carregado (${texto.fullText.length} chars)');

    // 1) cabeçalho dos dias -> posição X de cada coluna.
    final posDias = <String, double>{};
    for (final dia in GradeParseada.diasSemana) {
      final ocorrencias = await texto.allMatches(RegExp('\\b$dia\\b')).toList();
      if (ocorrencias.isEmpty) continue;
      posDias[dia] = ocorrencias.first.bounds.left;
    }
    _log('cabeçalho dos dias: ${posDias.length}/6 encontrados');
    if (posDias.length < 6) return null; // não é o formato esperado

    // 2) rótulos de horário -> posição Y de cada linha.
    final ocorrenciasHora = await texto.allMatches(_regexHora).toList();
    final posHoras = <String, double>{};
    for (final m in ocorrenciasHora) {
      final rotulo = m.text.substring(0, 5); // "07:00"
      posHoras.putIfAbsent(rotulo, () => m.bounds.top);
    }
    _log('rótulos de horário: ${posHoras.length} encontrados');
    if (posHoras.isEmpty) return null;
    final horasOrdenadas = posHoras.keys.toList()
      ..sort((a, b) => posHoras[b]!.compareTo(posHoras[a]!)); // maior Y = topo da página

    // 3) blocos de aula -> encaixados por (dia mais próximo em X, hora mais
    // próxima em Y, olhando de cima pra baixo).
    final grade = <String, List<String?>>{
      for (final h in horasOrdenadas) h: List<String?>.filled(6, null),
    };

    final ocorrenciasAula = await texto.allMatches(_regexAula).toList();
    _log('ocorrências de aula no grid: ${ocorrenciasAula.length}');
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

    _log('grid montado, preenchendo tabela de disciplinas...');

    // 4) tabela "Disciplinas Solicitadas" -> nome/sala por chave.
    final textoCompleto = texto.fullText;
    final inicio = textoCompleto.indexOf('Disciplinas Solicitadas');
    final fim = textoCompleto.indexOf('Equivalências Internas do Perfil');
    final blocoDisciplinas = inicio == -1
        ? textoCompleto
        : textoCompleto.substring(inicio, fim == -1 ? textoCompleto.length : fim);

    final disciplinas = <String, GradeDisciplina>{};
    final codigos = _regexCodigoDisciplina.allMatches(blocoDisciplinas).toList();
    _log('códigos de disciplina encontrados na tabela: ${codigos.length}');
    for (var i = 0; i < codigos.length; i++) {
      final codigo = codigos[i];
      final fimJanela = i + 1 < codigos.length ? codigos[i + 1].start : blocoDisciplinas.length;
      final janela = blocoDisciplinas.substring(codigo.end, fimJanela);
      final m = _regexRestoDisciplina.matchAsPrefix(janela);
      if (m == null) continue; // formato inesperado pra essa disciplina — não inventa nome/sala
      final nome = _limparEspacos(m.group(1)!);
      final turma = m.group(2)!;
      final sala = _limparEspacos(m.group(3)!);
      disciplinas['${codigo.group(0)}-$turma'] = GradeDisciplina(nome: nome, sala: sala);
    }
    if (disciplinas.isEmpty) {
      _log('nenhuma disciplina reconhecida na tabela — retornando null');
      return null;
    }

    _log('concluído: ${disciplinas.length} disciplina(s) na tabela');
    return GradeParseada(
      curso: _extrairCampo(textoCompleto, 'Curso:'),
      periodo: _extrairCampo(textoCompleto, 'Período:'),
      turno: _extrairCampo(textoCompleto, 'Turno:'),
      disciplinas: disciplinas,
      grade: grade,
    );
  } catch (e, st) {
    _log('ERRO durante o parse: $e\n$st');
    return null;
  } finally {
    await doc?.dispose();
  }
}

String? _normalizarChave(String texto) {
  final m = RegExp(r'([A-Z]{4}\d{4})\s*-\s*(\S+)').firstMatch(texto);
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
