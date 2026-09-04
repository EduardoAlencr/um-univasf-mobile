import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../util/data_pt.dart';
import '../widgets/app_card.dart';
import '../widgets/source_tag.dart';

const _headers = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D']; // Seg..Dom
const _mesesAbrev = mesesAbrevPt;

String _nomeMesCapitalizado(int mes) {
  final nome = mesesNomesPt[mes - 1];
  return nome[0].toUpperCase() + nome.substring(1);
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

  @override
  Widget build(BuildContext context) {
    final abrevMes = _mesesAbrev[_mesExibido.month - 1];
    final diasComEvento = <int>{
      for (final e in calendarEvents)
        if (e.month.toLowerCase() == abrevMes.toLowerCase()) int.tryParse(e.day) ?? -1,
    }..remove(-1);
    final eventosDoMes = calendarEvents.where((e) => e.month.toLowerCase() == abrevMes.toLowerCase()).toList();

    final primeiroDoMes = DateTime(_mesExibido.year, _mesExibido.month, 1);
    final diasNoMes = DateTime(_mesExibido.year, _mesExibido.month + 1, 0).day;
    final offsetInicial = primeiroDoMes.weekday - 1; // 0=Seg
    final totalCelulas = ((offsetInicial + diasNoMes + 6) ~/ 7) * 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendário Acadêmico', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('Semestre 2026.2', style: TextStyle(fontSize: 13, color: AppColors.ink2)),
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
                          decoration: BoxDecoration(gradient: AppColors.gradient, borderRadius: BorderRadius.circular(13)),
                          child: Column(
                            children: [
                              Text(e.day, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                              Text(
                                e.month.toUpperCase(),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(e.desc, style: const TextStyle(fontSize: 11.5, color: AppColors.ink2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SourceTag(text: 'Atualizado automaticamente · site oficial da UNIVASF', topPadding: 10),
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
