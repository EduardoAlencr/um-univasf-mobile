import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'mock_data.dart';

/// URL do JSON gerado pelo scraper, publicado automaticamente pelo GitHub
/// Actions (`.github/workflows/atualizar-dados.yml`) a cada execução —
/// permite pegar dados novos sem precisar rebuildar o app.
const _urlDadosRemotos =
    'https://raw.githubusercontent.com/EduardoAlencr/um-univasf-mobile/main/assets/data/dados_univasf.json';
const _timeoutRede = Duration(seconds: 6);
const _nomeArquivoCache = 'dados_univasf_cache.json';

/// Carrega o JSON gerado pelo scraper e substitui as listas mockadas
/// (homeNotices, allNotices, ruDays, calendarEvents, ...) por dados reais.
///
/// Ordem de tentativa, cada uma só usada se a anterior falhar:
/// 1. Busca a versão mais recente via HTTP (GitHub raw) — se der certo,
///    também salva uma cópia em cache local pra próxima abertura offline.
/// 2. Cache local da última busca bem-sucedida.
/// 3. Asset embutido no APK (o JSON congelado na data do build).
///
/// Qualquer falha (rede fora, asset ausente, JSON malformado, seção vazia)
/// é ignorada silenciosamente — o app nunca quebra por causa disso.
Future<void> loadRemoteData() async {
  final raw = await _buscarJson();
  if (raw == null) return;

  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;

    dadosAtualizadosEm = DateTime.tryParse(json['gerado_em'] as String? ?? '');
    _aplicarNoticias(json['noticias_setores']);
    _aplicarEditais(json['noticias_setores']);
    _aplicarCardapio(json['ru_cardapio']);
    _aplicarCalendario(json['calendario']);
    _aplicarItinerario(json['itinerario_onibus']);
    _aplicarAvisosSiga(json['avisos_siga']);
  } catch (_) {
    // JSON malformado (de qualquer fonte) — mantém os mocks.
  }
}

Future<String?> _buscarJson() async {
  final remoto = await _buscarRemoto();
  if (remoto != null) return remoto;

  final cache = await _lerCache();
  if (cache != null) return cache;

  try {
    return await rootBundle.loadString('assets/data/dados_univasf.json');
  } catch (_) {
    return null;
  }
}

Future<String?> _buscarRemoto() async {
  try {
    final resp = await http.get(Uri.parse(_urlDadosRemotos)).timeout(_timeoutRede);
    if (resp.statusCode != 200 || resp.body.isEmpty) return null;
    jsonDecode(resp.body); // valida que é JSON íntegro antes de aceitar/cachear
    unawaited(_salvarCache(resp.body));
    return resp.body;
  } catch (_) {
    return null;
  }
}

Future<File> _arquivoCache() async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}/$_nomeArquivoCache');
}

Future<void> _salvarCache(String conteudo) async {
  try {
    final arquivo = await _arquivoCache();
    await arquivo.writeAsString(conteudo);
  } catch (_) {
    // Sem permissão de disco ou similar — segue sem cache, sem quebrar o app.
  }
}

Future<String?> _lerCache() async {
  try {
    final arquivo = await _arquivoCache();
    if (!await arquivo.exists()) return null;
    return await arquivo.readAsString();
  } catch (_) {
    return null;
  }
}

const _iconesPorSetor = {
  'PROAE': '🍽️',
  'PROEX': '📢',
  'PROEN': '🎓',
};

void _aplicarNoticias(dynamic lista) {
  if (lista is! List || lista.isEmpty) return;

  final comData = <MapEntry<Notice, DateTime?>>[];
  for (final item in lista) {
    if (item is! Map) continue;
    final setor = (item['setor'] as String?) ?? 'UNIVASF';
    final titulo = (item['titulo'] as String?)?.trim();
    if (titulo == null || titulo.isEmpty) continue;
    final data = item['data'] as String?;
    final notice = Notice(
      icon: _iconesPorSetor[setor] ?? '📰',
      iconBg: comData.length % 4,
      title: titulo,
      desc: 'Notícia oficial do setor $setor.',
      when: data != null ? '$data · coletado do site da $setor' : 'coletado do site da $setor',
      url: item['url'] as String?,
    );
    comData.add(MapEntry(notice, _parseDataBr(data)));
  }
  if (comData.isEmpty) return;

  // Mais recente primeiro; itens sem data (raro) ficam por último.
  comData.sort((a, b) {
    if (a.value == null && b.value == null) return 0;
    if (a.value == null) return 1;
    if (b.value == null) return -1;
    return b.value!.compareTo(a.value!);
  });

  final noticias = comData.map((e) => e.key).toList();
  homeNotices = noticias.take(2).toList();
  allNotices = noticias;
}

const _corPorSetor = {
  'PROAE': 'green',
  'PROEX': 'yellow',
  'PROEN': 'blue',
};

DateTime? _parseDataBr(String? data) {
  if (data == null) return null;
  final partes = data.split('/');
  if (partes.length != 3) return null;
  final d = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  final y = int.tryParse(partes[2]);
  if (d == null || m == null || y == null) return null;
  return DateTime(y, m, d);
}

