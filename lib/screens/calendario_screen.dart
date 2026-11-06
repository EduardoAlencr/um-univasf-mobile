import 'package:flutter/material.dart';
import '../data/calendario_pessoal.dart';
import '../data/mock_data.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../util/data_pt.dart';
import '../widgets/app_badge.dart';
import '../widgets/app_card.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/source_tag.dart';
import '../widgets/um_toast.dart';

const _headers = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']; // Seg..Dom
const _mesesAbrev = mesesAbrevPt;

String _nomeMesCapitalizado(int mes) {
  final nome = mesesNomesPt[mes - 1];
  return nome[0].toUpperCase() + nome.substring(1);
}

/// Item unificado pra exibição — vem do calendário acadêmico público ou de
/// um evento pessoal do usuário (`isPessoal`), que também carrega o id do
/// documento no Firestore pra permitir excluir.
class _ItemCalendario {
  const _ItemCalendario({
    required this.dia,
    required this.mes,
    required this.titulo,
    required this.desc,
    required this.isPessoal,
    this.idPessoal,
    this.tag = 'outro',
    this.diaFim,
    this.mesFim,
  });
  final int dia;
  final String mes; // abreviação, ex. "Set"
  final String titulo;
  final String desc;
  final bool isPessoal;
  final String? idPessoal;

  /// 'feriado' | 'recesso' | 'matricula' | 'avaliacao' | 'outro' — eventos
  /// pessoais não usam isso pra cor (sempre amarelo), só os oficiais.
  final String tag;

  /// Último dia de um intervalo (ex. evento "15 a 22"), ou nulo se for um
  /// único dia.
  final int? diaFim;

  /// Mês do fim do intervalo, só quando diferente do mês de início (ex.
  /// "18 de Novembro a 11 de Dezembro") — nulo quando o intervalo fica
  /// dentro do mesmo mês.
  final String? mesFim;
}

// Só usado como selo pequeno (mesmo padrão do AppBadge já usado em todo o
// app) pra diferenciar a categoria — a grade e os destaques do mês
// continuam só azul (oficial) / amarelo (pessoal), igual ao resto do app,
// pra não destoar da paleta contida que o app já usa em todo o resto.
const _corPorTag = {
  'feriado': BadgeColor.red,
  'recesso': BadgeColor.orange,
  'matricula': BadgeColor.blue,
  'avaliacao': BadgeColor.green,
  'outro': BadgeColor.gray,
};

const _rotuloPorTag = {
  'feriado': 'Feriado',
  'recesso': 'Recesso',
  'matricula': 'Matrícula',
  'avaliacao': 'Avaliação',
  'outro': 'Calendário',
};

