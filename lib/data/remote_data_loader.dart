import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'mock_data.dart';

/// Carrega o JSON gerado pelo scraper (`scraper/run.py`), empacotado como
/// asset em `assets/data/dados_univasf.json`, e substitui as listas mockadas
/// (homeNotices, allNotices, ruDays, calendarEvents) por dados reais.
///
/// Qualquer falha (asset ausente, JSON malformado, seção vazia) é ignorada
/// silenciosamente e a seção correspondente continua com os dados mockados
/// originais — o app nunca quebra por causa disso.
Future<void> loadRemoteData() async {
  try {
    final raw = await rootBundle.loadString('assets/data/dados_univasf.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    _aplicarNoticias(json['noticias_setores']);
    _aplicarEditais(json['noticias_setores']);
    _aplicarCardapio(json['ru_cardapio']);
    _aplicarCalendario(json['calendario']);
    _aplicarItinerario(json['itinerario_onibus']);
    _aplicarAvisosSiga(json['avisos_siga']);
  } catch (_) {
    // Sem asset ainda, ou scraper não rodou — mantém os mocks.
  }
}

const _iconesPorSetor = {
  'PROAE': '🍽️',
  'PROEX': '📢',
  'PROEN': '🎓',
};

void _aplicarNoticias(dynamic lista) {
  if (lista is! List || lista.isEmpty) return;

  final noticias = <Notice>[];
  for (final item in lista) {
    if (item is! Map) continue;
    final setor = (item['setor'] as String?) ?? 'UNIVASF';
    final titulo = (item['titulo'] as String?)?.trim();
    if (titulo == null || titulo.isEmpty) continue;
    final data = item['data'] as String?;
    noticias.add(
      Notice(
        icon: _iconesPorSetor[setor] ?? '📰',
        iconBg: noticias.length % 4,
        title: titulo,
        desc: 'Notícia oficial do setor $setor.',
        when: data != null ? '$data · coletado do site da $setor' : 'coletado do site da $setor',
        url: item['url'] as String?,
      ),
    );
  }
  if (noticias.isEmpty) return;

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

void _aplicarItinerario(dynamic lista) {
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
    final descricao = item['descricao'] as String?;
    if (dia == null || periodoRefeicao == null || descricao == null) continue;
    porDia.putIfAbsent(dia, () => []).add(Meal(time: periodoRefeicao, what: descricao));
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