void _aplicarEditais(dynamic lista) {
  if (lista is! List || lista.isEmpty) return;

  final itens = <Edital>[];
  final comData = <MapEntry<Edital, DateTime?>>[];
  for (final item in lista) {
    if (item is! Map) continue;
    final setor = (item['setor'] as String?) ?? 'UNIVASF';
    final titulo = (item['titulo'] as String?)?.trim();
    if (titulo == null || titulo.isEmpty) continue;
    final data = item['data'] as String?;
    final edital = Edital(
      setor: setor,
      setorColor: _corPorSetor[setor] ?? 'gray',
      prazo: data != null ? 'postado em $data' : 'data não informada',
      titulo: titulo,
      desc: 'Notícia oficial do setor $setor.',
      fonte: 'Coletado do site da $setor',
      url: item['url'] as String?,
    );
    comData.add(MapEntry(edital, _parseDataBr(data)));
  }
  if (comData.isEmpty) return;

  comData.sort((a, b) {
    if (a.value == null && b.value == null) return 0;
    if (a.value == null) return 1;
    if (b.value == null) return -1;
    return b.value!.compareTo(a.value!);
  });
  itens.addAll(comData.map((e) => e.key));
  editais = itens;
}

void _aplicarItinerario(dynamic dados) {
  // Tolera o formato antigo (lista de viagens direto, sem vigência/data de
  // publicação) pra nunca ficar sem nada numa janela de transição entre o
  // app novo e um JSON ainda gerado pelo scraper antigo.
  final lista = dados is List ? dados : (dados is Map ? dados['viagens'] : null);
  if (lista is! List || lista.isEmpty) return;

  final viagens = <Viagem>[];
  for (final item in lista) {
    if (item is! Map) continue;
    final letra = item['letra'] as String?;
    final turno = item['turno'] as String?;
    final rota = item['rota'] as String?;
    final paradasJson = item['paradas'];
    if (letra == null || turno == null || rota == null || paradasJson is! List) continue;

    final paradas = <Parada>[];
    for (final p in paradasJson) {
      if (p is! Map) continue;
      final horario = p['horario'] as String?;
      final local = p['local'] as String?;
      if (horario == null || local == null) continue;
      paradas.add(Parada(horario: horario, local: local));
    }
    if (paradas.isEmpty) continue;

    viagens.add(
      Viagem(
        letra: letra,
        turno: turno,
        rota: rota,
        horarioSaida: item['horario_saida'] as String?,
        paradas: paradas,
      ),
    );
  }
  if (viagens.isEmpty) return;

  onibusViagens = viagens;
  if (dados is Map) {
    itinerarioVigencia = dados['vigencia'] as String?;
    itinerarioPublicadoEm = dados['publicado_em'] as String?;
  }
}

void _aplicarCardapio(dynamic cardapio) {
  if (cardapio is! Map) return;
  final refeicoes = cardapio['refeicoes'];
  if (refeicoes is! List || refeicoes.isEmpty) return;
  final periodo = cardapio['periodo'] as String?;

  final porDia = <String, List<Meal>>{};
  for (final item in refeicoes) {
    if (item is! Map) continue;
    final dia = item['dia'] as String?;
    final periodoRefeicao = item['periodo'] as String?;
    if (dia == null || periodoRefeicao == null) continue;

    final itensJson = item['itens'];
    final itens = <ItemCardapio>[];
    if (itensJson is List) {
      for (final it in itensJson) {
        if (it is! Map) continue;
        final categoria = it['categoria'] as String?;
        final prato = it['prato'] as String?;
        if (categoria == null || prato == null || prato.isEmpty) continue;
        itens.add(ItemCardapio(categoria: categoria, prato: prato));
      }
    }
    if (itens.isEmpty) continue;

    final resumo = itens.take(2).map((i) => i.prato).join(' · ');
    porDia.putIfAbsent(dia, () => []).add(Meal(time: periodoRefeicao, what: resumo, itens: itens));
  }
  if (porDia.isEmpty) return;

  final novosDias = <RuDay>[];
  var primeiro = true;
  for (final entry in porDia.entries) {
    novosDias.add(
      RuDay(
        label: entry.key,
        badge: primeiro ? periodo : null,
        meals: entry.value,
      ),
    );
    primeiro = false;
  }
  ruDays = novosDias;
  ruLegenda = cardapio['legenda'] as String?;
}

void _aplicarCalendario(dynamic lista) {
  if (lista is! List || lista.isEmpty) return;

  final eventos = <CalendarEvent>[];
  for (final item in lista) {
    if (item is! Map) continue;
    final dia = item['dia'] as String?;
    final mes = item['mes'] as String?;
    final titulo = item['titulo'] as String?;
    if (dia == null || mes == null || titulo == null) continue;
    eventos.add(
      CalendarEvent(
        day: dia,
        month: mes,
        title: titulo.length > 70 ? '${titulo.substring(0, 67)}...' : titulo,
        desc: 'Calendário acadêmico oficial',
      ),
    );
  }
  if (eventos.isEmpty) return;

  calendarEvents = eventos.take(6).toList();
}

void _aplicarAvisosSiga(dynamic lista) {
  if (lista is! List || lista.isEmpty) return;

  final avisos = <String>[];
  for (final item in lista) {
    final texto = item is String ? item : (item is Map ? item['texto'] as String? : null);
    if (texto == null || texto.trim().isEmpty) continue;
    avisos.add(texto.trim());
  }
  if (avisos.isEmpty) return;

  sigaAvisos = avisos;
}