BadgeColor _corDoTag(String tag) => _corPorTag[tag] ?? BadgeColor.gray;

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  late DateTime _mesExibido;
  final _hoje = DateTime.now();

  @override
  void initState() {
    super.initState();
    _mesExibido = DateTime(_hoje.year, _hoje.month);
  }

  void _mudarMes(int delta) {
    setState(() => _mesExibido = DateTime(_mesExibido.year, _mesExibido.month + delta));
  }

  Future<void> _adicionarEvento(String uid, {DateTime? dataInicial}) async {
    final tituloCtrl = TextEditingController();
    var dataEscolhida = dataInicial ?? DateTime(_mesExibido.year, _mesExibido.month, _hoje.day);

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Novo lembrete', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                TextField(
                  controller: tituloCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Ex.: Entrega do TCC',
                    filled: true,
                    fillColor: AppColors.canvas,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final escolhida = await showDatePicker(
                      context: ctx,
                      initialDate: dataEscolhida,
                      firstDate: DateTime(_hoje.year - 1),
                      lastDate: DateTime(_hoje.year + 3),
                    );
                    if (escolhida != null) setDialogState(() => dataEscolhida = escolhida);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.blueDark),
                        const SizedBox(width: 8),
                        Text(
                          '${dataEscolhida.day.toString().padLeft(2, '0')}/${dataEscolhida.month.toString().padLeft(2, '0')}/${dataEscolhida.year}',
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar', style: TextStyle(color: AppColors.ink2, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmou != true || tituloCtrl.text.trim().isEmpty) return;
    try {
      await adicionarEventoPessoal(uid, titulo: tituloCtrl.text.trim(), data: dataEscolhida);
      if (mounted) showUmToast(context, 'Lembrete adicionado ao seu calendário.');
    } catch (_) {
      if (mounted) showUmToast(context, 'Não foi possível salvar o lembrete agora. Tente de novo.');
    }
  }

  Future<void> _removerEvento(String uid, _ItemCalendario item) async {
    final confirmou = await showConfirmDialog(
      context,
      title: 'Excluir este lembrete?',
      message: '"${item.titulo}" será removido do seu calendário pessoal.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmou || item.idPessoal == null) return;
    try {
      await removerEventoPessoal(uid, item.idPessoal!);
      if (mounted) showUmToast(context, 'Lembrete excluído.');
    } catch (_) {
      if (mounted) showUmToast(context, 'Não foi possível excluir o lembrete agora. Tente de novo.');
    }
  }

  void _mostrarDetalhe(BuildContext context, _ItemCalendario item) {
    // Azul/amarelo (oficial/pessoal), igual ao resto do app — a categoria
    // (feriado/recesso/matrícula/avaliação) vira só um selo pequeno dentro
    // do conteúdo, não a cor principal do diálogo.
    final soft = item.isPessoal ? AppColors.yellowSoft : AppColors.blueSoft;
    final texto = item.isPessoal ? AppColors.yellowText : AppColors.blueDark;
    final periodo = item.diaFim == null || (item.diaFim == item.dia && item.mesFim == null)
        ? '${item.dia} de ${item.mes}'
        : item.mesFim != null
            ? '${item.dia} de ${item.mes} a ${item.diaFim} de ${item.mesFim}'
            : '${item.dia} a ${item.diaFim} de ${item.mes}';

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Text(periodo.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: texto, letterSpacing: 0.8)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge(
                    label: item.isPessoal ? 'Lembrete pessoal' : (_rotuloPorTag[item.tag] ?? 'Calendário'),
                    color: item.isPessoal ? BadgeColor.yellow : _corDoTag(item.tag),
                  ),
                  const SizedBox(height: 10),
                  Text(item.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.35)),
                  const SizedBox(height: 10),
                  Text(item.desc, style: const TextStyle(fontSize: 13, color: AppColors.ink2, height: 1.5)),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Fechar', style: TextStyle(color: AppColors.blueDark, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthScope.of(context).user?.uid;

    return StreamBuilder<List<EventoPessoal>>(
      stream: uid == null ? const Stream.empty() : streamEventosPessoais(uid),
      builder: (context, snapshot) {
        final pessoais = snapshot.data ?? const [];
        return _buildConteudo(context, uid, pessoais);
      },
    );
  }

  Widget _buildConteudo(BuildContext context, String? uid, List<EventoPessoal> pessoais) {
    final abrevMes = _mesesAbrev[_mesExibido.month - 1];

    final itensPublicos = calendarEvents.map(
      (e) => _ItemCalendario(
        dia: int.tryParse(e.day) ?? 0,
        mes: e.month,
        titulo: e.title,
        desc: e.desc,
        isPessoal: false,
        tag: e.tag,
        diaFim: e.dayEnd != null ? int.tryParse(e.dayEnd!) : null,
        mesFim: e.monthEnd,
      ),
    );
    final itensPessoais = pessoais.map(
      (e) => _ItemCalendario(
        dia: e.data.day,
        mes: _mesesAbrev[e.data.month - 1],
        titulo: e.titulo,
        desc: 'Lembrete pessoal',
        isPessoal: true,
        idPessoal: e.id,
      ),
    );
    final todosItens = [...itensPublicos, ...itensPessoais];

    final primeiroDoMes = DateTime(_mesExibido.year, _mesExibido.month, 1);
    final diasNoMes = DateTime(_mesExibido.year, _mesExibido.month + 1, 0).day;
    final offsetInicial = primeiroDoMes.weekday - 1; // 0=Seg

    // Tag de cada dia do mês com evento oficial — eventos com intervalo
    // (ex. "15 a 22") tingem todos os dias do intervalo, não só o inicial.
    // Quando o intervalo atravessa pro mês seguinte (mesFim != null),
    // tinge até o fim do mês exibido (se for o mês de início) ou desde o
    // dia 1 (se for o mês de fim) — nunca assume que o fim é no mesmo mês.
    final tagPorDia = <int, String>{};
    for (final e in itensPublicos) {
      final mesInicioBate = e.mes.toLowerCase() == abrevMes.toLowerCase();
      final mesFimBate = e.mesFim?.toLowerCase() == abrevMes.toLowerCase();
      if (e.dia == 0 || (!mesInicioBate && !mesFimBate)) continue;

      int inicio, fim;
      if (mesInicioBate && (e.mesFim == null || e.mesFim!.toLowerCase() == abrevMes.toLowerCase())) {
        inicio = e.dia;
        fim = (e.diaFim != null && e.diaFim! >= e.dia) ? e.diaFim! : e.dia;
      } else if (mesInicioBate) {
        inicio = e.dia; // intervalo continua no mês seguinte
        fim = diasNoMes;
      } else {
        inicio = 1; // mês de chegada de um intervalo iniciado no mês anterior
        fim = e.diaFim ?? 1;
      }
      for (var d = inicio; d <= fim; d++) {
        tagPorDia.putIfAbsent(d, () => e.tag);
      }
    }
    final diasPessoais = <int>{
      for (final e in itensPessoais)
        if (e.mes.toLowerCase() == abrevMes.toLowerCase()) e.dia,
    }..remove(0);
    final eventosDoMes = todosItens.where((e) => e.mes.toLowerCase() == abrevMes.toLowerCase()).toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));
    final totalCelulas = ((offsetInicial + diasNoMes + 6) ~/ 7) * 7;

    final hojeSemHora = DateTime(_hoje.year, _hoje.month, _hoje.day);
    EventoPessoal? proximoLembrete;
    for (final e in pessoais) {
      if (DateTime(e.data.year, e.data.month, e.data.day).isBefore(hojeSemHora)) continue;
      proximoLembrete = e;
      break; // streamEventosPessoais já vem ordenado por data
    }

    final conteudo = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendário Acadêmico', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('Semestre 2026.2 · azul = oficial, amarelo = seus lembretes', style: TextStyle(fontSize: 12.5, color: AppColors.ink2)),
          if (proximoLembrete != null) ...[
            const SizedBox(height: 14),
            _LembreteDestaque(evento: proximoLembrete, hoje: _hoje),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MonthNavButton(icon: '‹', onTap: () => _mudarMes(-1)),
              Text(
                '${_nomeMesCapitalizado(_mesExibido.month)} ${_mesExibido.year}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              _MonthNavButton(icon: '›', onTap: () => _mudarMes(1)),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
            children: [
              for (final h in _headers)
                Center(
                  child: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.ink2)),
                ),
              for (int i = 0; i < totalCelulas; i++)
                if (i < offsetInicial || i >= offsetInicial + diasNoMes)
                  const SizedBox.shrink()
                else
                  _DayCell(
                    day: i - offsetInicial + 1,
                    isToday: _mesExibido.year == _hoje.year && _mesExibido.month == _hoje.month && (i - offsetInicial + 1) == _hoje.day,
                    tag: tagPorDia[i - offsetInicial + 1],
                    isPessoal: diasPessoais.contains(i - offsetInicial + 1),
                    onTap: uid == null
                        ? null
                        : () => _adicionarEvento(
                              uid,
                              dataInicial: DateTime(_mesExibido.year, _mesExibido.month, i - offsetInicial + 1),
                            ),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                if (eventosDoMes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Nenhum evento neste mês.', style: TextStyle(fontSize: 12.5, color: AppColors.ink2)),
                  ),
                for (final e in eventosDoMes)
                  GestureDetector(
                    onTap: () => _mostrarDetalhe(context, e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              gradient: e.isPessoal ? null : AppColors.gradient,
                              color: e.isPessoal ? AppColors.yellow : null,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${e.dia}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: e.isPessoal ? AppColors.ink : Colors.white),
                                ),
                                Text(
                                  e.diaFim == null || (e.diaFim == e.dia && e.mesFim == null)
                                      ? e.mes.toUpperCase()
                                      : e.mesFim != null
                                          ? 'ATÉ ${e.diaFim}/${e.mesFim!.toUpperCase()}'
                                          : 'ATÉ ${e.diaFim}',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: e.isPessoal ? AppColors.ink : Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                AppBadge(label: e.isPessoal ? 'Lembrete pessoal' : (_rotuloPorTag[e.tag] ?? 'Calendário'), color: e.isPessoal ? BadgeColor.yellow : _corDoTag(e.tag)),
                              ],
                            ),
                          ),
                          if (e.isPessoal && uid != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.ink2),
                              onPressed: () => _removerEvento(uid, e),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SourceTag(text: 'Público: atualizado automaticamente · site oficial da UNIVASF', topPadding: 10),
              ],
            ),
          ),
        ],
      ),
    );

    if (uid == null) return conteudo;

    return Stack(
      children: [
        conteudo,
        Positioned(
          right: 20,
          bottom: 90,
          child: _NovoLembreteFab(onTap: () => _adicionarEvento(uid)),
        ),
      ],
    );
  }
}

