import 'package:flutter/material.dart';
import '../data/calendario_pessoal.dart';
import '../data/mock_data.dart';
import '../state/auth_scope.dart';
import '../theme/app_theme.dart';
import '../util/data_pt.dart';
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
  });
  final int dia;
  final String mes; // abreviação, ex. "Set"
  final String titulo;
  final String desc;
  final bool isPessoal;
  final String? idPessoal;
}

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

  Future<void> _adicionarEvento(String uid) async {
    final tituloCtrl = TextEditingController();
    var dataEscolhida = DateTime(_mesExibido.year, _mesExibido.month, _hoje.day);

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
    await adicionarEventoPessoal(uid, titulo: tituloCtrl.text.trim(), data: dataEscolhida);
    if (mounted) showUmToast(context, 'Lembrete adicionado ao seu calendário.');
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
    await removerEventoPessoal(uid, item.idPessoal!);
    if (mounted) showUmToast(context, 'Lembrete excluído.');
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
      (e) => _ItemCalendario(dia: int.tryParse(e.day) ?? 0, mes: e.month, titulo: e.title, desc: e.desc, isPessoal: false),
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

    final diasComEvento = <int>{
      for (final e in todosItens)
        if (e.mes.toLowerCase() == abrevMes.toLowerCase()) e.dia,
    }..remove(0);
    final eventosDoMes = todosItens.where((e) => e.mes.toLowerCase() == abrevMes.toLowerCase()).toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));

    final primeiroDoMes = DateTime(_mesExibido.year, _mesExibido.month, 1);
    final diasNoMes = DateTime(_mesExibido.year, _mesExibido.month + 1, 0).day;
    final offsetInicial = primeiroDoMes.weekday - 1; // 0=Seg
    final totalCelulas = ((offsetInicial + diasNoMes + 6) ~/ 7) * 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calendário Acadêmico', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    const Text('Semestre 2026.2 · azul = oficial, amarelo = seus lembretes', style: TextStyle(fontSize: 12.5, color: AppColors.ink2)),
                  ],
                ),
              ),
              if (uid != null)
                Material(
                  color: AppColors.blue,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _adicionarEvento(uid),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
            ],
          ),
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
                    hasEvent: diasComEvento.contains(i - offsetInicial + 1),
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
                  Container(
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
                                e.mes.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: e.isPessoal ? AppColors.ink : Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(e.desc, style: const TextStyle(fontSize: 11.5, color: AppColors.ink2)),
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
                const SourceTag(text: 'Público: atualizado automaticamente · site oficial da UNIVASF', topPadding: 10),
              ],
            ),
          ),
        ],
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
  const _DayCell({required this.day, required this.isToday, required this.hasEvent});
  final int day;
  final bool isToday;
  final bool hasEvent;

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
    } else if (hasEvent) {
      bg = AppColors.blueSoft;
      fg = AppColors.blueDark;
      weight = FontWeight.w800;
    }

    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadow,
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('$day', style: TextStyle(fontSize: 12.5, color: fg, fontWeight: weight)),
          if (hasEvent)
            Positioned(
              bottom: 5,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: isToday ? Colors.white : AppColors.blue, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