class _LembreteDestaque extends StatelessWidget {
  const _LembreteDestaque({required this.evento, required this.hoje});
  final EventoPessoal evento;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: [
          BoxShadow(color: AppColors.yellow.withValues(alpha: 0.45), blurRadius: 28, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              'SEU PRÓXIMO LEMBRETE · ${descreverPrazo(evento.data, hoje).toUpperCase()}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 10),
          Text(evento.titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(
            formatarDataCompleta(evento.data),
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _NovoLembreteFab extends StatelessWidget {
  const _NovoLembreteFab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.yellow,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: AppColors.ink, size: 20),
              SizedBox(width: 8),
              Text(
                'Adicionar lembrete',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthNavButton extends StatelessWidget {
  const _MonthNavButton({required this.icon, required this.onTap});
  final String icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blueSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.blueDark)),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isToday, this.tag, this.isPessoal = false, this.onTap});
  final int day;
  final bool isToday;

  /// Tag do evento oficial nesse dia ('feriado'/'recesso'/'matricula'/
  /// 'avaliacao'/'outro'), ou nulo se não há evento oficial nesse dia.
  final String? tag;
  final bool isPessoal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.card;
    Color fg = AppColors.ink;
    Gradient? gradient;
    List<BoxShadow>? shadow = [
      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
    ];
    FontWeight weight = FontWeight.normal;

    if (isToday) {
      gradient = AppColors.gradient;
      fg = Colors.white;
      weight = FontWeight.w900;
      shadow = null;
    } else if (isPessoal) {
      bg = AppColors.yellowSoft;
      fg = AppColors.yellowText;
      weight = FontWeight.w800;
    } else if (tag != null) {
      // Sempre azul pra qualquer evento oficial, igual ao resto do app —
      // a categoria (feriado/recesso/matrícula/avaliação) só aparece como
      // selo na lista e no diálogo de detalhe, não tingindo a grade inteira.
      bg = AppColors.blueSoft;
      fg = AppColors.blueDark;
      weight = FontWeight.w800;
    }

    return Material(
      color: gradient == null ? bg : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: shadow,
          ),
          alignment: Alignment.center,
          child: Text('$day', style: TextStyle(fontSize: 12.5, color: fg, fontWeight: weight)),
        ),
      ),
    );
  }
}
